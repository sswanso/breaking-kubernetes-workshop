# Demo: Enumeration

Technique 1: enumerate with built-in tools. Starting as `cart-worker`.

![Enumeration demo](gifs/01-enumeration.gif)

## Commands run

```bash
export KUBECONFIG=./kubeconfigs/cart-worker.kubeconfig

kubectl get namespaces
kubectl auth can-i --list -n cart-svc
for ns in $(kubectl get ns -o name | cut -d/ -f2); do echo "$ns: $(kubectl auth can-i create pods -n "$ns" 2>/dev/null)"; done
kubectl auth can-i --list -n wallet-svc
kubectl get secrets -n wallet-svc
```
