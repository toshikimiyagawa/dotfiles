#!/bin/bash

set -e

DOTFILES_DIR="${DOTFILES_DIR:-$(cd "$(dirname "$0")" && pwd)}"

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
link "$DOTFILES_DIR/.zshrc"      "$HOME/.zshrc"
link "$DOTFILES_DIR/.zimrc"      "$HOME/.zimrc"
link "$DOTFILES_DIR/.fzf.zsh"   "$HOME/.fzf.zsh"
link "$DOTFILES_DIR/.zprofile"  "$HOME/.zprofile"
link "$DOTFILES_DIR/.gitconfig" "$HOME/.gitconfig"

# .config はディレクトリ単位でリンクする（既存実体の一回限りの移行は ./migrate-config.sh）
link_config() {
  local src="$DOTFILES_DIR/.config"
  local dst="$HOME/.config"

  if [ -L "$dst" ]; then
    if [ "$(readlink "$dst")" = "$src" ]; then
      ok "$dst -> $src (既にリンク済み)"
    else
      rm "$dst"
      ln -s "$src" "$dst"
      ok "$dst -> $src"
    fi
  elif [ -d "$dst" ]; then
    warn "$dst は実ディレクトリです。'./migrate-config.sh' を実行して移行してください（.config のリンクはスキップ）"
  elif [ -e "$dst" ]; then
    warn "$dst が予期しないファイルです。手動で確認してください（.config のリンクはスキップ）"
  else
    mkdir -p "$(dirname "$dst")"
    ln -s "$src" "$dst"
    ok "$dst -> $src"
  fi
}
link_config

# chpwd-recent-dirs (cdr) のキャッシュファイルを用意
CHPWD_RECENT_DIRS="$HOME/.cache/shell/chpwd-recent-dirs"
if [ ! -f "$CHPWD_RECENT_DIRS" ]; then
  mkdir -p "$(dirname "$CHPWD_RECENT_DIRS")"
  touch "$CHPWD_RECENT_DIRS"
  ok "作成: $CHPWD_RECENT_DIRS"
fi

info "完了"
