# Demo: Setup

Verify the kind cluster is already running, apply the lab manifests, generate the
low-privilege kubeconfig, and run the first `get ns`.

![Setup demo](gifs/00-setup.gif)

## Commands run

```bash
kind get clusters
kubectl get nodes
kubectl apply -k manifests/
./scripts/gen-serviceaccount-kubeconfig.sh
export KUBECONFIG=kubeconfigs/checkout-serviceaccount.kubeconfig
kubectl get ns
```
