KUBECTL_DEPLOY_CONTEXT ?= 'cryoem-logbook-dev'

# Secrets are ExternalSecrets (externalsecrets.yaml) synced from Vault by ESO;
# nothing here reads Vault.

all: apply

ensure-context:
	if [ '$(shell kubectl config current-context)' != $(KUBECTL_DEPLOY_CONTEXT) ]; then echo "Configured deployment context incorrect; expecting $(KUBECTL_DEPLOY_CONTEXT)."; exit 1; fi

run-apply:
	kubectl apply -k .

run-diff:
	kubectl diff -k .; rc=$$?; if [ $$rc -eq 1 ]; then exit 0; elif [ $$rc -gt 1 ]; then exit $$rc; fi

apply: ensure-context run-apply

diff: ensure-context run-diff

dump:
	kubectl kustomize .
