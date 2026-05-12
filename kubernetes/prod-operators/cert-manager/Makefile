KUBECTL_DEPLOY_CONTEXT ?= 'cryoem'
NAMESPACE ?= cert-manager
CM_VERSION ?= 'v1.20.0'

ensure-context:
	if [ '$(shell kubectl config current-context)' != $(KUBECTL_DEPLOY_CONTEXT) ]; then echo "Configured deployment context inccorect; expecting $(KUBECTL_DEPLOY_CONTEXT)."; exit 1; fi

update: ensure-context
	@helm repo add jetstack https://charts.jetstack.io 2>/dev/null 1>&2
	@helm repo update 2>/dev/null 1>&2
	@cat kustomization.yaml.tmpl > kustomization.yaml
	@helm template cert-manager jetstack/cert-manager --namespace $(NAMESPACE) --version $(CM_VERSION) --set installCRDs=true -f cm-values.yaml | kubectl slice -t "{{.kind | lower}}-{{.metadata.name | lower}}.yaml" -o resources/
	@mv resources/customresourcedefinition* crd/
	@mv resources/job-* jobs/
	@kustomize edit add resource resources/* jobs/*

dump: 
	kubectl kustomize .

run-apply:
	# CRDs too long
	#kubectl delete -f jobs/
	kubectl apply --server-side --force-conflicts -f crd/
	kubectl apply -k .

apply: ensure-context run-apply

delete: ensure-context
	kubectl kustomize . | kubectl delete -f -
