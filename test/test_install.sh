#!/bin/bash
HERE="$(cd "$(dirname "$0")" && pwd)"
. "$HERE/lib.sh"
REPO="$(cd "$HERE/.." && pwd)"

echo "TEST: install.sh の .config 処理"

run_install() {
  # install.sh が参照するホーム直下 dotfiles のソースを偽リポジトリに用意（dangling 回避）
  for f in .zshrc .zimrc .fzf.zsh .zprofile .gitconfig; do touch "$DOTFILES_DIR/$f"; done
  DOTFILES_DIR="$DOTFILES_DIR" HOME="$HOME" "$REPO/install.sh" 2>&1
}

# ケース1: TARGET なし → リンク作成
setup_sandbox
rm -rf "$HOME/.config"
OUT="$(run_install)"
assert_symlink_to "$HOME/.config" "$DOTFILES_DIR/.config"
teardown_sandbox

# ケース2: 正しいリンク済み → no-op
setup_sandbox
rm -rf "$HOME/.config"; ln -s "$DOTFILES_DIR/.config" "$HOME/.config"
OUT="$(run_install)"
assert_symlink_to "$HOME/.config" "$DOTFILES_DIR/.config"
assert_output_contains "$OUT" "既にリンク済み"
teardown_sandbox

# ケース3: 別の場所へのリンク → 張り直し
setup_sandbox
rm -rf "$HOME/.config"; mkdir -p "$SANDBOX/other"; ln -s "$SANDBOX/other" "$HOME/.config"
OUT="$(run_install)"
assert_symlink_to "$HOME/.config" "$DOTFILES_DIR/.config"
teardown_sandbox

# ケース4: 実ディレクトリ → WARN してスキップ（実ディレクトリのまま）
setup_sandbox
rm -rf "$HOME/.config"; mkdir -p "$HOME/.config"; printf 'x' > "$HOME/.config/real"
OUT="$(run_install)"
assert_is_dir "$HOME/.config"
assert_output_contains "$OUT" "migrate-config.sh"
teardown_sandbox

finish
