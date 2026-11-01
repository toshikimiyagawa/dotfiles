#!/bin/bash
# .config/herdr/bin/acn-claude のテスト。偽の ssh・fzf・ghq・claude を使い、本物のコンテナには繋がない。
HERE="$(cd "$(dirname "$0")" && pwd)"
. "$HERE/lib.sh"
REPO="$(cd "$HERE/.." && pwd)"
SCRIPT="$REPO/.config/herdr/bin/acn-claude"

echo "TEST: acn-claude"

# herdr のペインで動かしても、本物の herdr に metadata を送らないように herdr の外として動かす
unset HERDR_PANE_ID

# 偽のコマンドとホストの ghq root を一時ディレクトリに作る
setup_fakes() {
  T="$(mktemp -d)"
  mkdir -p "$T/bin" "$T/remotebin" "$T/hostroot" "$T/croot"

  # 偽の ssh: -t 付き（起動）は引数・リモートのコマンド・HERDR_AGENT を記録する。
  # -t 無し（一覧の取得）は FAKE_CONTAINER_LIST を返す（FAKE_SSH_FAIL があれば失敗する）
  cat > "$T/bin/ssh" <<'EOF'
#!/bin/sh
case " $* " in
  *" -t "*)
    printf '%s\n' "$@" > "$FAKE_DIR/ssh_t_args"
    for a in "$@"; do last=$a; done
    printf '%s' "$last" > "$FAKE_DIR/remote"
    printf '%s' "${HERDR_AGENT:-}" > "$FAKE_DIR/agent"
    ;;
  *)
    printf '%s\n' "$@" > "$FAKE_DIR/ssh_list_args"
    [ -z "${FAKE_SSH_FAIL:-}" ] || exit 255
    printf '%s\n' "$FAKE_CONTAINER_LIST"
    ;;
esac
EOF

  # 偽の fzf: 入力を記録し、FAKE_FZF_KIND の種類の最初の行を出す（空なら何も出さずに 130 で終わる）
  cat > "$T/bin/fzf" <<'EOF'
#!/bin/sh
cat > "$FAKE_DIR/fzf_in"
[ -n "${FAKE_FZF_KIND:-}" ] || exit 130
grep "^$FAKE_FZF_KIND " "$FAKE_DIR/fzf_in" | head -n 1
EOF

  # 偽のホストの ghq: list と root を返す（FAKE_GHQ_FAIL があれば失敗する）
  cat > "$T/bin/ghq" <<'EOF'
#!/bin/sh
[ -z "${FAKE_GHQ_FAIL:-}" ] || exit 1
case "$1" in
  list) printf '%s\n' "$FAKE_HOST_LIST" ;;
  root) printf '%s\n' "$FAKE_DIR/hostroot" ;;
  *) exit 1 ;;
esac
EOF

  # 偽のコンテナの ghq（T4b・T4c でリモートのコマンドを実行するとき用）
  cat > "$T/remotebin/ghq" <<'EOF'
#!/bin/sh
case "$1" in
  root) printf '%s\n' "$FAKE_DIR/croot" ;;
  get)
    printf '%s\n' "$2" > "$FAKE_DIR/ghq_get_arg"
    [ -n "${FAKE_GET_OK:-}" ] || { echo "fake ghq get failed" >&2; exit 1; }
    mkdir -p "$FAKE_DIR/croot/$FAKE_GET_DIR"
    ;;
  *) exit 1 ;;
esac
EOF

  # 偽の claude: 呼ばれたら、そのディレクトリを記録する
  cat > "$T/remotebin/claude" <<'EOF'
#!/bin/sh
pwd > "$FAKE_DIR/claude_called"
EOF

  chmod +x "$T/bin/"* "$T/remotebin/"*

  # ホストのリポジトリ（remote.origin.url を設定しておく）
  for r in github.com/a/hostonly github.com/a/both github.com/x/acn-devcontainer; do
    mkdir -p "$T/hostroot/$r"
    git -C "$T/hostroot/$r" init -q
    git -C "$T/hostroot/$r" config remote.origin.url "git@github.com:${r#github.com/}.git"
  done

  # git worktree（.git がファイル）。一覧に出ないこと
  mkdir -p "$T/hostroot/github.com/a/hostonly.worktrees/feat"
  echo "gitdir: $T/hostroot/github.com/a/hostonly/.git/worktrees/feat" > "$T/hostroot/github.com/a/hostonly.worktrees/feat/.git"

  # 偽の herdr: 引数を記録する
  cat > "$T/bin/herdr" <<'EOF2'
