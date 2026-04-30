KUBECTL_DEPLOY_CONTEXT ?= 'cryoem-logbook-dev'

all: apply

ensure-context:
	if [ '$(shell kubectl config current-context)' != $(KUBECTL_DEPLOY_CONTEXT) ]; then echo "Configured deployment context incorrect; expecting $(KUBECTL_DEPLOY_CONTEXT)."; exit 1; fi

get-secrets-from-vault:
	mkdir -p etc/.secrets/

clean-secrets:
	rm -rf etc/.secrets/

run-apply:
	kubectl apply --server-side --force-conflicts -k .

run-kustomize:
	kubectl kustomize .

run-diff:
	kubectl diff -k .; rc=$$?; if [ $$rc -eq 1 ]; then exit 0; elif [ $$rc -gt 1 ]; then exit $$rc; fi

apply: ensure-context get-secrets-from-vault run-apply clean-secrets

dump: ensure-context get-secrets-from-vault run-kustomize clean-secrets

diff: ensure-context get-secrets-from-vault run-diff clean-secrets

# ── Backup operations ────────────────────────────────────────────────
#
# Trigger an on-demand physical backup for testing.
backup-ondemand: ensure-context
	kubectl apply -f backup-ondemand.yaml
#
#Check status of all backups.
backup-status: ensure-context
	kubectl get psmdb-backup

.PHONY: all ensure-context get-secrets-from-vault clean-secrets run-apply run-kustomize run-diff apply dump diff
