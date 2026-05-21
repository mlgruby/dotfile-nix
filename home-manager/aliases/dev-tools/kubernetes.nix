# home-manager/aliases/dev-tools/kubernetes.nix
#
# Kubernetes and k3s aliases.
{ ... }:
{
  k = "kubectl"; # Kubectl shorthand
  kgp = "kubectl get pods"; # List pods
  kgs = "kubectl get svc"; # List services
  kgd = "kubectl get deployments"; # List deployments
  kgn = "kubectl get nodes"; # List nodes
  kga = "kubectl get all"; # List all resources
  kgns = "kubectl get namespaces"; # List namespaces

  # Describe resources
  kdp = "kubectl describe pod"; # Describe pod - usage: kdp pod-name
  kds = "kubectl describe svc"; # Describe service - usage: kds service-name
  kdd = "kubectl describe deployment"; # Describe deployment - usage: kdd deployment-name
  kdn = "kubectl describe node"; # Describe node - usage: kdn node-name

  # Logs and exec
  klogs = "kubectl logs -f"; # Follow pod logs - usage: klogs pod-name
  kexec = "kubectl exec -it"; # Execute command in pod - usage: kexec pod-name -- /bin/sh

  # Context and namespace
  kctx = "kubectl config get-contexts"; # List contexts
  kns = "kubectl config set-context --current --namespace"; # Switch namespace - usage: kns namespace-name
  ksd = "kubectl config use-context vortexa-develop"; # Switch to Develop context
  ksp = "kubectl config use-context vortexa-production"; # Switch to Production context

  # Apply and delete
  kaf = "kubectl apply -f"; # Apply configuration file - usage: kaf deployment.yaml
  kdf = "kubectl delete -f"; # Delete resources from file - usage: kdf deployment.yaml

  # Port forwarding
  kpf = "kubectl port-forward"; # Forward port to local machine - usage: kpf pod-name 8080:80

  # Interactive pod selection
  kfp = "kubectl get pods | fzf --header-lines=1 | awk '{print $1}'"; # Fuzzy select pod
  kfl = "kubectl get pods | fzf --header-lines=1 | awk '{print $1}' | xargs kubectl logs -f"; # Fuzzy select and tail pod logs
  kfe = "kubectl get pods | fzf --header-lines=1 | awk '{print $1}' | xargs -I {} kubectl exec -it {} -- /bin/sh"; # Fuzzy select and exec into pod
}
