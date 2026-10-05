#!/usr/bin/env bash
# One-time bootstrap: install Argo CD with Helm, then hand control to Git.
# After this, change the cluster by committing, not by running commands.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
export KUBECONFIG="${KUBECONFIG:-$REPO_ROOT/kubeconfig}"

# Only needs to be close: Argo CD converges to the version pinned in
# apps/argocd.yaml right after it starts.
ARGOCD_CHART_VERSION="10.9.6"

echo "==> Checking cluster access"
kubectl get nodes >/dev/null

echo "==> Installing Argo CD (chart ${ARGOCD_CHART_VERSION})"
helm repo add argo https://argoproj.github.io/argo-helm --force-update >/dev/null
helm upgrade --install argocd argo/argo-cd \
  --namespace argocd --create-namespace \
  --version "$ARGOCD_CHART_VERSION" \
  --values "$REPO_ROOT/values/argocd.yaml" \
  --wait --timeout 10m

echo "==> Handing control to Git (root app)"
kubectl apply -f "$REPO_ROOT/bootstrap/root.yaml"

cat <<MSG

Argo CD is running. Retrieve the initial admin password with:
  kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d; echo
Change it after first login, then delete that secret.
MSG
