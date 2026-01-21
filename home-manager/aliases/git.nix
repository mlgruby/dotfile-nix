# home-manager/aliases/git.nix
#
# Git Workflow Aliases
#
# Purpose:
# - Streamline git operations with short aliases
# - FZF-powered interactive branch/commit selection
# - GitHub CLI integration
#
# Categories:
# - Basic operations (gs, gaa, gcm, gp, gl)
# - Branch management (gco, gcob, gbd)
# - Stash operations (gst, gstp, gstl)
# - Log/diff viewing (glog, gd, gdc)
# - Rebase/reset (grb, grbi, grh)
# - GitHub CLI (ghpr, ghprs)
{...}: {
  # ==========================================================================
  # Interactive FZF-powered Git
  # ==========================================================================
  # Branch selection with commit preview
  gcb = "~/.config/home-manager/scripts/git-fuzzy-checkout.sh";  # Fuzzy checkout branch with preview

  # Log browsing with diff preview
  fshow = "~/.config/home-manager/scripts/git-fuzzy-log.sh";  # Fuzzy browse commits with diff

  # Stash selection and apply
  fstash = "~/.config/home-manager/scripts/git-fuzzy-stash.sh";  # Fuzzy select and apply stash

  # ==========================================================================
  # LazyGit Integration
  # ==========================================================================
  lgc = "lazygit -w $(pwd)";                                                        # Open lazygit in current directory
  lgf = "lazygit -f $(find . -type d -name '.git' -exec dirname {} \\; | fzf)";     # Fuzzy find and open git repo in lazygit
  lgs = "lazygit status";                                                           # Show lazygit status

  # ==========================================================================
  # Quick Status & Basic Operations
  # ==========================================================================
  gs = "git status --short";             # Short git status
  s = "git status";                      # Git status (super short alias)
  gaa = "git add --all";                 # Stage all changes
  gcm = "git commit -m";                 # Commit with message - usage: gcm "commit message"
  gp = "git push";                       # Push to remote
  gl = "git pull";                       # Pull from remote

  # ==========================================================================
  # Checkout Operations
  # ==========================================================================
  gco = "git checkout";                                    # Checkout branch/commit - usage: gco branch-name
  gcob = "git checkout -b";                                # Create and checkout new branch - usage: gcob new-branch
  gcom = "git checkout main || git checkout master";       # Checkout main/master
  gcod = "git checkout develop";                           # Checkout develop branch

  # ==========================================================================
  # Commit Operations
  # ==========================================================================
  gca = "git commit --amend";                                               # Amend last commit
  gcan = "git commit --amend --no-edit";                                    # Amend without changing message
  gwip = "git add -A && git commit -m 'WIP'";                               # Quick work-in-progress commit
  gunwip = "git log -1 --pretty=%s | grep -q 'WIP' && git reset HEAD~1";    # Undo WIP commit

  # ==========================================================================
  # Branch Management
  # ==========================================================================
  gbd = "git branch -d";                 # Delete branch (safe - checks merge status) - usage: gbd branch-name
  gbD = "git branch -D";                 # Force delete branch - usage: gbD branch-name
  gbl = "git branch -l";                 # List local branches
  gbr = "git branch -r";                 # List remote branches
  gba = "git branch -a";                 # List all branches (local and remote)
  gbn = "git checkout -b";               # Create and checkout new branch - usage: gbn new-branch

  # ==========================================================================
  # Remote Operations
  # ==========================================================================
  gf = "git fetch";                              # Fetch from remote
  gfa = "git fetch --all";                       # Fetch from all remotes
  gfo = "git fetch origin";                      # Fetch from origin
  gps = "git push";                              # Push to remote
  gpsf = "git push --force-with-lease";          # Force push (safer - checks remote)
  gpsu = "git push -u origin HEAD";              # Push and set upstream
  gpl = "git pull";                              # Pull from remote
  gplr = "git pull --rebase";                    # Pull with rebase

  # ==========================================================================
  # Stash Operations
  # ==========================================================================
  gst = "git stash";                     # Stash changes
  gsta = "git stash push -m";            # Stash with message - usage: gsta "work in progress"
  gstp = "git stash pop";                # Apply and remove latest stash
  gstl = "git stash list";               # List all stashes
  gsts = "git stash show";               # Show stash contents - usage: gsts stash@{0}
  gstd = "git stash drop";               # Delete a stash - usage: gstd stash@{0}
  gstc = "git stash clear";              # Delete all stashes

  # ==========================================================================
  # Log Operations
  # ==========================================================================
  glog = "git log --oneline --decorate --graph";                                # Compact graph log
  gloga = "git log --oneline --decorate --graph --all";                         # Compact graph log (all branches)
  glogp = "git log --pretty=format:'%h -%d %s (%cr) <%an>' --abbrev-commit";    # Pretty log with author
  glast = "git log -1 HEAD";                                                    # Show last commit

  # ==========================================================================
  # Diff Operations
  # ==========================================================================
  gd = "git diff";                                        # Show unstaged changes
  gdc = "git diff --cached";                              # Show staged changes
  gdh = "git diff HEAD";                                  # Show all changes since last commit
  gdt = "git diff-tree --no-commit-id --name-only -r";    # Show files changed in commit - usage: gdt <commit-hash>

  # ==========================================================================
  # Reset Operations
  # ==========================================================================
  grh = "git reset HEAD";                        # Unstage all changes - usage: grh <file>
  grhh = "git reset HEAD --hard";                # Discard all local changes (DESTRUCTIVE!)
  groh = "git reset origin/HEAD --hard";         # Reset to remote HEAD (DESTRUCTIVE!)

  # ==========================================================================
  # Rebase Operations
  # ==========================================================================
  grb = "git rebase";                    # Rebase current branch - usage: grb main
  grbi = "git rebase -i";                # Interactive rebase - usage: grbi HEAD~3
  grbc = "git rebase --continue";        # Continue rebase after resolving conflicts
  grba = "git rebase --abort";           # Abort rebase
  grbs = "git rebase --skip";            # Skip current commit in rebase

  # ==========================================================================
  # Tag Operations
  # ==========================================================================
  gt = "git tag";                        # List tags
  gta = "git tag -a";                    # Create annotated tag - usage: gta v1.0.0 -m "Release 1.0.0"
  gtd = "git tag -d";                    # Delete tag - usage: gtd v1.0.0
  gtl = "git tag -l";                    # List tags matching pattern - usage: gtl "v1.*"

  # ==========================================================================
  # Worktree Operations
  # ==========================================================================
  gwt = "git worktree";                  # Manage worktrees
  gwta = "git worktree add";             # Create new worktree - usage: gwta ../path branch-name
  gwtl = "git worktree list";            # List all worktrees
  gwtr = "git worktree remove";          # Remove worktree - usage: gwtr ../path

  # ==========================================================================
  # Bisect Operations
  # ==========================================================================
  gbs = "git bisect start";              # Start binary search for bug
  gbsg = "git bisect good";              # Mark commit as good
  gbsb = "git bisect bad";               # Mark commit as bad
  gbsr = "git bisect reset";             # End bisect session

  # ==========================================================================
  # Clean Operations
  # ==========================================================================
  gclean = "git clean -fd";              # Remove untracked files and directories
  gcleann = "git clean -fdn";            # Dry run - show what would be removed

  # ==========================================================================
  # Workflow Shortcuts
  # ==========================================================================
  gsync = "git fetch origin && git checkout main && git pull origin main";  # Sync with main branch
  gup = "git fetch && git rebase origin/main";                              # Update current branch from main
  gnuke = "git reset --hard && git clean -fd";                              # Nuclear option - reset everything (DESTRUCTIVE!)

  # Quick workflow combinations
  quickcommit = "gaa && gcm";                                               # Stage all and commit - usage: quickcommit "message"
  quickpush = "gaa && gcm && gp";                                           # Stage, commit, and push - usage: quickpush "message"
  quickamend = "gaa && gcan";                                               # Stage all and amend last commit
  quicksave = "gwip";                                                       # Quick WIP commit (alias for gwip)
  quickfix = "gaa && git commit --amend --no-edit && gpsf";                # Stage, amend, and force push (DESTRUCTIVE!)

  # ==========================================================================
  # Search Operations
  # ==========================================================================
  ggrep = "git grep";                    # Search in tracked files
  glog-search = "git log --grep";        # Search commit messages
  glog-author = "git log --author";      # Filter commits by author

  # ==========================================================================
  # GitHub CLI Integration
  # ==========================================================================
  ghpr = "gh pr create --fill";                      # Create PR with auto-filled details
  ghprs = "gh pr status";                            # Show PR status
  ghprv = "gh pr view --web";                        # View PR in browser
  ghprm = "gh pr merge";                             # Merge PR
  ghprl = "gh pr list --limit 1000";                 # List all PRs
  ghpro = "gh pr list --state open --limit 1000";    # List open PRs
  ghprch = "gh pr checks";                           # Show PR check status
  ghprf = "gh pr list --state open | fzf --preview 'echo {} | awk \"{print \\$1}\" | xargs gh pr view' | awk '{print $1}' | xargs gh pr view --web";  # Fuzzy find and view PR

  # Repository management
  ghrv = "gh repo view --web";                       # View repo in browser
  ghrc = "gh repo clone";                            # Clone repository
  ghrf = "gh repo fork";                             # Fork repository
  ghrs = "gh repo sync";                             # Sync forked repo

  # Issue management
  ghil = "gh issue list --limit 1000";               # List all issues
  ghic = "gh issue create";                          # Create new issue
  ghiv = "gh issue view";                            # View issue details
  ghif = "gh issue list | fzf --preview 'echo {} | awk \"{print \\$1}\" | xargs gh issue view' | awk '{print $1}' | xargs gh issue view --web";  # Fuzzy find and view issue

  # ==========================================================================
  # Conventional Commits
  # ==========================================================================
  feat = "git commit -m 'feat: '";                   # Commit new feature
  fix = "git commit -m 'fix: '";                     # Commit bug fix
  docs = "git commit -m 'docs: '";                   # Commit documentation changes
  style = "git commit -m 'style: '";                 # Commit formatting changes
  refactor = "git commit -m 'refactor: '";           # Commit refactoring
  test = "git commit -m 'test: '";                   # Commit test changes
  chore = "git commit -m 'chore: '";                 # Commit maintenance tasks
}