#!/bin/sh
printf '%s\n' "$@" > "$FAKE_DIR/herdr_args"
EOF2
  chmod +x "$T/bin/herdr"

  export FAKE_DIR="$T"
  export FAKE_CONTAINER_LIST="$(printf 'github.com/a/both\ngithub.com/c/conly')"
  export FAKE_HOST_LIST="$(printf 'github.com/a/both\ngithub.com/a/hostonly\ngithub.com/a/hostonly.worktrees/feat\ngithub.com/x/acn-devcontainer')"
  unset FAKE_SSH_FAIL FAKE_FZF_KIND FAKE_GHQ_FAIL FAKE_GET_OK FAKE_GET_DIR ACN_WORKSPACE_DIR
}

run_acn() {
  ACN_SSH_BIN="$T/bin/ssh" ACN_FZF="$T/bin/fzf" ACN_GHQ="$T/bin/ghq" ACN_SSH_HOST=acn-test \
    ACN_HERDR="$T/bin/herdr" HERDR_PANE_ID="${FAKE_PANE_ID-w9:p9}" \
    sh "$SCRIPT" "$@" </dev/null 2>&1
}

teardown_fakes() { rm -rf "$T"; }

# T1: 一覧の並びと中身
setup_fakes
FAKE_FZF_KIND=container run_acn >/dev/null
expected="container  github.com/a/both
container  github.com/c/conly
workspace  /workspaces/acn-devcontainer
get        github.com/a/hostonly"
assert_file_eq "$T/fzf_in" "$expected"
if grep -qx -- '-t' "$T/ssh_list_args"; then fail "T1: list ssh has -t"; else pass "T1: list ssh has no -t"; fi
if grep -q -- '-f "$r/.git"' "$T/ssh_list_args"; then pass "T1: container list skips worktrees"; else fail "T1: container list does not skip worktrees"; fi
teardown_fakes

# T2: container 行を選ぶ
setup_fakes
FAKE_FZF_KIND=container run_acn >/dev/null
assert_file_eq "$T/agent" "claude"
assert_file_eq "$T/ssh_t_args" "-t
-o
SendEnv=COLORTERM
acn-test
cd \"\$(ghq root)\"/'github.com/a/both' && exec claude"
assert_file_eq "$T/remote" "cd \"\$(ghq root)\"/'github.com/a/both' && exec claude"
teardown_fakes

# T3: workspace 行を選ぶ
setup_fakes
FAKE_FZF_KIND=workspace run_acn >/dev/null
assert_file_eq "$T/agent" "claude"
assert_file_eq "$T/remote" "cd '/workspaces/acn-devcontainer' && exec claude"
teardown_fakes

# T4: get 行を選ぶ
setup_fakes
FAKE_FZF_KIND=get run_acn >/dev/null
REMOTE="$(cat "$T/remote")"
assert_file_eq "$T/agent" "claude"
assert_output_contains "$REMOTE" "ghq get 'git@github.com:a/hostonly.git' ||"
assert_output_contains "$REMOTE" "cd \"\$(ghq root)\"/'github.com/a/hostonly' && exec claude"

# T4b: ghq get が失敗したら、メッセージを出して claude を起動せず、0 以外で終わる
OUT="$(cd "$T" && PATH="$T/remotebin:$PATH" sh -c "$REMOTE" </dev/null 2>&1)"
rc=$?
assert_output_contains "$OUT" "ghq get に失敗した"
assert_output_contains "$OUT" "Enter で閉じる"
if [ ! -e "$T/claude_called" ]; then pass "T4b: claude not called"; else fail "T4b: claude was called"; fi
if [ "$rc" -ne 0 ]; then pass "T4b: exit code non-zero ($rc)"; else fail "T4b: exit code was 0"; fi
assert_file_eq "$T/ghq_get_arg" "git@github.com:a/hostonly.git"

