#!/bin/bash

set -e

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"

info()  { echo "[INFO]  $*"; }
ok()    { echo "[OK]    $*"; }
warn()  { echo "[WARN]  $*"; }

link() {
  local src="$1"
  local dst="$2"

  mkdir -p "$(dirname "$dst")"

  if [ -L "$dst" ]; then
    rm "$dst"
  elif [ -e "$dst" ]; then
    warn "既存ファイルをバックアップ: $dst -> $dst.bak"
    mv "$dst" "$dst.bak"
  fi

  ln -sf "$src" "$dst"
  ok "$dst -> $src"
}

info "dotfiles のシンボリックリンクを設定します: $DOTFILES_DIR"

# ホームディレクトリの dotfiles
link "$DOTFILES_DIR/.zshrc"   "$HOME/.zshrc"
link "$DOTFILES_DIR/.zimrc"   "$HOME/.zimrc"
link "$DOTFILES_DIR/.fzf.zsh" "$HOME/.fzf.zsh"

# .config 配下（git 管理対象のもの）
link "$DOTFILES_DIR/.config/ghostty"   "$HOME/.config/ghostty"
link "$DOTFILES_DIR/.config/bat"       "$HOME/.config/bat"
link "$DOTFILES_DIR/.config/nvim"      "$HOME/.config/nvim"
link "$DOTFILES_DIR/.config/karabiner" "$HOME/.config/karabiner"
link "$DOTFILES_DIR/.config/git"       "$HOME/.config/git"
link "$DOTFILES_DIR/.config/cmux"      "$HOME/.config/cmux"

# 除外: .config/1Password, .config/iterm2, .config/op は git 管理外のため手動設定

info "完了"
