# .config ディレクトリ単位シンボリックリンク化 実装計画

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** `~/.config` を `<repo>/.config` への単一ディレクトリリンクにし、一回限りの移行を専用スクリプトに分離する。

**Architecture:** `install.sh` は冪等な「リンク生成のみ」に限定し、既存の実 `~/.config` を repo へ取り込む一回限りの移行は新規 `migrate-config.sh` が担う。除外は `.gitignore` のブロックリストで管理。検証は偽 `HOME` と偽リポジトリを使った bash サンドボックステストで行う。

**Tech Stack:** Bash（macOS の `/bin/bash` = 3.2 互換で書く。`mapfile`/連想配列/`${var,,}` は使わない）、git（`git check-ignore`）、依存なしの自作 bash テストハーネス。

関連: issue #8 / 設計スペック `docs/superpowers/specs/2026-06-06-config-symlink-design.md`

---

## 設計上の確定事項（実装中に迷ったら参照）

- **gh の扱い**: `.config/gh/config.yml`・`hosts.yml` は現状どおり**追跡を継続**する（`hosts.yml` はトークンを含まず、ユーザー名と `git_protocol` のみ。gh はトークンを OS キーチェーンに保存）。`.gitignore` 化はしない。
- **スクリプトの環境変数オーバーライド**: `install.sh` と `migrate-config.sh` はともに `DOTFILES_DIR="${DOTFILES_DIR:-$(cd "$(dirname "$0")" && pwd)}"` とし、テストから `DOTFILES_DIR` と `HOME` を差し替えられるようにする。
- **走査粒度**: 移行はリーフ（実ファイル・シンボリックリンク）単位。`find` はデフォルトでシンボリックリンクを辿らないため、repo 内を指すリンク配下に降りていかない（プロトタイプで検証済み）。
- **非破壊**: `rm -rf` で実データを消さない。移行はまず `~/.config` 全体を `~/.config.bak.<timestamp>` に退避し、repo へは `cp -R` でコピーする（退避先に原本が残る）。

## ファイル構成

- Create: `migrate-config.sh` — 一回限りの移行スクリプト（リポジトリ直下）。
- Modify: `install.sh` — `.config` 個別リンク行（37〜46 行相当）を `~/.config` 単一リンクの冪等処理に置換。`DOTFILES_DIR` をオーバーライド可能に変更。
- Create: `test/lib.sh` — テスト共通ヘルパー（アサーション・サンドボックス構築）。
- Create: `test/test_migrate.sh` — `migrate-config.sh` のテスト。
- Create: `test/test_install.sh` — `install.sh` の `.config` 処理のテスト。
- Create: `test/run.sh` — 全テストを実行するランナー。
- Modify: `.gitignore` — ブロックリスト運用の意図をコメントで明記（既存エントリは維持）。
- Modify: `CLAUDE.md` — ディレクトリ単位リンク方針と運用ルールを反映。

---

## Task 1: テストハーネスを用意する

**Files:**
- Create: `test/lib.sh`
- Create: `test/run.sh`

- [ ] **Step 1: `test/lib.sh` を作成**

```bash
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
```

- [ ] **Step 2: `test/run.sh` を作成**

```bash
#!/bin/bash
# test/ 配下の test_*.sh を順に実行する。
HERE="$(cd "$(dirname "$0")" && pwd)"
rc=0
for t in "$HERE"/test_*.sh; do
  echo "=== $(basename "$t") ==="
  bash "$t" || rc=1
  echo
done
exit "$rc"
```

- [ ] **Step 3: 実行権限を付与**

Run: `chmod +x test/run.sh`
Expected: エラーなし。

- [ ] **Step 4: コミット**

```bash
git add test/lib.sh test/run.sh
git commit -m "test: bash テストハーネスを追加"
```

---

## Task 2: migrate-config.sh を実装する（TDD）

**Files:**
- Create: `test/test_migrate.sh`
- Create: `migrate-config.sh`

