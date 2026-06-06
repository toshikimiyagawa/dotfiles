#!/bin/bash
# テスト用の共通ヘルパー（bash 3.2 互換）。各テストは set -e を使わない（全アサーションを実行するため）。

FAILS=0

pass() { echo "  PASS: $*"; }
fail() { echo "  FAIL: $*"; FAILS=$((FAILS + 1)); }

assert_symlink_to() {
  local link="$1" target="$2"
  if [ -L "$link" ] && [ "$(readlink "$link")" = "$target" ]; then
    pass "symlink $link -> $target"
  else
    fail "expected symlink $link -> $target (got: $(ls -ld "$link" 2>&1))"
  fi
}

assert_is_dir() {
  if [ -d "$1" ] && [ ! -L "$1" ]; then pass "real dir: $1"; else fail "expected real dir: $1"; fi
}

assert_file_eq() {
  local f="$1" expected="$2"
  if [ -f "$f" ] && [ "$(cat "$f")" = "$expected" ]; then
    pass "file content ok: $f"
  else
    fail "expected '$f' to contain '$expected' (got: $(cat "$f" 2>&1))"
  fi
}

assert_exists() { if [ -e "$1" ]; then pass "exists: $1"; else fail "expected to exist: $1"; fi; }

assert_output_contains() {
  case "$1" in
    *"$2"*) pass "output contains: $2" ;;
    *) fail "output missing: $2" ;;
  esac
}

# 偽の dotfiles リポジトリ（git 初期化済み）と偽 HOME を作る。
# 実行後は $SANDBOX / $HOME / $DOTFILES_DIR が使える。
setup_sandbox() {
  SANDBOX="$(mktemp -d)"
  export HOME="$SANDBOX/home"
  export DOTFILES_DIR="$SANDBOX/dotfiles"
  mkdir -p "$HOME" "$DOTFILES_DIR/.config"

  git -C "$DOTFILES_DIR" init -q
  git -C "$DOTFILES_DIR" config user.email test@example.com
  git -C "$DOTFILES_DIR" config user.name test

  printf '.config/op/\n' > "$DOTFILES_DIR/.gitignore"
  mkdir -p "$DOTFILES_DIR/.config/bat" "$DOTFILES_DIR/.config/gh"
  printf 'bat-config\n' > "$DOTFILES_DIR/.config/bat/config"
  printf 'repo-version\n' > "$DOTFILES_DIR/.config/gh/config.yml"
  git -C "$DOTFILES_DIR" add -A
  git -C "$DOTFILES_DIR" commit -qm init
}

teardown_sandbox() { if [ -n "$SANDBOX" ]; then rm -rf "$SANDBOX"; fi; }

finish() {
  echo
  if [ "$FAILS" -eq 0 ]; then echo "ALL PASS"; exit 0; else echo "$FAILS FAILED"; exit 1; fi
}
