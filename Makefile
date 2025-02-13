bootstrap:
	./.scripts/bootstrap.sh

cleanup:
	minikube delete
	rm database/terraform/terraform.tfstate

serve-argocd:
	minikube kubectl -- port-forward svc/argocd-server -n argocd 8080:443

serve-postgres:
	minikube kubectl -- port-forward svc/postgresql -n database 5432:5432

password-argocd:
	minikube kubectl -- get secret argocd-initial-admin-secret -n argocd -o jsonpath="{.data.password}" | base64 -d