- [ ] **Step 1: 失敗するテストを書く（`test/test_migrate.sh`）**

```bash
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
```

- [ ] **Step 2: テストを実行して失敗を確認**

Run: `bash test/test_migrate.sh`
Expected: FAIL。`migrate-config.sh` が存在しないため `bash: .../migrate-config.sh: No such file or directory`、各 assert が FAIL し最後に `N FAILED`。

- [ ] **Step 3: `migrate-config.sh` を実装**

```bash
#!/bin/bash

set -e

DOTFILES_DIR="${DOTFILES_DIR:-$(cd "$(dirname "$0")" && pwd)}"
SRC="$DOTFILES_DIR/.config"
DST="$HOME/.config"

info() { echo "[INFO]  $*"; }
ok()   { echo "[OK]    $*"; }
warn() { echo "[WARN]  $*"; }

# --- 前提状態の判定 ---
if [ -L "$DST" ]; then
  if [ "$(readlink "$DST")" = "$SRC" ]; then
    ok "既に移行済みです: $DST -> $SRC"
    exit 0
  fi
  warn "$DST は別のリンクです ($(readlink "$DST"))。手動で確認してください。"
  exit 1
fi

if [ ! -e "$DST" ]; then
  info "$DST は存在しません。移行対象はありません。'./install.sh' でリンクを作成してください。"
  exit 0
fi

if [ ! -d "$DST" ]; then
  warn "$DST は実ファイルです。手動で確認してください。"
  exit 1
fi

# --- 退避してリンク作成 ---
BAK="$DST.bak.$(date +%Y%m%d%H%M%S)"
mv "$DST" "$BAK"
ok "退避しました: $DST -> $BAK"

ln -s "$SRC" "$DST"
ok "リンクを作成しました: $DST -> $SRC"

# --- 退避先のリーフを走査して repo へ取り込む ---
migrate_entry() {
  local e="$1"
  local rel="${e#"$BAK"/}"
  local repo_path="$SRC/$rel"

  # シンボリックリンク（repo 内を指すものは親リンクで吸収済み）
  if [ -L "$e" ]; then
    local target
    target="$(readlink "$e")"
    case "$target" in
      "$SRC"/*|"$SRC") info "スキップ (repo 内リンク): $rel" ;;
      *) warn "repo 外を指すリンクが残っています: $rel -> $target（退避先に保持）" ;;
    esac
    return 0
  fi

  # repo に同じパスが存在する場合
  if [ -e "$repo_path" ]; then
    if diff -r "$e" "$repo_path" >/dev/null 2>&1; then
      info "一致のためスキップ: $rel"
    else
      warn "衝突: $rel は repo 版と相違します。自動上書きしません（原本は退避先に残存）。"
      echo "----- diff (左: repo / 右: backup) -----"
      diff -u "$repo_path" "$e" || true
      echo "----------------------------------------"
    fi
    return 0
  fi

  # repo に存在しない → .gitignore 対象かで扱いを変える
  mkdir -p "$(dirname "$repo_path")"
  if git -C "$DOTFILES_DIR" check-ignore -q ".config/$rel"; then
    cp -R "$e" "$repo_path"
    ok "コピー (非追跡 / .gitignore 対象): $rel"
  else
    cp -R "$e" "$repo_path"
    warn "コピー (追跡対象 → レビューしてコミットしてください): $rel"
  fi
  return 0
}

while IFS= read -r -d '' e; do
  migrate_entry "$e" || warn "処理中にエラー: ${e#"$BAK"/}（継続します）"
done < <(find "$BAK" -mindepth 1 \( -type f -o -type l \) -print0)

# --- サマリ ---
info "移行が完了しました。"
info "退避ディレクトリ: $BAK（内容を確認後、不要なら削除してください）"
info "追跡対象に追加されたファイルは 'git status' で確認し、レビューのうえコミットしてください。"
info "衝突 (WARN) があった場合は退避先の原本を手動で反映してください。"
```

- [ ] **Step 4: 実行権限を付与**

