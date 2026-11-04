#!/usr/bin/env bash
# Generates a minimal kubeconfig for the checkout-serviceaccount ServiceAccount,
# dropped into kubeconfigs/. It contains only the kind cluster's API server and CA
# plus the ServiceAccount token (no admin or other-cluster credentials).
#
# Usage: ./scripts/gen-serviceaccount-kubeconfig.sh [duration]
#   duration defaults to 24h (passed to `kubectl create token --duration`)
#   KIND_CLUSTER_NAME selects the kind cluster (default: kind)
#
# Works with kind on Docker or Podman, with or without sudo for the container runtime.

set -euo pipefail

SERVICEACCOUNT_NAME="checkout-serviceaccount"
SERVICEACCOUNT_NAMESPACE="checkout-prod"
DURATION="${1:-24h}"
KIND_CLUSTER_NAME="${KIND_CLUSTER_NAME:-kind}"

# Pick a container runtime and detect whether it needs sudo.
SUDO=""
if [[ -z "${KIND_EXPERIMENTAL_PROVIDER:-}" ]]; then
  if command -v docker >/dev/null 2>&1; then
    KIND_EXPERIMENTAL_PROVIDER=docker
  elif command -v podman >/dev/null 2>&1; then
    KIND_EXPERIMENTAL_PROVIDER=podman
  fi
fi
if [[ -n "${KIND_EXPERIMENTAL_PROVIDER:-}" ]]; then
  export KIND_EXPERIMENTAL_PROVIDER
  if ! "${KIND_EXPERIMENTAL_PROVIDER}" info >/dev/null 2>&1 \
     && sudo -n "${KIND_EXPERIMENTAL_PROVIDER}" info >/dev/null 2>&1; then
    SUDO="sudo"
  fi
fi

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT_DIR="${REPO_ROOT}/kubeconfigs"
OUT_FILE="${OUT_DIR}/${SERVICEACCOUNT_NAME}.kubeconfig"
mkdir -p "${OUT_DIR}"

# Admin kubeconfig straight from kind, independent of the user's own kubeconfig.
ADMIN_KUBECONFIG="$(mktemp)"
CA_FILE="$(mktemp)"
trap 'rm -f "${ADMIN_KUBECONFIG}" "${CA_FILE}"' EXIT
${SUDO} kind get kubeconfig --name "${KIND_CLUSTER_NAME}" > "${ADMIN_KUBECONFIG}"

SERVER="$(kubectl --kubeconfig="${ADMIN_KUBECONFIG}" config view --raw --minify -o jsonpath='{.clusters[0].cluster.server}')"
kubectl --kubeconfig="${ADMIN_KUBECONFIG}" config view --raw --minify \
  -o jsonpath='{.clusters[0].cluster.certificate-authority-data}' | base64 -d > "${CA_FILE}"

TOKEN="$(kubectl --kubeconfig="${ADMIN_KUBECONFIG}" create token "${SERVICEACCOUNT_NAME}" \
  -n "${SERVICEACCOUNT_NAMESPACE}" --duration="${DURATION}")"

rm -f "${OUT_FILE}"
kubectl --kubeconfig="${OUT_FILE}" config set-cluster "${KIND_CLUSTER_NAME}" \
  --server="${SERVER}" --certificate-authority="${CA_FILE}" --embed-certs=true >/dev/null
kubectl --kubeconfig="${OUT_FILE}" config set-credentials "${SERVICEACCOUNT_NAME}" --token="${TOKEN}" >/dev/null
kubectl --kubeconfig="${OUT_FILE}" config set-context "${SERVICEACCOUNT_NAME}" \
  --cluster="${KIND_CLUSTER_NAME}" \
  --user="${SERVICEACCOUNT_NAME}" \
  --namespace="${SERVICEACCOUNT_NAMESPACE}" >/dev/null
kubectl --kubeconfig="${OUT_FILE}" config use-context "${SERVICEACCOUNT_NAME}" >/dev/null
chmod 600 "${OUT_FILE}"

echo "Wrote ${OUT_FILE} (token valid for ${DURATION})"
echo
echo "To use it:"
echo "  export KUBECONFIG=${OUT_FILE}"
