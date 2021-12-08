SECRET_PATH=secret/cryoem/cryoem-daq--prod

etc:
	mkdir -p etc

passwords: etc
	# db
	vault kv get --field=cert.crt -format=json $(SECRET_PATH)/logbook | sed -e 's/\"//g' > etc/cert.crt
	vault kv get --field=cert.key -format=json $(SECRET_PATH)/logbook | sed -e 's/\"//g' > etc/cert.key
	vault kv get --field=intermediates.cer -format=json $(SECRET_PATH)/logbook | sed -e 's/\"//g' > etc/intermediates.cer
	vault kv get --field=keytab_webauth -format=json $(SECRET_PATH)/logbook | sed -e 's/\"//g' > etc/keytab_webauth
	vault kv get --field=backend.htpasswd -format=json $(SECRET_PATH)/logbook | sed -e 's/\"//g' > etc/backend.htpasswd
	vault kv get --field=collab-listener.password -format=json $(SECRET_PATH)/logbook | sed -e 's/\"//g' > etc/collab-listener.password


    
apply:
	kubectl apply -k .
