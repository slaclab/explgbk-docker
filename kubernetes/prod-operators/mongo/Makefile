## MongoDB operator lifecycle for the prod environment
## Usage:  make -C kubernetes/dev-operators/mongo <target>

#MONGO_OPERATOR_VERSION ?= 1.15.0
MONGO_OPERATOR_VERSION ?= 1.22.0
KUBECTL_DEPLOY_CONTEXT ?= 'cryoem'
OPERATOR_NAMESPACE     ?= psmdb-operator
WATCH_NAMESPACE        ?= cryoem-logbook

ensure-context:
	if [ '$(shell kubectl config current-context)' != $(KUBECTL_DEPLOY_CONTEXT) ]; then echo "Configured deployment context incorrect; expecting $(KUBECTL_DEPLOY_CONTEXT)."; exit 1; fi

helm-repo:
	helm repo add percona https://percona.github.io/percona-helm-charts/ || true
	helm repo update percona

update: ensure-context helm-repo
	rm -rf resources && mkdir -p resources
	helm template --include-crds psmdb-operator percona/psmdb-operator \
		--version $(MONGO_OPERATOR_VERSION) \
		--namespace $(OPERATOR_NAMESPACE) \
		-f values.yaml \
		| kubectl-slice -o resources/
	@echo "resources:" > resources/kustomization.yaml
	@cd resources && for f in $$(ls *.yaml | grep -v kustomization.yaml); do echo "- $$f" >> kustomization.yaml; done
	@echo "Generated resources:"
	@ls resources/

apply: ensure-context
	kubectl apply --server-side --force-conflicts -k .

diff: ensure-context
	kubectl diff --server-side --force-conflicts -k . || true

dump:
	kubectl kustomize .

logs: ensure-context
	kubectl logs -n $(OPERATOR_NAMESPACE) -l app.kubernetes.io/name=psmdb-operator -f

.PHONY: ensure-context helm-repo update apply diff dump logs
