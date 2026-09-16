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

# Default test command for the current repo: $GIT_STACK_TEST_CMD if set,
# else inferred from the build system found at the repo root.  Prints
# nothing (and fails) when it can't tell.
git-test-cmd() {
  if [[ -n $GIT_STACK_TEST_CMD ]]; then
    print -r -- "$GIT_STACK_TEST_CMD"
    return
  fi
  local root
  root=$(git rev-parse --show-toplevel 2>/dev/null) || return 1
  if [[ -f $root/MODULE.bazel || -f $root/WORKSPACE || -f $root/WORKSPACE.bazel ]]; then
    print -r -- "bazel test //..."
  elif [[ -f $root/justfile || -f $root/Justfile ]] && just --list 2>/dev/null | grep -qE '^\s+test\b'; then
    print -r -- "just test"
  elif [[ -f $root/Cargo.toml ]]; then
    print -r -- "cargo test"
  elif [[ -f $root/go.mod ]]; then
    print -r -- "go test ./..."
  elif [[ -f $root/package.json ]] && grep -q '"test"' "$root/package.json"; then
    print -r -- "npm test"
  elif [[ -f $root/pyproject.toml || -f $root/pytest.ini ]]; then
    print -r -- "pytest"
  else
    return 1
  fi
}

# Run a command on every commit in the stack: the arguments, or
# git-test-cmd's default when none are given.
git-stack-test() {
  local cmd="${*:-$(git-test-cmd)}"
  if [[ -z $cmd ]]; then
    echo "usage: git-stack-test <command>  (no default test command detected for this repo; set GIT_STACK_TEST_CMD)" >&2
    return 2
  fi
  echo "→ $cmd on each commit since $(git-base-branch)" >&2
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
