# home-manager/aliases/dev-tools.nix
#
# Development Tools Aliases
#
# Purpose:
# - Docker container management
# - Terraform/Infrastructure workflows
# - Kubernetes/k3s operations
# - FZF-powered tool integration
#
# Categories:
# - Docker (d, dc, dsp, drm, dlog)
# - Terraform (tf, tfin, tfp, tfa)
# - Kubernetes (k, kgp, kgs, klogs)
# - FZF utilities (fe, fcd, fif)
{helpers, ...}: let
  inherit (helpers) mkAliases mkFileTypeAliases;
in {
  # ==========================================================================
  # Modern CLI Tool Aliases (eza, fd, duf, btm)
  # ==========================================================================

  # eza (modern ls replacement)
  lsa = "eza -la";                                # List all with details
  lst = "eza -T";                                 # Tree view
  lsta = "eza -Ta";                               # Tree view including hidden files
  lsr = "eza -R";                                 # Recursive listing
  lsg = "eza -l --git";                           # List with git status indicators
  lsm = "eza -l --sort=modified";                 # Sort by modification time
  lss = "eza -l --sort=size";                     # Sort by file size
  lsh = "eza -la --header";                       # List with column headers
  lstree = "eza -T --level=3";                    # Tree view (3 levels deep)

  # fd (modern find replacement)
  fdh = "fd -H";                                  # Include hidden files - usage: fdh pattern
  fa = "fd -a";                                   # Show absolute paths - usage: fa pattern
  ft = "fd -tf --changed-within 1d";              # Find files modified in last 24h
  fdir = "fd -td";                                # Find directories only - usage: fdir pattern
  ff = "fd -tf";                                  # Find files only - usage: ff pattern
  fsym = "fd -tl";                                # Find symlinks only
  fconf = "fd -e conf -e config";                 # Find config files
  # File type shortcuts
  fpy = "fd -e py";                               # Find Python files - usage: fpy pattern
  fjs = "fd -e js";                               # Find JavaScript files - usage: fjs pattern
  fnix = "fd -e nix";                             # Find Nix files - usage: fnix pattern
  fsh = "fd -e sh";                               # Find shell scripts
  fmd = "fd -e md";                               # Find markdown files
  fjson = "fd -e json";                           # Find JSON files
  fyaml = "fd -e yaml";                           # Find YAML files
  ftoml = "fd -e toml";                           # Find TOML files

  # duf (modern df replacement)
  dfa = "duf --all";                                # Show all filesystems
  dfh = "duf --hide-fs tmpfs,devtmpfs,efivarfs";    # Hide temporary filesystems
  dfi = "duf --only local,network";                 # Show only local and network disks
  dfs = "duf --sort size";                          # Sort by disk size

  # btm (modern top replacement)
  bm = "btm --basic";                    # Basic system monitor view
  bmp = "btm --process_command";         # Show full process commands
  bmt = "btm --tree";                    # Show process tree
  bmb = "btm --battery";                 # Show battery info
  bmn = "btm --network_legend";          # Show network legend

  # ==========================================================================
  # Tmux Session Management
  # ==========================================================================
  tn = "tmux new -s";                    # Create new named session - usage: tn mysession
  ta = "tmux attach -t";                 # Attach to session - usage: ta mysession
  tl = "tmux list-sessions";             # List all sessions
  tk = "tmux kill-session -t";           # Kill specific session - usage: tk mysession
  t = "tmux new-session -A -s main";     # Attach to or create main session
  tls = "tmux list-sessions -F '#{session_name}: #{?session_attached,attached,not attached}'";  # List sessions with status
  tkall = "tmux list-sessions -F '#{session_name}' | xargs -I {} tmux kill-session -t {}";      # Kill all sessions

  # ==========================================================================
  # FZF Integration
  # ==========================================================================
  # File editing with preview
  fe = "fzf --preview 'bat --color=always --style=numbers --line-range=:500 {}' | xargs -r \${EDITOR:-nvim}";   # Fuzzy find and edit file
  ffp = "fzf --preview 'bat --color=always --style=numbers --line-range=:500 {}'";                              # Fuzzy find with file preview
  edit = "fzf --preview 'bat --color=always {}' | xargs nvim";                                                  # Fuzzy find and edit in nvim

  # Directory navigation
  fcd = "cd $(find . -type d -not -path '*/\\.*' | fzf)";     # Fuzzy find directory (excluding hidden)
  fcdh = "cd $(find . -type d | fzf)";                        # Fuzzy find directory (including hidden)

  # Content search
  fif = "rg --color=always --line-number --no-heading --smart-case \"\" | fzf --ansi --preview 'bat --color=always --style=numbers {1} --highlight-line {2}'";  # Fuzzy search file contents

  # Process management
  fkill = "ps -ef | sed 1d | fzf -m | awk '{print $2}' | xargs kill -9";                  # Fuzzy select and kill processes
  fmem = "ps -eo pid,ppid,cmd,%mem,%cpu --sort=-%mem | head -20 | fzf --header-lines=1";  # Fuzzy browse top memory usage

  # History and environment
  hist = "history 0 | fzf --ansi --preview 'echo {}' | sed 's/ *[0-9]* *//'";  # Fuzzy search command history
  fenv = "env | fzf --preview 'echo {}' | cut -d= -f2";                        # Fuzzy search environment variables

  # ==========================================================================
  # Docker
  # ==========================================================================
  d = "docker";                        # Docker shorthand
  dc = "docker-compose";               # Docker Compose shorthand

  # Interactive container management
  dsp = "docker ps --format 'table {{.Names}}\\t{{.Status}}\\t{{.Ports}}' | fzf --header-lines=1 | awk '{print $1}' | xargs -r docker stop";                # Fuzzy select and stop container
  drm = "docker ps -a --format 'table {{.Names}}\\t{{.Status}}\\t{{.Ports}}' | fzf --header-lines=1 | awk '{print $1}' | xargs -r docker rm";               # Fuzzy select and remove container
  dimg = "docker images --format 'table {{.Repository}}\\t{{.Tag}}\\t{{.Size}}' | fzf --header-lines=1";                                                    # Fuzzy browse docker images
  dlog = "docker ps --format 'table {{.Names}}\\t{{.Status}}' | fzf --header-lines=1 | awk '{print $1}' | xargs -r docker logs -f";                         # Fuzzy select and tail container logs
  dexec = "docker ps --format 'table {{.Names}}\\t{{.Status}}' | fzf --header-lines=1 | awk '{print $1}' | xargs -r -I {} docker exec -it {} /bin/bash";    # Fuzzy select and exec into container

  # ==========================================================================
  # Terraform
  # ==========================================================================
  tf = "terraform";                              # Terraform shorthand
  tfin = "terraform init";                       # Initialize Terraform
  tfp = "terraform plan";                        # Show execution plan
  tfa = "terraform apply";                       # Apply changes
  tfd = "terraform destroy";                     # Destroy infrastructure

  # Version management
  tfi = "tfswitch -i";                           # Install Terraform version
  tfu = "tfswitch -u";                           # Update tfswitch
  tfl = "tfswitch -l";                           # List available versions

  # Workspace management
  tfwst = "terraform workspace select";          # Switch workspace
  tfwsw = "terraform workspace show";            # Show current workspace
  tfwls = "terraform workspace list";            # List workspaces
  tfwsn = "terraform workspace new";             # Create new workspace

  # State and planning
  tfpd = "terraform plan -destroy";              # Plan infrastructure destruction
  tfsh = "terraform show";                       # Show state or plan
  tfst = "terraform state list";                 # List resources in state

  # ==========================================================================
  # Kubernetes / k3s
  # ==========================================================================
  k = "kubectl";                         # Kubectl shorthand
  kgp = "kubectl get pods";              # List pods
  kgs = "kubectl get svc";               # List services
  kgd = "kubectl get deployments";       # List deployments
  kgn = "kubectl get nodes";             # List nodes
  kga = "kubectl get all";               # List all resources
  kgns = "kubectl get namespaces";       # List namespaces

  # Describe resources
  kdp = "kubectl describe pod";          # Describe pod - usage: kdp pod-name
  kds = "kubectl describe svc";          # Describe service - usage: kds service-name
  kdd = "kubectl describe deployment";   # Describe deployment - usage: kdd deployment-name
  kdn = "kubectl describe node";         # Describe node - usage: kdn node-name

  # Logs and exec
  klogs = "kubectl logs -f";             # Follow pod logs - usage: klogs pod-name
  kexec = "kubectl exec -it";            # Execute command in pod - usage: kexec pod-name -- /bin/sh

  # Context and namespace
  kctx = "kubectl config get-contexts";                          # List contexts
  kns = "kubectl config set-context --current --namespace";      # Switch namespace - usage: kns namespace-name
  ksd = "kubectl config use-context vortexa-develop";            # Switch to Develop context
  ksp = "kubectl config use-context vortexa-production";         # Switch to Production context

  # Apply and delete
  kaf = "kubectl apply -f";              # Apply configuration file - usage: kaf deployment.yaml
  kdf = "kubectl delete -f";             # Delete resources from file - usage: kdf deployment.yaml

  # Port forwarding
  kpf = "kubectl port-forward";          # Forward port to local machine - usage: kpf pod-name 8080:80

  # Interactive pod selection
  kfp = "kubectl get pods | fzf --header-lines=1 | awk '{print $1}'";                                               # Fuzzy select pod
  kfl = "kubectl get pods | fzf --header-lines=1 | awk '{print $1}' | xargs kubectl logs -f";                       # Fuzzy select and tail pod logs
  kfe = "kubectl get pods | fzf --header-lines=1 | awk '{print $1}' | xargs -I {} kubectl exec -it {} -- /bin/sh";  # Fuzzy select and exec into pod
}
