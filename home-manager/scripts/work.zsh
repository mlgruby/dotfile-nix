# Work-profile Zsh helpers.

# Lazy helper to load GitHub credentials for devcontainers on-demand
# Avoid ambiently exporting high-privilege GitHub tokens into every interactive shell environment
function devcontainer-auth() {
  if ! command -v gh >/dev/null 2>&1; then
    echo "gh CLI not found." >&2
    return 1
  fi

  local user token
  user="$(gh api user --jq .login 2>/dev/null)" || true
  token="$(gh auth token 2>/dev/null)" || true

  if [ -z "$user" ] || [ -z "$token" ]; then
    echo "Failed to retrieve GitHub credentials. Please run 'gh auth login'." >&2
    return 1
  fi

  export DEVCONTAINER_GITHUB_ACTOR="$user"
  export DEVCONTAINER_GITHUB_TOKEN="$token"
  echo "Exported DEVCONTAINER_GITHUB_ACTOR ($DEVCONTAINER_GITHUB_ACTOR) and DEVCONTAINER_GITHUB_TOKEN."
}

function setup-vortexa-kube() {
  echo "Setting up Vortexa Kubernetes contexts..."

  unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN

  echo "Configuring Develop cluster..."
  AWS_PROFILE=default-sso aws eks --region eu-west-1 update-kubeconfig --name KubeCluster --role-arn arn:aws:iam::045251666112:role/EKSUserRole --alias vortexa-develop

  echo "Configuring Production cluster..."
  AWS_PROFILE=production-sso aws eks --region eu-west-1 update-kubeconfig --name KubeCluster --role-arn arn:aws:iam::501857513371:role/EKSUserRole --alias vortexa-production

  echo "Done! Use ksd/ksp to switch contexts."
}