Run: `chmod +x migrate-config.sh`
Expected: エラーなし。

- [ ] **Step 5: テストを実行して成功を確認**

Run: `bash test/test_migrate.sh`
Expected: PASS。全アサーションが PASS し最後に `ALL PASS`。

- [ ] **Step 6: コミット**

```bash
git add migrate-config.sh test/test_migrate.sh
git commit -m "feat: .config 移行スクリプト migrate-config.sh を追加"
```

---

## Task 3: install.sh の .config 処理を置換する（TDD）

**Files:**
- Create: `test/test_install.sh`
- Modify: `install.sh`（5 行目の `DOTFILES_DIR` 行、および 37〜46 行相当の `.config` 個別リンク部）

- [ ] **Step 1: 失敗するテストを書く（`test/test_install.sh`）**

```bash
#!/bin/bash
HERE="$(cd "$(dirname "$0")" && pwd)"
. "$HERE/lib.sh"
REPO="$(cd "$HERE/.." && pwd)"

echo "TEST: install.sh の .config 処理"

run_install() {
  # install.sh が参照するホーム直下 dotfiles のソースを偽リポジトリに用意（dangling 回避）
  for f in .zshrc .zimrc .fzf.zsh .zprofile .gitconfig; do touch "$DOTFILES_DIR/$f"; done
  DOTFILES_DIR="$DOTFILES_DIR" HOME="$HOME" bash "$REPO/install.sh" 2>&1
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
```

- [ ] **Step 2: テストを実行して失敗を確認**

Run: `bash test/test_install.sh`
Expected: FAIL。現行 `install.sh` は `~/.config/starship.toml` などを個別リンクするため `~/.config` 自体はリンクにならず、ケース1の `assert_symlink_to` が FAIL（最後に `N FAILED`）。

- [ ] **Step 3: `install.sh` の `DOTFILES_DIR` 行をオーバーライド可能にする**

`install.sh` の 5 行目を置換する。

変更前:
```bash
DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
```
変更後:
```bash
DOTFILES_DIR="${DOTFILES_DIR:-$(cd "$(dirname "$0")" && pwd)}"
```

- [ ] **Step 4: `.config` 個別リンク部を単一リンク処理に置換**

`install.sh` の次のブロック（「`.config` 配下（git 管理対象のもの）」のコメントから「除外: .config/1Password ...」コメントまで、現 37〜46 行相当）を削除し、置換する。

削除する範囲（変更前）:
```bash
# .config 配下（git 管理対象のもの）
link "$DOTFILES_DIR/.config/starship.toml" "$HOME/.config/starship.toml"
link "$DOTFILES_DIR/.config/ghostty"   "$HOME/.config/ghostty"
link "$DOTFILES_DIR/.config/bat"       "$HOME/.config/bat"
link "$DOTFILES_DIR/.config/nvim"      "$HOME/.config/nvim"
link "$DOTFILES_DIR/.config/karabiner" "$HOME/.config/karabiner"
link "$DOTFILES_DIR/.config/git"       "$HOME/.config/git"
link "$DOTFILES_DIR/.config/cmux"      "$HOME/.config/cmux"

# 除外: .config/1Password, .config/iterm2, .config/op は git 管理外のため手動設定
```

置換後（同じ位置に）:
```bash
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
```

- [ ] **Step 5: テストを実行して成功を確認**

Run: `bash test/test_install.sh`
Expected: PASS。全アサーションが PASS し最後に `ALL PASS`。

- [ ] **Step 6: 全テストをまとめて実行**

Run: `bash test/run.sh`
Expected: `test_install.sh` と `test_migrate.sh` がともに `ALL PASS`、終了コード 0。

- [ ] **Step 7: コミット**

```bash
git add install.sh test/test_install.sh
git commit -m "refactor: install.sh を .config ディレクトリ単位リンクに変更"
```

---

## Task 4: .gitignore と CLAUDE.md を更新する

