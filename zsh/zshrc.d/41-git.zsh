alias gs='git status --ahead-behind'
alias gl='git log --oneline --max-count=42'
alias gl1='git log --max-count=1'
alias glg='git log --graph --oneline --branches --first-parent --max-count=24 @'
alias glga='git log --graph --oneline --branches @'
alias gd='git diff'
alias gds='git diff --stat'
alias gdw='git diff --word-diff-regex=.'
alias gdt='git difftool --dir-diff --no-symlinks'
alias gdtm='git difftool --dir-diff --no-symlinks origin/main'
alias gdts='git difftool --no-prompt'
alias gdtsm='git difftool --no-prompt origin/main'
alias gmt='git mergetool'
alias gf='git fetch'
alias gp='git push'
alias gpf='git push --force-with-lease'
alias gpsup='git push --set-upstream origin $(git branch --show-current)'
alias gcan!='git commit --all --amend --no-edit'
alias grasq='git rebase --interactive --autosquash origin/main'
alias gcof='git checkout "$(git branch --format="%(refname:short)" | fzf)"'

git-stack-list() {
  git for-each-ref --format='%(refname:short)' --merged=HEAD --no-merged=develop refs/heads/
}

git-stack-push() {
  local branches
  branches=$(git-stack-list)
  if [[ -z "$branches" ]]; then
    echo "No branches to push."
    return 0
  fi
  echo "Pushing:"
  echo "$branches"
  echo "$branches" | xargs git push --force-with-lease origin
}
