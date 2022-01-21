# Bootstrap

This document explains how to deploy ArgoCD for the first time.

## Context

Our target architecture is for ArgoCD to manage every component deployed in the
cluster, including ArgoCD itself. Once ArgoCD is deployed, it uses the contents
of this repository to deploy everything.

## Requirements

- `helm`
- `kubectl`
- `kubeseal`
- Kubernetes cluster is up, `kubectl get nodes` works

## Instructions

ArgoCD uses an SSH key to connect to its repositories. ArgoCD needs a separate
key for each repository.

The steps below show how to upload ArgoCD's private key to the cluster securely
with Sealed Secrets.

1. Generate public and private keys:

   ```bash
   ssh-keygen -t ed25519 -C "ArgoCD" -f argocd -N ""
   ```

2. Upload the public key (`argocd.pub`) as a Deploy Key in your repository (read-only).

3. Deploy Sealed Secrets.

   ```bash
   HELM_KUBECONTEXT="gke_my-project_europe-west1-b_my-cluster" ./bootstrap/scripts/deploy-sealed-secrets.sh
   ```

4. Check that Sealed Secrets is running properly:

   ```bash
   # This command should print a certificate. If it does, Sealed Secrets is
   # running properly.
   kubeseal \
     --controller-name=sealed-secrets \
     --controller-namespace=sealed-secrets \
     --fetch-cert
   ```

5. Create a `credentials/secret.yml` file with ArgoCD's repository's URL and private key:

   > 🚨 Do **NOT** commit this file to git. 🚨

   ```yaml
   apiVersion: v1
   kind: Secret
   metadata:
     name: github-credentials
     labels:
       argocd.argoproj.io/secret-type: repository
   type: Opaque
   stringData:
     # Change this 👇, write your repository URL as `git@...`.
     url: git@github.com:padok-team/your-repository.git
     # Change this 👇, write ArgoCD's private key.
     sshPrivateKey: |
       -----BEGIN OPENSSH PRIVATE KEY-----
       b3Bl...
       -----END OPENSSH PRIVATE KEY-----
   ```

6. Delete the `argocd` and `argocd.pub` ssh key files

7. Encrypt the secret:

   ```bash
   kubeseal \
     --controller-name=sealed-secrets \
     --controller-namespace=sealed-secrets \
     --format=yaml \
     --scope=cluster-wide \
     < credentials/secret.yml \
     > credentials/sealed-secret.yml
   ```

8. Commit the `credentials/sealed-secret.yml` file.

9. Deploy ArgoCD:

   ```bash
   HELM_KUBECONTEXT="gke_my-project_europe-west1-b_my-cluster" ./bootstrap/scripts/deploy-argocd.sh
   ```