**Files:**
- Modify: `.gitignore`
- Modify: `CLAUDE.md`

- [ ] **Step 1: `.gitignore` の先頭にブロックリスト運用の意図を明記**

`.gitignore` の先頭（`.DS_Store` の行の前）に次のコメントを追加する。既存エントリは変更しない。

```
# ~/.config はディレクトリ単位でリンクしているため、配下に現れる同期不要なもの
# （秘匿情報・キャッシュ・マシン固有の状態ファイル等）はここに都度追記する（ブロックリスト運用）。
# コミット前に必ず `git status` を確認すること。
```

- [ ] **Step 2: `CLAUDE.md` の管理方針を更新**

`CLAUDE.md` の「`.config/1Password/`、`.config/iterm2/`、`.config/op/` は `.gitignore` で git 管理外。」の一文を、次に置換する。

```markdown
`~/.config` は `.config` ディレクトリ自体を1つのシンボリックリンクとしてホームに張る（配下を丸ごと git 管理）。同期したくないもの（`.config/1Password/`、`.config/iterm2/`、`.config/op/` など）は `.gitignore` に都度追記するブロックリスト運用。コミット前に `git status` で意図しないファイルが含まれていないか確認する。
```

そのうえで「## 作業時の注意」の最初の項目を次に置換する。

変更前:
```markdown
- 設定変更は実際のホームディレクトリへのシンボリックリンク経由で反映される
```
変更後:
```markdown
- 設定変更は実際のホームディレクトリへのシンボリックリンク経由で反映される（`~/.config` はディレクトリ単位でリンク）
- 既存マシンで個別リンクから移行する場合は `./migrate-config.sh` を一度実行する（非破壊。退避ディレクトリを残す）
```

- [ ] **Step 3: コミット**

```bash
git add .gitignore CLAUDE.md
git commit -m "docs: .config ブロックリスト運用と移行手順を明記"
```

---

## Task 5: 実機での移行（手動・runbook）

> 自動テストではなく、実際のマシンで一度だけ行う手順。サンドボックステストが全て PASS したあとに実施する。

- [ ] **Step 1: 移行前の状態を記録**

Run: `ls -la ~/.config`
Expected: `gh` が実ディレクトリ、その他が repo へのシンボリックリンク。

- [ ] **Step 2: 移行スクリプトを実行**

Run: `./migrate-config.sh`
Expected: `~/.config` がリンク化され、`~/.config.bak.<timestamp>` が作成される。`gh/config.yml` は repo 版と相違するため「衝突」WARN と diff が表示される（自動上書きされない）。

- [ ] **Step 3: 結果を確認**

Run: `ls -la ~/.config && git -C "$(cd "$(dirname ./migrate-config.sh)" && pwd)" status`
Expected: `~/.config` が `<repo>/.config` へのリンク。`git status` で意図しない追跡対象が無いこと（あれば `.gitignore` に追記）。

- [ ] **Step 4: gh の衝突を手動で解消**

退避先 `~/.config.bak.<timestamp>/gh/config.yml`（ライブ版）と repo 版 `<repo>/.config/gh/config.yml` の diff を確認し、必要な差分を手動で反映する。`hosts.yml` も同様に確認。

- [ ] **Step 5: 各アプリの動作確認**

Run: 新しいシェルを開いて `exec zsh`
Expected: starship プロンプト表示・`nvim` 起動・`gh auth status` が正常。問題なければ退避ディレクトリ `~/.config.bak.<timestamp>` を削除してよい。

---

## 完了条件

- `bash test/run.sh` が `ALL PASS`（終了コード 0）。
- `install.sh` は `~/.config` を単一リンクで冪等に張り、実ディレクトリ検出時は WARN してスキップする。
- `migrate-config.sh` が既存実体を非破壊に移行し、衝突を diff 表示し、`.gitignore` 対象か否かでコピー先の追跡可否が分かれる。再実行は安全。
- 実機で `~/.config` がディレクトリリンク化され、各アプリが正常動作する。
