#!/bin/bash
HERE="$(cd "$(dirname "$0")" && pwd)"
. "$HERE/lib.sh"
REPO="$(cd "$HERE/.." && pwd)"

echo "TEST: migrate-config.sh"
setup_sandbox

# 偽 ~/.config（実ディレクトリ）に4ケースを作る
mkdir -p "$HOME/.config"
ln -s "$DOTFILES_DIR/.config/bat" "$HOME/.config/bat"                 # 1) repo 内を指す symlink
mkdir -p "$HOME/.config/newapp"; printf 'hello\n' > "$HOME/.config/newapp/conf"  # 2) 新規・追跡対象
mkdir -p "$HOME/.config/op";     printf 'secret\n' > "$HOME/.config/op/token"    # 3) 新規・gitignore 対象
mkdir -p "$HOME/.config/gh";     printf 'local-version\n' > "$HOME/.config/gh/config.yml"  # 4) 衝突

OUT="$(DOTFILES_DIR="$DOTFILES_DIR" HOME="$HOME" bash "$REPO/migrate-config.sh" 2>&1)"
echo "$OUT" | sed 's/^/    > /'

# ~/.config がリンク化された
assert_symlink_to "$HOME/.config" "$DOTFILES_DIR/.config"
# 退避ディレクトリができている
BAK="$(ls -d "$HOME"/.config.bak.* 2>/dev/null | head -1)"
assert_exists "$BAK"
# 2) 新規・追跡対象としてコピーされた
assert_file_eq "$DOTFILES_DIR/.config/newapp/conf" "hello"
if git -C "$DOTFILES_DIR" check-ignore -q ".config/newapp/conf"; then fail "newapp が ignore された"; else pass "newapp は追跡対象"; fi
# 3) gitignore 対象としてコピーされた（非追跡）
assert_file_eq "$DOTFILES_DIR/.config/op/token" "secret"
if git -C "$DOTFILES_DIR" check-ignore -q ".config/op/token"; then pass "op は非追跡(ignore)"; else fail "op が追跡対象になった"; fi
# 4) 衝突は上書きされない（repo 版のまま）／diff 表示／原本は退避先に残る
assert_file_eq "$DOTFILES_DIR/.config/gh/config.yml" "repo-version"
assert_output_contains "$OUT" "衝突"
assert_file_eq "$BAK/gh/config.yml" "local-version"

# 冪等: 再実行で「既に移行済み」
OUT2="$(DOTFILES_DIR="$DOTFILES_DIR" HOME="$HOME" bash "$REPO/migrate-config.sh" 2>&1)"
assert_output_contains "$OUT2" "既に移行済み"

teardown_sandbox
finish
