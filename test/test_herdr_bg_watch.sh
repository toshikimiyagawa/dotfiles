#!/bin/bash
# .config/herdr/bin/herdr-bg-watch のテスト。偽の herdr を使い、本物の herdr には繋がない。
# ロックは一時ディレクトリの TMPDIR の下に作る。
HERE="$(cd "$(dirname "$0")" && pwd)"
. "$HERE/lib.sh"
REPO="$(cd "$HERE/.." && pwd)"
SCRIPT="$REPO/.config/herdr/bin/herdr-bg-watch"

echo "TEST: herdr-bg-watch"

# このテストは herdr のペインの中で走ることがある。本物の herdr に触れないように消す
unset HERDR_PANE_ID HERDR_BG_WATCH_ONCE HERDR_BG_WATCH_INTERVAL HERDR_BG_WATCH_DETACHED HERDR_BG_WATCH_PERL

if [ -x "$SCRIPT" ]; then pass "script is executable"; else fail "script is not executable"; fi

# 偽の herdr: 呼ばれた引数を 1 行ずつ calls に記録する。
#   pane list   : 呼ばれた回数を数え、list.json を返す。fail_after に N があれば N 回目より後は失敗する
#   agent read  : screen.<pane>.<pane list の回数> か screen.<pane> を返す（無ければ失敗する）
setup_fakes() {
  T="$(mktemp -d)"
  mkdir -p "$T/bin" "$T/tmp"
  cat > "$T/bin/herdr" <<'EOF'
#!/bin/sh
echo "$*" >> "$FAKE_DIR/calls"
case "$1 $2" in
  "pane list")
    n=$(cat "$FAKE_DIR/list_n" 2>/dev/null || echo 0)
    n=$((n + 1))
    echo "$n" > "$FAKE_DIR/list_n"
    if [ -f "$FAKE_DIR/fail_after" ] && [ "$n" -gt "$(cat "$FAKE_DIR/fail_after")" ]; then exit 1; fi
    cat "$FAKE_DIR/list.json"
    ;;
  "agent read")
    n=$(cat "$FAKE_DIR/list_n")
    if [ -f "$FAKE_DIR/screen.$3.$n" ]; then cat "$FAKE_DIR/screen.$3.$n"
    elif [ -f "$FAKE_DIR/screen.$3" ]; then cat "$FAKE_DIR/screen.$3"
    else exit 1; fi
    ;;
esac
exit 0
EOF
  chmod +x "$T/bin/herdr"
  export FAKE_DIR="$T"
  LOCK="$T/tmp/herdr-bg-watch.$(id -u).lock"
}

teardown_fakes() { rm -rf "$T"; }

# 監視を動かす。切り離さない（HERDR_BG_WATCH_DETACHED=1）。待つのは最大 10 秒（それを超えたら止めて 124 を返す）
run_watch() {
  HERDR_BG_WATCH_DETACHED=1 HERDR_BG_WATCH_HERDR="$T/bin/herdr" HERDR_BG_WATCH_INTERVAL=0 TMPDIR="$T/tmp" \
    sh "$SCRIPT" </dev/null >"$T/out" 2>&1 &
  local pid=$! i=0
  while kill -0 "$pid" 2>/dev/null; do
    i=$((i + 1))
    if [ "$i" -gt 100 ]; then kill "$pid" 2>/dev/null; wait "$pid" 2>/dev/null; return 124; fi
    sleep 0.1
  done
  wait "$pid"
}

assert_called() {
  if grep -qxF -- "$1" "$T/calls" 2>/dev/null; then pass "called: $1"; else fail "not called: $1 (calls: $(cat "$T/calls" 2>&1))"; fi
}
assert_not_called_like() {
  if grep -qF -- "$1" "$T/calls" 2>/dev/null; then fail "unexpectedly called: $1 (calls: $(cat "$T/calls" 2>&1))"; else pass "not called: $1"; fi
}
assert_no_lock() {
  if [ ! -e "$LOCK" ]; then pass "$1: lock removed"; else fail "$1: lock remains"; fi
}

BG_SHELL='⏵⏵ auto mode on · 1 shell · ↓ to manage'
BG_SUBAGENT='⏵⏵ auto mode on (shift+tab to cycle) · esc to interrupt · ↓ to manage
  ⏺ main
  ◯ general-purpose  調べもの'
NO_BG='⏵⏵ auto mode on (shift+tab to cycle)'
TWO_CLAUDE='{"result":{"panes":[{"pane_id":"p1","agent":"claude"},{"pane_id":"p2","agent":"claude"}]}}'
MARK_P1='pane report-metadata p1 --source herdr-bg-watch --token bg=⧗ --ttl-ms 10000'
CLEAR_P1='pane report-metadata p1 --source herdr-bg-watch --clear-token bg'

