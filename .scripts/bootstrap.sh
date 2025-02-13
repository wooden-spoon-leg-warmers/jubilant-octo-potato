#!/bin/bash

set -e

source .env

if [ -z "$GITHUB_REPOSITORY" ]; then
  echo "GITHUB_REPOSITORY environment variable is not set."
  exit 1
fi

wait_for_pod_ready() {
  local NAMESPACE=$1
  local LABEL=$2
  local TIMEOUT="600s"

  # Loop until the pod is found
  while true; do
    echo "Looking for pod with label $LABEL in namespace $NAMESPACE..."
    set +e
    POD_NAME=$(minikube kubectl -- get pod -l $LABEL -n $NAMESPACE -o jsonpath="{.items[0].metadata.name}" 2>/dev/null)
    set -e
    if [ -n "$POD_NAME" ]; then
      echo "Pod $POD_NAME found. Waiting for it to be ready..."
      break
    else
      echo "Pod not found. Retrying in 5 seconds..."
      sleep 5
    fi
  done

  # Wait for the pod to be ready
  minikube kubectl -- wait --for=condition=ready --timeout=$TIMEOUT pod -l $LABEL -n $NAMESPACE
}

# Check if minikube is running already if not start it
minikube status || minikube start

# Install ArgoCD
minikube kubectl -- create namespace argocd || true
minikube kubectl -- apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml --wait

# Wait for ArgoCD to be ready
wait_for_pod_ready "argocd" "app.kubernetes.io/name=argocd-application-controller"

# Restart all ArgoCD pods due to some issue? Maybe with minikube
minikube kubectl -- rollout restart deployment -n argocd
minikube kubectl -- rollout restart statefulset -n argocd
wait_for_pod_ready "argocd" "app.kubernetes.io/name=argocd-application-controller"

# Deploy the database
minikube kubectl -- apply -k local/database
# Wait for the database to be ready
wait_for_pod_ready "database" "app.kubernetes.io/name=postgresql"

# Port forward the database
minikube kubectl -- port-forward svc/postgresql 5432:5432 -n database &
# Run the terraform
terraform -chdir=database/terraform init
terraform -chdir=database/terraform apply -var="db_password=password" -auto-approve
# Close the port forward
kill %1

# Deploy the application
# Read the file and replace occurrences
CONTENT=$(minikube kubectl -- kustomize local/api | sed "s|wooden-spoon-leg-warmers/fluffy-carnival|$GITHUB_REPOSITORY|g")

# Apply the content using kubectl
echo "$CONTENT" | minikube kubectl -- apply -f -

# Wait for the database to be ready
# wait_for_pod_ready "api" "app.kubernetes.io/instance=api"

# Port forward the database
minikube kubectl -- port-forward svc/api 3000:3000 -n api
