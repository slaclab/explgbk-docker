## cert-manager lifecycle for the dev environment
## Usage:  make -C kubernetes/dev-operators/cert-manager <target>

CERT_MANAGER_VERSION   ?= 1.20.2
KUBECTL_DEPLOY_CONTEXT ?= 'cryoem-logbook-dev'
NAMESPACE              ?= cert-manager

CERT_MANAGER_URL := https://github.com/cert-manager/cert-manager/releases/download/v$(CERT_MANAGER_VERSION)/cert-manager.yaml

ensure-context:
	if [ '$(shell kubectl config current-context)' != $(KUBECTL_DEPLOY_CONTEXT) ]; then echo "Configured deployment context incorrect; expecting $(KUBECTL_DEPLOY_CONTEXT)."; exit 1; fi

update:
	rm -rf resources && mkdir -p resources
	curl -fsSL $(CERT_MANAGER_URL) | kubectl-slice -o resources/
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

.PHONY: ensure-context update apply diff dump
