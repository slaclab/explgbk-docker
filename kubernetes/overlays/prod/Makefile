SECRET_PATH ?= secret/cryoem/cryoem-logbook

get-secrets-from-vault:
	mkdir -p etc/.secrets/
	set -e; for i in MONGODB_BACKUP_PASSWORD  MONGODB_CLUSTER_ADMIN_PASSWORD  MONGODB_CLUSTER_MONITOR_PASSWORD  MONGODB_USER_ADMIN_PASSWORD	PMM_SERVER_PASSWORD  S3_ACCESS_KEY  S3_SECRET_KEY cert.crt cert.key intermediates.cer keytab_webauth.encoded backend.htpasswd collab-listener.password; do vault kv get --field=$$i $(SECRET_PATH) > etc/.secrets/$$i ; done
	cat etc/.secrets/keytab_webauth.encoded | base64 -d > etc/.secrets/keytab_webauth
	

clean-secrets:
	rm -f etc/.secrets/

run-apply:
	kubectl apply -k .

dump:
	kubectl kustomize  . | yh

apply: get-secrets-from-vault run-apply clean-secrets
