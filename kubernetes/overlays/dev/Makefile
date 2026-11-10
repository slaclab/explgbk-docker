KUBECTL_DEPLOY_CONTEXT ?= 'cryoem-logbook-dev'
SECRET_PATH ?= secret/cryoem/cryoem-logbook-dev

all: apply

ensure-context:
	if [ '$(shell kubectl config current-context)' != $(KUBECTL_DEPLOY_CONTEXT) ]; then echo "Configured deployment context incorrect; expecting $(KUBECTL_DEPLOY_CONTEXT)."; exit 1; fi

get-secrets-from-vault:
	mkdir -p etc/.secrets/
	set -e; for i in cert.crt cert.key intermediates.cer keytab_webauth.encoded backend.htpasswd explgbk-writer.username explgbk-writer.password explgbk-reader.username explgbk-reader.password; do vault kv get --field=$$i $(SECRET_PATH) > etc/.secrets/$$i ; done
	cat etc/.secrets/keytab_webauth.encoded | base64 -d > etc/.secrets/keytab_webauth

clean-secrets:
	rm -rf etc/.secrets/

run-apply:
	kubectl apply -k .

run-kustomize:
	kubectl kustomize .

run-diff:
	kubectl diff -k .; rc=$$?; if [ $$rc -eq 1 ]; then exit 0; elif [ $$rc -gt 1 ]; then exit $$rc; fi

apply: ensure-context get-secrets-from-vault run-apply clean-secrets

dump: ensure-context get-secrets-from-vault run-kustomize clean-secrets

diff: ensure-context get-secrets-from-vault run-diff clean-secrets
