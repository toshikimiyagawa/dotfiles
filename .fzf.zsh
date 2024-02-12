# Setup fzf
# ---------
#if [[ ! "$PATH" == */opt/homebrew/opt/fzf/bin* ]]; then
#  PATH="${PATH:+${PATH}:}/opt/homebrew/opt/fzf/bin"
#fi

# Auto-completion
# ---------------
source "~/.config/fzf/completion.zsh"

# Key bindings
# ------------
source "~/.config/fzf/key-bindings.zsh"

function ghq-fzf() {
  local target_dir=$(ghq list -p | fzf --query="$LBUFFER")

  if [ -n "$target_dir" ]; then
    BUFFER="cd ${target_dir}"
    zle accept-line
  fi

  zle reset-prompt
}
zle -N ghq-fzf
bindkey "^j" ghq-fzf
