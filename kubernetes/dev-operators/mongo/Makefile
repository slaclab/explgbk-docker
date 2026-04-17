## MongoDB operator lifecycle for the dev environment
## Usage:  make -C operator/mongo <target>

MONGO_OPERATOR_VERSION ?= 1.21.2
KUBECTL_DEPLOY_CONTEXT ?= 'cryoem-logbook-dev'
OPERATOR_NAMESPACE     ?= percona-mongodb-operator
WATCH_NAMESPACE        ?= dev

ensure-context:
	if [ '$(shell kubectl config current-context)' != $(KUBECTL_DEPLOY_CONTEXT) ]; then echo "Configured deployment context inccorect; expecting $(KUBECTL_DEPLOY_CONTEXT)."; exit 1; fi

helm-repo:
	helm repo add percona https://percona.github.io/percona-helm-charts/ || true
	helm repo update percona

PSMDB_CRDS := perconaservermongodbs.psmdb.percona.com \
              perconaservermongodbbackups.psmdb.percona.com \
              perconaservermongodbrestores.psmdb.percona.com

adopt-crds:
	@for crd in $(PSMDB_CRDS); do \
		kubectl label   crd $$crd app.kubernetes.io/version- 2>/dev/null || true; \
		kubectl annotate crd $$crd meta.helm.sh/release-name=psmdb-operator meta.helm.sh/release-namespace=$(OPERATOR_NAMESPACE) --overwrite; \
		kubectl label   crd $$crd app.kubernetes.io/managed-by=Helm --overwrite; \
	done

adopt-resources:
	@kubectl -n $(OPERATOR_NAMESPACE) get sa,role,rolebinding,deployment \
		--no-headers -o custom-columns=KIND:.kind,NAME:.metadata.name 2>/dev/null \
		| awk '{print tolower($$1) "/" $$2}' \
		| while read resource; do \
			kubectl -n $(OPERATOR_NAMESPACE) annotate $$resource \
				meta.helm.sh/release-name=psmdb-operator \
				meta.helm.sh/release-namespace=$(OPERATOR_NAMESPACE) --overwrite 2>/dev/null || true; \
			kubectl -n $(OPERATOR_NAMESPACE) label $$resource \
				app.kubernetes.io/managed-by=Helm --overwrite 2>/dev/null || true; \
		done
	@kubectl get clusterrole,clusterrolebinding \
		--no-headers -o custom-columns=KIND:.kind,NAME:.metadata.name 2>/dev/null \
		| grep psmdb \
		| awk '{print tolower($$1) "/" $$2}' \
		| while read resource; do \
			kubectl annotate $$resource \
				meta.helm.sh/release-name=psmdb-operator \
				meta.helm.sh/release-namespace=$(OPERATOR_NAMESPACE) --overwrite 2>/dev/null || true; \
			kubectl label $$resource \
				app.kubernetes.io/managed-by=Helm --overwrite 2>/dev/null || true; \
		done

run-apply:
	helm upgrade --install psmdb-operator percona/psmdb-operator \
		--version $(MONGO_OPERATOR_VERSION) \
		--namespace $(OPERATOR_NAMESPACE) \
		--create-namespace \
		--set watchNamespace=$(WATCH_NAMESPACE) \
		--atomic --timeout 120s
	kubectl apply --server-side --force-conflicts -f cert-manager-issuer.yaml

run-kustomize:
	helm template psmdb-operator percona/psmdb-operator \
		--version $(MONGO_OPERATOR_VERSION) \
		--namespace $(OPERATOR_NAMESPACE) \
		--set watchNamespace=$(WATCH_NAMESPACE)

run-diff:
	helm diff upgrade psmdb-operator percona/psmdb-operator \
		--version $(MONGO_OPERATOR_VERSION) \
		--namespace $(OPERATOR_NAMESPACE) \
		--set watchNamespace=$(WATCH_NAMESPACE); rc=$$?; if [ $$rc -gt 1 ]; then exit $$rc; fi

apply: ensure-context helm-repo
	@if ! helm status psmdb-operator -n $(OPERATOR_NAMESPACE) &>/dev/null; then \
		$(MAKE) adopt-crds adopt-resources; \
	fi
	$(MAKE) run-apply

dump: ensure-context helm-repo run-kustomize

diff: ensure-context helm-repo run-diff

.PHONY: ensure-context helm-repo adopt-crds adopt-resources run-apply run-kustomize run-diff apply dump diff
