MONGO_OPERATOR_VERSION ?= 1.12.0
NAMESPACE ?= cryoem-logbook

all: mongo-operator kafka-operator

mongo-operator:
	helm repo add percona https://percona.github.io/percona-helm-charts/
	helm repo update
	helm template --version $(MONGO_OPERATOR_VERSION) mongodb-operator percona/psmdb-operator --namespace $(NAMESPACE) > mongo-operator.yaml
	curl https://raw.githubusercontent.com/percona/percona-helm-charts/main/charts/psmdb-operator/crds/crd.yaml > mongo-crd.yaml

kafka-operator:
	curl -L https://strimzi.io/install/latest?namespace=kafka-operator -o kafka-operator.yaml

run-apply:
	kubectl apply -k .
