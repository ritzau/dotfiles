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

# Base branch for the stack/merged helpers below: $GIT_BASE_BRANCH if set,
# else origin's default branch (as recorded at clone time), else main.
git-base-branch() {
  if [[ -n $GIT_BASE_BRANCH ]]; then
    print -r -- "$GIT_BASE_BRANCH"
    return
  fi
  local head
  head=$(git symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null) \
    && print -r -- "${head#origin/}" \
    || print -r -- main
}

git-stack-list() {
  git for-each-ref --format='%(refname:short)' --merged=HEAD --no-merged="$(git-base-branch)" refs/heads/
}

# Run a command on every commit in the stack.  The command is the
# arguments, or $GIT_STACK_TEST_CMD when none are given.
git-stack-test() {
  local cmd="${*:-$GIT_STACK_TEST_CMD}"
  if [[ -z $cmd ]]; then
    echo "usage: git-stack-test <command>  (or set GIT_STACK_TEST_CMD)" >&2
    return 2
  fi
  git rebase --exec "$cmd" "$(git merge-base HEAD "$(git-base-branch)")"
}

git-merged-list() {
  local base
  base=$(git-base-branch)
  git branch --merged "$base" --format='%(refname:short)' | grep -vx -- "$base"
}

git-merged-delete() {
  local branches
  branches=$(git-merged-list)
  if [[ -z "$branches" ]]; then
    echo "No merged branches to delete."
    return 0
  fi
  echo "Deleting:"
  echo "$branches"
  echo "$branches" | xargs git branch -d
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
