#!/bin/bash
HERE="$(cd "$(dirname "$0")" && pwd)"
. "$HERE/lib.sh"
REPO="$(cd "$HERE/.." && pwd)"

echo "TEST: migrate-config.sh"

# --- シナリオA: 実ディレクトリからの移行（4ケース）---
setup_sandbox
mkdir -p "$HOME/.config"
ln -s "$DOTFILES_DIR/.config/bat" "$HOME/.config/bat"                 # 1) repo 内を指す symlink
mkdir -p "$HOME/.config/newapp"; printf 'hello\n' > "$HOME/.config/newapp/conf"  # 2) 新規・追跡対象
mkdir -p "$HOME/.config/op";     printf 'secret\n' > "$HOME/.config/op/token"    # 3) 新規・gitignore 対象
mkdir -p "$HOME/.config/gh";     printf 'local-version\n' > "$HOME/.config/gh/config.yml"  # 4) 衝突

OUT="$(DOTFILES_DIR="$DOTFILES_DIR" HOME="$HOME" "$REPO/migrate-config.sh" 2>&1)"; RC=$?
echo "$OUT" | sed 's/^/    > /'

if [ "$RC" -eq 0 ]; then pass "exit 0"; else fail "expected exit 0, got $RC"; fi
assert_symlink_to "$HOME/.config" "$DOTFILES_DIR/.config"
BAK="$(ls -d "$HOME"/.config.bak.* 2>/dev/null | head -1)"
assert_exists "$BAK"
# サマリに退避先パスが正しく出る（bash 3.2 で変数直後のマルチバイトが化けない）
assert_output_contains "$OUT" "$BAK"
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
# 1) repo 内を指す symlink はスキップされる
assert_output_contains "$OUT" "スキップ (repo 内リンク)"

# 冪等: 再実行で「既に移行済み」かつ exit 0
OUT2="$(DOTFILES_DIR="$DOTFILES_DIR" HOME="$HOME" "$REPO/migrate-config.sh" 2>&1)"; RC2=$?
assert_output_contains "$OUT2" "既に移行済み"
if [ "$RC2" -eq 0 ]; then pass "再実行 exit 0"; else fail "expected exit 0, got $RC2"; fi
teardown_sandbox

# --- シナリオB: ~/.config が別の場所へのリンク → exit 1 ---
setup_sandbox
rm -rf "$HOME/.config"; mkdir -p "$SANDBOX/elsewhere"; ln -s "$SANDBOX/elsewhere" "$HOME/.config"
OUT="$(DOTFILES_DIR="$DOTFILES_DIR" HOME="$HOME" "$REPO/migrate-config.sh" 2>&1)"; RC=$?
if [ "$RC" -eq 1 ]; then pass "別リンクで exit 1"; else fail "expected exit 1, got $RC"; fi
teardown_sandbox

# --- シナリオC: ~/.config が実ファイル → exit 1 ---
setup_sandbox
rm -rf "$HOME/.config"; printf 'x' > "$HOME/.config"
OUT="$(DOTFILES_DIR="$DOTFILES_DIR" HOME="$HOME" "$REPO/migrate-config.sh" 2>&1)"; RC=$?
if [ "$RC" -eq 1 ]; then pass "実ファイルで exit 1"; else fail "expected exit 1, got $RC"; fi
teardown_sandbox

# --- シナリオD: ~/.config が存在しない → exit 0 ---
setup_sandbox
rm -rf "$HOME/.config"
OUT="$(DOTFILES_DIR="$DOTFILES_DIR" HOME="$HOME" "$REPO/migrate-config.sh" 2>&1)"; RC=$?
if [ "$RC" -eq 0 ]; then pass "未存在で exit 0"; else fail "expected exit 0, got $RC"; fi
teardown_sandbox

# --- シナリオE: コピー先がブロックされ失敗 → 「コピー失敗」と正しく報告（虚偽成功でない）---
setup_sandbox
# repo に .config/blocked をファイルとして追跡。backup 側は blocked/child を持つため
# mkdir -p .config/blocked が失敗し、コピーできない。
printf 'iamfile\n' > "$DOTFILES_DIR/.config/blocked"
git -C "$DOTFILES_DIR" add -A
git -C "$DOTFILES_DIR" commit -qm blocked
mkdir -p "$HOME/.config/blocked"; printf 'data\n' > "$HOME/.config/blocked/child"
OUT="$(DOTFILES_DIR="$DOTFILES_DIR" HOME="$HOME" "$REPO/migrate-config.sh" 2>&1)"; RC=$?
echo "$OUT" | sed 's/^/    > /'
assert_output_contains "$OUT" "コピー失敗"
teardown_sandbox

finish
