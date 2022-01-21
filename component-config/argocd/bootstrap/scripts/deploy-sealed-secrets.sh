#! /usr/bin/env bash

set -e

# Helpers for readability.
bold=$(tput bold)
normal=$(tput sgr0)
function _info() {
    echo "${bold}${1}${normal}"
}

# Run script from directory where the script is stored.
cd "$( dirname "${BASH_SOURCE[0]}" )"

# Define the target cluster.
: "${HELM_KUBECONTEXT:?"set this variable to the Kubernetes context to use"}"
export HELM_KUBECONTEXT

# Connect to Helm chart repository.
_info "📚 Connecting to Helm chart repository..."
helm repo add sealed-secrets https://bitnami-labs.github.io/sealed-secrets
helm repo update

# Deploy Sealed Secret controller.
_info "🚀 Deploying Sealed Secret controller..."
helm upgrade \
    --install \
    --namespace=sealed-secrets \
    --create-namespace \
    --wait \
    --version=1.16.1 \
    --values=../../component-config/sealed-secrets/helm-values.yml \
    sealed-secrets \
    sealed-secrets/sealed-secrets

_info "👍 Deployment successful."
