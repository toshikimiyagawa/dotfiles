#!/bin/bash
# .zshrc の ghq-fzf_change_directory（^q）のテスト。偽の fzf・ghq を使い、fzf に渡る引数を確認する。
HERE="$(cd "$(dirname "$0")" && pwd)"
. "$HERE/lib.sh"
REPO="$(cd "$HERE/.." && pwd)"
ZSHRC="$REPO/.zshrc"

echo "TEST: zshrc ghq-fzf_change_directory"

if ! command -v zsh >/dev/null 2>&1; then
  echo "  SKIP: zsh が無いので何もしない"
  finish
fi

T="$(mktemp -d)"
trap 'rm -rf "$T"' EXIT
mkdir -p "$T/bin" "$T/root/ghq-repo"
touch "$T/root/ghq-repo/alpha.txt" "$T/root/ghq-repo/beta.txt"

# 関数の定義だけを .zshrc から取り出す
sed -n '/^function ghq-fzf_change_directory() {/,/^}/p' "$ZSHRC" > "$T/func.zsh"

# 偽の fzf: 引数を 1 行ずつ記録し、何も選ばずに終わる。偽の ghq: list は 1 件、root は一時ディレクトリ
cat > "$T/bin/fzf" <<'EOS'
#!/bin/sh
cat > /dev/null
printf '%s\n' "$@" > "$FAKE_DIR/fzf_args"
EOS
cat > "$T/bin/ghq" <<'EOS'
#!/bin/sh
case "$1" in
  list) echo ghq-repo ;;
  root) printf '%s\n' "$FAKE_DIR/root" ;;
esac
EOS
chmod +x "$T/bin/fzf" "$T/bin/ghq"

# 指定した LINES で関数を呼び、fzf の引数を $T/fzf_args に残す
run_func() {
  rm -f "$T/fzf_args"
  FAKE_DIR="$T" PATH="$T/bin:$PATH" LINES_IN="$1" zsh -c '
    zle() { :; }
    . "$FAKE_DIR/func.zsh"
    LINES=$LINES_IN
    ghq-fzf_change_directory
  ' >/dev/null 2>&1
}

# 記録した引数から、指定したオプションの次の行を取り出す
arg_after() {
  awk -v k="$1" 'f { print; exit } $0 == k { f = 1 }' "$T/fzf_args"
}

# 高さ N を取り出す（down,N の N）

# Z1: --preview-window が down で始まる
run_func 50
PW="$(arg_after --preview-window)"
case "$PW" in
  down*) pass "Z1: --preview-window is '$PW'" ;;
  *) fail "Z1: --preview-window should start with down (got: '$PW')" ;;
esac

# Z2: --preview のコマンドを本物の eza で実行する
if command -v eza >/dev/null 2>&1; then
  PREVIEW="$(arg_after --preview)"
  CMD="$(printf '%s' "$PREVIEW" | sed 's/{}/ghq-repo/g')"
  OUT="$(sh -c "$CMD" 2>"$T/err")"
  RC=$?
  if [ "$RC" -eq 0 ] && [ ! -s "$T/err" ] \
     && printf '%s' "$OUT" | grep -q alpha.txt && printf '%s' "$OUT" | grep -q beta.txt; then
    pass "Z2: preview command lists the repo (rc=0, no stderr)"
  else
    fail "Z2: preview command failed (rc=$RC, stderr=$(cat "$T/err"), out=$OUT, cmd=$CMD)"
  fi
else
  echo "  SKIP: Z2: eza が無いので飛ばす"
fi

# Z3: 式どおりの高さ
PW50="$(run_func 50; arg_after --preview-window)"
PW30="$(run_func 30; arg_after --preview-window)"
if [ "$PW50" = "down,33" ]; then pass "Z3: LINES=50 -> down,33"; else fail "Z3: LINES=50 expected down,33 (got: '$PW50')"; fi
if [ "$PW30" = "down,16" ]; then pass "Z3: LINES=30 -> down,16"; else fail "Z3: LINES=30 expected down,16 (got: '$PW30')"; fi

# Z4: リストに 10 行以上残り、LINES=50 の方が大きい
N50="${PW50#down,}"
N30="${PW30#down,}"
case "$N50$N30" in
  ''|*[!0-9]*) fail "Z4: heights are not numeric (50: '$N50', 30: '$N30')" ;;
  *)
    L50=$((50 - N50 - 2)); L30=$((30 - N30 - 2))
    if [ "$L50" -ge 10 ] && [ "$L30" -ge 10 ]; then pass "Z4: list rows ok (LINES=50: $L50, LINES=30: $L30)"; else fail "Z4: list rows too few (LINES=50: $L50, LINES=30: $L30)"; fi
    if [ "$N50" -gt "$N30" ]; then pass "Z4: preview at LINES=50 ($N50) > LINES=30 ($N30)"; else fail "Z4: preview at 50 ($N50) should be > at 30 ($N30)"; fi
    ;;
esac

finish