# B1: claude のペインが 2 つあり、片方にだけ ↓ to manage があれば、そのペインにだけ送る
setup_fakes
echo "$TWO_CLAUDE" > "$T/list.json"
printf 'こんにちは\n%s   \n\n' "$BG_SHELL" > "$T/screen.p1"
printf 'こんにちは\n%s\n' "$NO_BG" > "$T/screen.p2"
HERDR_BG_WATCH_ONCE=1 run_watch
rc=$?
if [ "$rc" -eq 0 ]; then pass "B1: exit 0"; else fail "B1: exit code $rc"; fi
assert_called "agent read p1 --source recent --lines 40"
assert_called "agent read p2 --source recent --lines 40"
assert_called "$MARK_P1"
assert_not_called_like "report-metadata p2"
assert_not_called_like "--clear-token"
assert_no_lock "B1/B7"
teardown_fakes

# B1: サブエージェントの表示（モード表示の行の下にタスクの一覧）でも送る
setup_fakes
echo '{"result":{"panes":[{"pane_id":"p1","agent":"claude"}]}}' > "$T/list.json"
printf '%s\n' "$BG_SUBAGENT" > "$T/screen.p1"
HERDR_BG_WATCH_ONCE=1 run_watch
assert_called "$MARK_P1"
teardown_fakes

# B2: claude ではないペイン（agent が無い・別の値）は読まない
setup_fakes
echo '{"result":{"panes":[{"pane_id":"p1","agent":"claude"},{"pane_id":"p3"},{"pane_id":"p4","agent":"codex"},{"pane_id":"p5","agent":null}]}}' > "$T/list.json"
for p in p1 p3 p4 p5; do printf '%s\n' "$BG_SHELL" > "$T/screen.$p"; done
HERDR_BG_WATCH_ONCE=1 run_watch
assert_called "$MARK_P1"
assert_not_called_like " p3 "
assert_not_called_like " p4 "
assert_not_called_like " p5 "
teardown_fakes

# B3: 送ったペインが次の回で ↓ to manage を出さなくなれば消す。送っていないペインには消すものを送らない。
# 1 つのプロセスで回す: 1 回目は p1 にあり、2 回目は無く、その後 pane list を 3 回失敗させて終わらせる
setup_fakes
echo "$TWO_CLAUDE" > "$T/list.json"
printf '%s\n' "$BG_SHELL" > "$T/screen.p1.1"
printf '%s\n' "$NO_BG" > "$T/screen.p1.2"
printf '%s\n' "$NO_BG" > "$T/screen.p2"
echo 2 > "$T/fail_after"
run_watch
rc=$?
if [ "$rc" -eq 0 ]; then pass "B3: exit 0"; else fail "B3: exit code $rc"; fi
if [ "$(grep -cxF -- "$MARK_P1" "$T/calls")" -eq 1 ]; then pass "B3: marked once"; else fail "B3: mark count: $(cat "$T/calls")"; fi
if [ "$(grep -cxF -- "$CLEAR_P1" "$T/calls")" -eq 1 ]; then pass "B3: cleared once"; else fail "B3: clear count: $(cat "$T/calls")"; fi
if [ "$(grep -n -xF -- "$MARK_P1" "$T/calls" | cut -d: -f1)" -lt "$(grep -n -xF -- "$CLEAR_P1" "$T/calls" | cut -d: -f1)" ]; then
  pass "B3: clear comes after mark"
else
  fail "B3: order: $(cat "$T/calls")"
fi
assert_not_called_like "report-metadata p2"
assert_no_lock "B3/B7"
teardown_fakes

# B4: pane list が 3 回続けて失敗すると、0 で終わる
setup_fakes
echo 0 > "$T/fail_after"
run_watch
rc=$?
if [ "$rc" -eq 0 ]; then pass "B4: exit 0"; else fail "B4: exit code $rc"; fi
if [ "$(grep -cx 'pane list' "$T/calls")" -eq 3 ]; then pass "B4: pane list called 3 times"; else fail "B4: calls: $(cat "$T/calls")"; fi
assert_no_lock "B4/B7"
teardown_fakes

# B5: ロックを持つプロセスが生きていれば、2 つ目は herdr を呼ばずにすぐ 0 で終わる
setup_fakes
echo '{"result":{"panes":[]}}' > "$T/list.json"
sleep 30 &
holder=$!
mkdir -p "$LOCK"
echo "$holder" > "$LOCK/pid"
HERDR_BG_WATCH_ONCE= run_watch
rc=$?
if [ "$rc" -eq 0 ]; then pass "B5: exit 0"; else fail "B5: exit code $rc"; fi
if [ ! -e "$T/calls" ]; then pass "B5: herdr not called"; else fail "B5: herdr called: $(cat "$T/calls")"; fi
assert_file_eq "$LOCK/pid" "$holder"
kill "$holder" 2>/dev/null
wait "$holder" 2>/dev/null
teardown_fakes

# B6: 古いロック（pid のプロセスが無い）は取り直して動く。終わればロックは残らない（B7）
setup_fakes
echo "$TWO_CLAUDE" > "$T/list.json"
printf '%s\n' "$BG_SHELL" > "$T/screen.p1"
printf '%s\n' "$NO_BG" > "$T/screen.p2"
sh -c 'exit 0' &
dead=$!
wait "$dead"
mkdir -p "$LOCK"
echo "$dead" > "$LOCK/pid"
HERDR_BG_WATCH_ONCE=1 run_watch
rc=$?
if [ "$rc" -eq 0 ]; then pass "B6: exit 0"; else fail "B6: exit code $rc"; fi
assert_called "$MARK_P1"
assert_no_lock "B6/B7"
teardown_fakes

