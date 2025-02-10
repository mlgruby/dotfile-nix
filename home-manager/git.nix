{
  programs.zsh.initExtra = ''
    function gitdefaultbranch() {
      git remote show origin | grep 'HEAD' | cut -d':' -f2 | sed -e 's/^ *//g' -e 's/ *$//g'
    }
    # ... other git functions ...
  '';
}
