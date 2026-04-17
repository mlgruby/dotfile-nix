# Work-profile Zsh helpers.

function setup-vortexa-kube() {
  echo "Setting up Vortexa Kubernetes contexts..."

  unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN

  echo "Configuring Develop cluster..."
  AWS_PROFILE=default-sso aws eks --region eu-west-1 update-kubeconfig --name KubeCluster --role-arn arn:aws:iam::045251666112:role/EKSUserRole --alias vortexa-develop

  echo "Configuring Production cluster..."
  AWS_PROFILE=production-sso aws eks --region eu-west-1 update-kubeconfig --name KubeCluster --role-arn arn:aws:iam::501857513371:role/EKSUserRole --alias vortexa-production

  echo "Done! Use ksd/ksp to switch contexts."
}