# B6: pid のファイルが無いロックも、古いロックとして取り直す
setup_fakes
echo '{"result":{"panes":[]}}' > "$T/list.json"
mkdir -p "$LOCK"
HERDR_BG_WATCH_ONCE=1 run_watch
assert_called "pane list"
assert_no_lock "B6 (no pid)/B7"
teardown_fakes

# B8: ↓ to manage が行の途中にあるだけなら送らない。行末の空白は無視する。
# 「 · /tasks to see subagents」を含む行があれば送る
setup_fakes
echo '{"result":{"panes":[{"pane_id":"p1","agent":"claude"},{"pane_id":"p2","agent":"claude"},{"pane_id":"p3","agent":"claude"}]}}' > "$T/list.json"
printf '「↓ to manage」が出たら裏で動いている、と説明した\n%s\n' "$NO_BG" > "$T/screen.p1"
printf 'x\n⏵⏵ bypass permissions on · 1 shell · ↓ to manage \t \n' > "$T/screen.p2"
printf '⏵⏵ auto mode on (shift+tab to cycle) · /tasks to see subagents\n' > "$T/screen.p3"
HERDR_BG_WATCH_ONCE=1 run_watch
assert_not_called_like "report-metadata p1"
assert_called 'pane report-metadata p2 --source herdr-bg-watch --token bg=⧗ --ttl-ms 10000'
assert_called 'pane report-metadata p3 --source herdr-bg-watch --token bg=⧗ --ttl-ms 10000'
teardown_fakes

# 読めないペインは飛ばして続ける
setup_fakes
echo "$TWO_CLAUDE" > "$T/list.json"
printf '%s\n' "$BG_SHELL" > "$T/screen.p2"
HERDR_BG_WATCH_ONCE=1 run_watch
rc=$?
if [ "$rc" -eq 0 ]; then pass "unreadable pane: exit 0"; else fail "unreadable pane: exit code $rc"; fi
assert_called 'pane report-metadata p2 --source herdr-bg-watch --token bg=⧗ --ttl-ms 10000'
teardown_fakes

# B9: HERDR_BG_WATCH_DETACHED も HERDR_BG_WATCH_ONCE も無いとき、perl で setsid して自分を動かし直し、
# 元のプロセスは herdr を呼ばずに 0 で終わる。偽の perl は引数と環境を記録するだけで、監視は動かさない
setup_fakes
echo '{"result":{"panes":[]}}' > "$T/list.json"
cat > "$T/bin/perl" <<'EOF'
#!/bin/sh
for a in "$@"; do printf '%s\n' "$a"; done > "$FAKE_DIR/perl_args.tmp"
env > "$FAKE_DIR/perl_env.tmp"
mv "$FAKE_DIR/perl_env.tmp" "$FAKE_DIR/perl_env"
mv "$FAKE_DIR/perl_args.tmp" "$FAKE_DIR/perl_args"
EOF
chmod +x "$T/bin/perl"
HERDR_BG_WATCH_PERL="$T/bin/perl" HERDR_BG_WATCH_HERDR="$T/bin/herdr" HERDR_BG_WATCH_INTERVAL=0 TMPDIR="$T/tmp" \
  sh "$SCRIPT" </dev/null >"$T/out" 2>&1
rc=$?
if [ "$rc" -eq 0 ]; then pass "B9: exit 0"; else fail "B9: exit code $rc"; fi
i=0
while [ ! -f "$T/perl_args" ] && [ "$i" -lt 50 ]; do i=$((i + 1)); sleep 0.1; done
if [ -f "$T/perl_args" ]; then pass "B9: perl started"; else fail "B9: perl not started"; fi
if grep -qxF -- '-MPOSIX' "$T/perl_args" 2>/dev/null; then pass "B9: -MPOSIX"; else fail "B9: args: $(cat "$T/perl_args" 2>&1)"; fi
if grep -qxF -- '-e' "$T/perl_args" 2>/dev/null && grep -qF -- 'POSIX::setsid()' "$T/perl_args"; then pass "B9: -e POSIX::setsid()"; else fail "B9: args: $(cat "$T/perl_args" 2>&1)"; fi
if grep -qxF -- "$SCRIPT" "$T/perl_args" 2>/dev/null; then pass "B9: script absolute path"; else fail "B9: args: $(cat "$T/perl_args" 2>&1)"; fi
if grep -qxF -- 'HERDR_BG_WATCH_DETACHED=1' "$T/perl_env" 2>/dev/null; then pass "B9: HERDR_BG_WATCH_DETACHED=1"; else fail "B9: env lacks HERDR_BG_WATCH_DETACHED=1"; fi
if [ ! -e "$T/calls" ]; then pass "B9: herdr not called"; else fail "B9: herdr called: $(cat "$T/calls")"; fi
assert_no_lock "B9"
teardown_fakes

finish
