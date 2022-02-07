#! /usr/bin/env bash

set -e

# Helpers for readability.
bold=$(tput bold)
normal=$(tput sgr0)
function _info() {
    echo "${bold}${1}${normal}"
}
function _error() {
    echo "${bold}${red}Error: ${1}${normal}"
}
function _usage() {
    _info "Usage:"
    _info "  HELM_KUBECONTEXT=my-context $0"
}

# Run script from directory where the script is stored.
cd "$( dirname "$0" )"

# The caller must specify the Kubernetes cluster to deploy to and the
# credentials to use.
if [ -z "$HELM_KUBECONTEXT" ]; then
    _error "The HELM_KUBECONTEXT environment variable is not set."
    _usage
    exit 1
fi

_info "🎯 Using Kubernetes context \"$HELM_KUBECONTEXT\"..."
export HELM_KUBECONTEXT="$HELM_KUBECONTEXT"

# Connect to Helm chart repository.
_info "📚 Connecting to Helm chart repository..."
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update

# Create a namespace for Argo CD.
_info "📦 Creating a namespace..."
kubectl create namespace argocd || true

# Upload private SSH key to pull from GitHub.
_info "🔑 Uploading private SSH key for GitHub access..."
kubectl apply \
  --namespace=argocd \
  --filename=../templates/sealed-secret.yaml

# Deploy Argo CD.
_info "🚀 Deploying Argo CD..."
helm upgrade \
    --install \
    --namespace=argocd \
    --create-namespace \
    --wait \
    --version=3.26.3 \
    --values=../values.yaml \
    argocd \
    argo/argo-cd

# Create the ArgoCD app of apps.
_info "⚙️ Creating the ArgoCD app of apps..."
kubectl apply \
  --namespace=argocd \
  --filename=../../../../argocd-config/applications/app-of-apps.yaml

_info "👍 Deployment successful."
