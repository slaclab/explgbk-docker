#!/bin/bash
# Read-only report of the Strimzi operator, its CRDs and the Kafka cluster for one
# kube context + namespace. Changes nothing. The spec dump contains no secret values.
#
# Usage: bash inspect-strimzi.sh <context> <namespace> [spec-dump-file]
#   prod: bash inspect-strimzi.sh cryoem cryoem-logbook
#   dev:  bash inspect-strimzi.sh cryoem-logbook-dev dev
set -u
CTX=${1:?context}; NS=${2:?namespace}; OUT=${3:-$HOME/kafka-live-$CTX.yaml}
k() { kubectl --context "$CTX" "$@" 2>/dev/null; }

echo "### 1. Strimzi operator deployments (all namespaces visible to $CTX)"
k get deploy -A -o custom-columns='NS:.metadata.namespace,NAME:.metadata.name,IMAGE:.spec.template.spec.containers[0].image,READY:.status.readyReplicas,WANT:.spec.replicas' \
  | grep -i -E '^NS|strimzi'
for d in $(k get deploy -A -o jsonpath='{range .items[*]}{.metadata.namespace}/{.metadata.name}{"\n"}{end}' | grep strimzi-cluster-operator); do
  echo "  $d"
  echo "    watches:  $(k -n "${d%/*}" get deploy "${d#*/}" -o jsonpath='{.spec.template.spec.containers[0].env[?(@.name=="STRIMZI_NAMESPACE")].value}')"
  echo "    managed:  $(k -n "${d%/*}" get deploy "${d#*/}" -o jsonpath='{.metadata.labels.app\.kubernetes\.io/managed-by} {.metadata.labels.helm\.sh/chart}')"
done
if command -v helm >/dev/null; then
  echo "  helm releases:"; helm --kube-context "$CTX" list -A 2>/dev/null | grep -i -E '^NAME|strimzi'
fi

echo; echo "### 2. Strimzi CRDs (served / stored versions)"
k get crd -o custom-columns='NAME:.metadata.name,SERVED:.spec.versions[*].name,STORED:.status.storedVersions' \
  | grep -E '^NAME|strimzi'

echo; echo "### 3. Kafka resources in $NS"
k -n "$NS" get kafka,kafkanodepool,kafkatopic,kafkauser,kafkarebalance
echo
k -n "$NS" get kafka -o jsonpath='{range .items[*]}{.metadata.name}{":"}{"\n  kafkaVersion="}{.status.kafkaVersion}{"  metadataVersion="}{.status.kafkaMetadataVersion}{"\n  operatorLastSuccessfulVersion="}{.status.operatorLastSuccessfulVersion}{"\n  annotations: kraft="}{.metadata.annotations.strimzi\.io/kraft}{" node-pools="}{.metadata.annotations.strimzi\.io/node-pools}{"\n  spec.kafka.version="}{.spec.kafka.version}{"  zookeeper="}{.spec.zookeeper.replicas}{"\n  conditions: "}{.status.conditions}{"\n"}{end}'

echo; echo "### 4. Broker pods"
k -n "$NS" get pods -l strimzi.io/kind=Kafka -o wide

echo; echo "### 5. Topics and under-replicated partitions (run on a broker)"
B=$(k -n "$NS" get pods -l strimzi.io/kind=Kafka -o name | grep -v -E 'entity|cruise|exporter' | head -1)
if [ -n "$B" ]; then
  echo "  broker: $B"
  k -n "$NS" exec "$B" -c kafka -- /opt/kafka/bin/kafka-topics.sh --bootstrap-server localhost:9092 --list
  echo "  under-replicated (empty is good):"
  k -n "$NS" exec "$B" -c kafka -- /opt/kafka/bin/kafka-topics.sh --bootstrap-server localhost:9092 --describe --under-replicated-partitions
else
  echo "  no broker pod found"
fi

echo; echo "### 6. explgbk Kafka warnings/errors, last 72h (empty is good)"
P=$(k -n "$NS" get pods -l name=explgbk -o name | head -1)
[ -n "$P" ] && k -n "$NS" logs "$P" --since=72h | grep -i kafka | grep -i -E 'error|warn|fail|unsupported|nobrokers' \
  | sed -E 's/^[0-9-]+ [0-9:,]+ - //' | sort | uniq -c | sort -rn | head -20

echo; echo "### 7. Writing Kafka / KafkaNodePool / KafkaTopic specs to $OUT"
k -n "$NS" get kafka,kafkanodepool,kafkatopic -o yaml > "$OUT" && wc -l "$OUT"
