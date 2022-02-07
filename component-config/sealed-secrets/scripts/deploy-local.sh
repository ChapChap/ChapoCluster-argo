#! /usr/bin/env bash

set -e

# Helpers for readability.
bold=$(tput bold)
red=$(tput setaf 1)
normal=$(tput sgr0)
function _info() {
    echo "${bold}${1}${normal}"
}
function _error() {
    echo "${bold}${red}Error: ${1}${normal}"
}
function _usage() {
    _info "Usage:"
    _info "  KUBECONTEXT=my-context $0"
}

# Run script from directory where the script is stored.
cd "$( dirname "$0" )"

# The caller must specify the Kubernetes cluster to deploy to and the
# credentials to use.
if [ -z "$KUBECONTEXT" ]; then
    _error "The KUBECONTEXT environment variable is not set."
    _usage
    exit 1
fi

_info "🎯 Using Kubernetes context \"$KUBECONTEXT\"..."
export HELM_KUBECONTEXT="$KUBECONTEXT"

# Deploy Prometheus.
_info "🚀 Deploying Prometheus..."
helm dependency update ../
helm upgrade \
    --install \
    --namespace=sealed-secrets \
    --create-namespace \
    --wait \
    sealed-secrets \
    ../

_info "👍 Deployment successful."
