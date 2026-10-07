# fzf - general-purpose command-line fuzzy finder
# https://github.com/junegunn/fzf
source <(fzf --zsh 2>/dev/null)

export FZF_DEFAULT_COMMAND='fd --type f --hidden --exclude .git'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
_fzf_compgen_path() { fd --type f --hidden --exclude .git . "$1" }
_fzf_compgen_dir()  { fd --type d --hidden --exclude .git . "$1" }