# T4c: ghq get が成功したら、そのディレクトリで claude を起動する
OUT="$(cd "$T" && FAKE_GET_OK=1 FAKE_GET_DIR=github.com/a/hostonly PATH="$T/remotebin:$PATH" sh -c "$REMOTE" </dev/null 2>&1)"
assert_exists "$T/claude_called"
case "$(cat "$T/claude_called" 2>/dev/null)" in
  */croot/github.com/a/hostonly) pass "T4c: claude started in the fetched dir" ;;
  *) fail "T4c: claude started in: $(cat "$T/claude_called" 2>&1)" ;;
esac
teardown_fakes

# T8: ホストの ghq が失敗しても、container 行と workspace 行が出て、起動まで進む
setup_fakes
FAKE_GHQ_FAIL=1 FAKE_FZF_KIND=workspace run_acn >/dev/null
assert_file_eq "$T/fzf_in" "container  github.com/a/both
container  github.com/c/conly
workspace  /workspaces/acn-devcontainer"
assert_file_eq "$T/remote" "cd '/workspaces/acn-devcontainer' && exec claude"
teardown_fakes
# ACN_GHQ のコマンドが無いときも同じ
setup_fakes
OUT="$(ACN_SSH_BIN="$T/bin/ssh" ACN_FZF="$T/bin/fzf" ACN_GHQ="$T/no-such-ghq" ACN_HERDR="$T/bin/herdr" FAKE_FZF_KIND=container \
  sh "$SCRIPT" </dev/null 2>&1)"
assert_file_eq "$T/fzf_in" "container  github.com/a/both
container  github.com/c/conly
workspace  /workspaces/acn-devcontainer"
assert_exists "$T/remote"
teardown_fakes

# T5: fzf で何も選ばなければ、-t 付きの ssh は実行されない
setup_fakes
run_acn >/dev/null
rc=$?
if [ ! -e "$T/ssh_t_args" ]; then pass "T5: ssh -t not run"; else fail "T5: ssh -t was run"; fi
if [ "$rc" -eq 0 ]; then pass "T5: exit 0"; else fail "T5: exit code $rc"; fi
teardown_fakes

# T6: 一覧の取得の ssh が失敗したら、-t 付きの ssh は実行されず、0 以外で終わる
setup_fakes
OUT="$(FAKE_SSH_FAIL=1 FAKE_FZF_KIND=container run_acn)"
rc=$?
if [ ! -e "$T/ssh_t_args" ]; then pass "T6: ssh -t not run"; else fail "T6: ssh -t was run"; fi
if [ "$rc" -ne 0 ]; then pass "T6: exit code non-zero ($rc)"; else fail "T6: exit code was 0"; fi
assert_output_contains "$OUT" "Enter で閉じる"
teardown_fakes

# T7: acn-claude <dir> は一覧を取らずに <dir> で起動する
setup_fakes
run_acn "/work/my dir" >/dev/null
if [ ! -e "$T/ssh_list_args" ]; then pass "T7: list not fetched"; else fail "T7: list was fetched"; fi
if [ ! -e "$T/fzf_in" ]; then pass "T7: fzf not run"; else fail "T7: fzf was run"; fi
assert_file_eq "$T/agent" "claude"
assert_file_eq "$T/remote" "cd '/work/my dir' && exec claude"
teardown_fakes

# T9: herdr のエージェント一覧に「c <フォルダ名>」を送る。herdr の外（HERDR_PANE_ID が空）では送らない
setup_fakes
FAKE_FZF_KIND=container run_acn >/dev/null
assert_file_eq "$T/herdr_args" "pane
report-metadata
w9:p9
--source
acn-claude
--token
loc=c both"
teardown_fakes

setup_fakes
run_acn "/work/my dir" >/dev/null
if grep -qx 'loc=c my dir' "$T/herdr_args"; then pass "T9: <dir> のフォルダ名を送る"; else fail "T9: <dir> のフォルダ名を送らない: $(cat "$T/herdr_args" 2>&1)"; fi
teardown_fakes

setup_fakes
FAKE_PANE_ID= FAKE_FZF_KIND=container run_acn >/dev/null
if [ ! -e "$T/herdr_args" ]; then pass "T9: herdr の外では送らない"; else fail "T9: herdr の外で送った"; fi
teardown_fakes

finish
