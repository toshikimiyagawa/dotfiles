# -----------------
# Zsh configuration
# -----------------

#
# History
#

# Remove older command from the history if a duplicate is to be added.
setopt HIST_IGNORE_ALL_DUPS
setopt IGNORE_EOF

#
# Input/output
#

# Set editor default keymap to emacs (`-e`) or vi (`-v`)
bindkey -e

# Prompt for spelling correction of commands.
#setopt CORRECT

# Customize spelling correction prompt.
#SPROMPT='zsh: correct %F{red}%R%f to %F{green}%r%f [nyae]? '

# Remove path separator from WORDCHARS.
WORDCHARS=${WORDCHARS//[\/]}

stty stop undef
stty start undef

alias vi="nvim"
alias vim="nvim"

export KEYTIMEOUT=1
export GOPATH=$HOME/go
export PYENV_ROOT=$HOME/.pyenv
export PATH=$PATH:$GOPATH/bin:$PYENV_ROOT/bin

bindkey '\e' send-break

## fzf
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
export FZF_DEFAULT_OPTS='--no-height --reverse'
export FZF_CTRL_R_OPTS='--preview "echo {}"'
# export _ZO_FZF_OPTS='--no-height --reverse'

## zimfw
ZIM_HOME=~/.zim
# Install missing modules and update ${ZIM_HOME}/init.zsh if missing or outdated.
if [[ ! ${ZIM_HOME}/init.zsh -nt ${ZIM_CONFIG_FILE:-${ZDOTDIR:-${HOME}}/.zimrc} ]]; then
    source /opt/homebrew/opt/zimfw/share/zimfw.zsh init
fi
# Initialize modules.
source ${ZIM_HOME}/init.zsh

## starship
export STARSHIP_CONFIG="$HOME/.config/starship.toml"
eval "$(starship init zsh)"

# cdr, add-zsh-hook を有効にする
autoload -Uz chpwd_recent_dirs cdr add-zsh-hook
add-zsh-hook chpwd chpwd_recent_dirs

# cdrを有効にして設定する
zstyle ':completion:*' recent-dirs-insert both
zstyle ':chpwd:*' recent-dirs-max 500
zstyle ':chpwd:*' recent-dirs-default true
zstyle ':chpwd:*' recent-dirs-file "$HOME/.cache/shell/chpwd-recent-dirs"
zstyle ':chpwd:*' recent-dirs-pushd true

# AUTO_CDの対象に ~ と上位ディレクトリを加える
cdpath=(~ ..)

function fzf-cdr() {
    # 選択したリポジトリへ移動 かつ
  local src=$(cdr -l | awk '{ print $2 }' | fzf)
  if [ -n "$src" ]; then
    BUFFER="cd $src"
    zle accept-line
  fi
  zle -R -c
}
zle -N fzf-cdr
bindkey '^s' fzf-cdr

function ghq-fzf_change_directory() {
    # 選択したリポジトリへ移動 かつ
    # 右にリポジトリのディレクトリ詳細を表示
  local src=$(ghq list | fzf --preview "eza -l -g -a --icons $(ghq root)/{} | tail -n+4 | awk '{print \$6\"/\"\$8\" \"\$9 \" \" \$10}'")
  if [ -n "$src" ]; then
    BUFFER="cd $(ghq root)/$src"
    zle accept-line
  fi
  zle -R -c
}
zle -N ghq-fzf_change_directory
bindkey '^q' ghq-fzf_change_directory

# ==============================================================================
# SOPS を使用した暗号化環境変数の自動展開（修正版）
# ==============================================================================
SECRET_ENV_FILE="$HOME/.config/sops/secrets/secrets.sops.env" # ファイルの実際のパスに合わせて変更してください

if [ -f "$SECRET_ENV_FILE" ] && command -v sops >/dev/null 2>&1; then
    # sopsで複合した内容を1行ずつ読み込む（idx, を削除して正常なzsh構文に修正）
    while read -r line || [ -n "$line" ]; do
        # 空行やコメント行（#始まり）はスキップ
        [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
        
        # 各行を export コマンドとして実行
        export "$line"
    done < <(sops -d --output-type dotenv "$SECRET_ENV_FILE" 2>/dev/null)
fi
