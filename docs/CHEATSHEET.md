# Breaking Kubernetes Cheat Sheet

---

## kubectl auth commands

### kubectl is a very powerful command line tool. Some helpful commands for this workshop are listed below but its just the tip of the iceberg. Checkout the documentation at https://kubernetes.io/docs/reference/kubectl/ for more information. the output in kubectl is very customizable    


get help with almost anything in kubectl
```bash
kubectl --help
```

help can be used on commands, verbs, and resources
```bash
kubectl auth --help
```
if you don't know who you are just ask :)
output for service accounts will contain the SA name and namespace (system:serviceaccount:<ns>:<name>)
```bash
kubectl auth whoami
```

see what you can do by listing resources and actions (verbs) that you have access to
```bash
kubectl auth can-i --list
```

target a specific namespace to almost any kubectl command by adding -n <namespace_name>
```bash
kubectl auth can-i --list -n <namespace>
```

---

## kubectl get and describe commands

### kubectl likes shorthand A LOT. ns and -n are short for namespace, -A is short for allnamespaces, sa is short for serviceaccount, rs is short for replica set, and many more. fun fact, k8s is shorthand for kubernetes. it means k is the first character, followed by 8 more characters, then s is the last character. that's how much the k8s community loves shorthand and it's all over the kubectl application. you don't have to use shorthand but it's there to make your life easier.


see what namespaces exist in the cluster
```bash
kubectl get ns
```

display the pods in a namespace
```bash
kubectl get pods -n <namespace>
```

display all the pods in all the namespaces
```bash
kubectl get pods -A
```

get all the resources in a namespace (services, pods, deployments, etc.)
```bash
kubectl get all -n <namespace>
```

get service account information
```bash
kubectl get serviceaccounts -n <namespace>
```
or
```bash
kubectl get sa -n <namespace>
```

get service account details
```bash
kubectl describe sa <serviceaccount> -n <namespace>
```

get the yaml for a service account and redirect it to a file
```bash
kubectl get sa <serviceaccount> -n <namespace> -o yaml > serviceaccount.yaml
```

get secrets in a namespace
```bash
kubectl get secrets -n <namespace>
```

shows keys & sizes, not values
```bash
kubectl describe secret <secret> -n <namespace>
```

show the secret config in yaml output 
```bash
kubectl get secret <secret> -n <namespace> -o yaml
```

---

## examples of using kubectl outputs

### the output in kubectl is very customizable -o wide, yaml, json, or jsonpath='{.item.name}' are some really useful ways to customize the kubectl output. the kubernetes API does everything in json. kubectl translates yaml to json when talking to the API. jsonpath can be very useful to get the output displayed exactly how you want it. see https://kubernetes.io/docs/reference/kubectl/jsonpath/ for more info.


pull one field out with JSONPath and send it to base64 to decode
```bash
kubectl get secret <secret> -n <namespace> -o jsonpath='{.data.<key>}' | base64 -d
```

filter big lists with a client-side query:
```bash
kubectl get <resource> -A -o jsonpath='{...}'
```

run a pod with a command
```bash
kubectl run <name> -n <namespace> --image=<image> --command -- <keep-alive-cmd>
```

get the pod spec yaml without deploying the pod and save it to a file
```bash
kubectl run <name> -n <namespace> --image=<image> --dry-run=client -o yaml > pod.yaml
```

example pod yaml file that uses a service account and a sleep command to keep the pod running indefinitely
```bash
apiVersion: v1
kind: Pod
metadata:
  name: <pod-name>
  namespace: <namespace>
spec:
  serviceAccountName: <serviceaccount>
  containers:
  - name: <container-name>
    image: <image>
    # This command keeps the container running so you can exec into it
    command: ["sleep", "infinity"]
    imagePullPolicy: IfNotPresent
```

apply a yaml file to a namespace
```bash
kubectl apply -f pod.yaml -n <namespace>
```

apply a yaml file that contains kustomization
```bash
kubectl apply -k pod.yaml
```

---

## kubectl pod cli access

### sometimes you just need to get cli access to the container inside the pods container. kubectl allows you to proxy your CLI to a target container. Logs can also help you understand what's happening in a container


run sh (shell) inside a pods container. change sh to bash if the container includes it
```bash
kubectl exec -it <pod> -n <namespace> -- sh
```
display logged events inside a pod
```bash
kubectl logs <pod> -n <namespace>
```

---

## helpful role and binding commands

### RBAC in k8s is defined in roles and applied to users and service accounts with role bindings. Over privileged accounts and misconfigurations are always targets.  

inspect what a cluster role actually grants:
```bash
kubectl get clusterrole <role> -o yaml
```
and namespaced role
```bash
kubectl get role <role> -n <namespace> -o yaml
```

see who/what is bound to the cluster roles:
```bash
kubectl get clusterrolebindings -o wide
```
and roles in all namespaces:
```bash
kubectl get rolebindings -A -o wide
```

create a cluster admin role binding:
```bash
kubectl create clusterrolebinding <name-cluster-role-binding> --clusterrole=cluster-admin --serviceaccount=<namespace>:<serviceaccount>
```

example cluster role binding yaml for a service account
```bash
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: <binding-name>
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: <service-account-name>
  namespace: <namespace>
```

---
