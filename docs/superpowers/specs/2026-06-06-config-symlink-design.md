# .config ディレクトリ単位シンボリックリンク化 設計

関連 issue: #8

## 背景 / 目的

現在 `~/.config` 配下は個別ファイル／サブディレクトリ単位でシンボリックリンクを張っており、リンク粒度が混在している（`bat`/`ghostty`/`nvim` 等はディレクトリ単位、`starship.toml` はファイル単位）。また repo に `.config/gh` があるのに `install.sh` のリンク対象から漏れているなど、設定追加のたびに `install.sh` を追記する必要があり追従漏れが起きやすい。

`~/.config` 配下を（アプリが書き込む内容も含めて）**丸ごとリポジトリ管理下に置きたい**。そのために `~/.config` 自体を1つのシンボリックリンクにし、同期したくないものは都度 `.gitignore` に追記するブロックリスト運用へ移行する。

## 採用アプローチ

- **アーキテクチャ**: `~/.config` → `<repo>/.config` の単一ディレクトリリンク。
- **除外管理**: ブロックリスト方式の `.gitignore`（既定で全追跡、同期不要なものを都度追記）。
  - アローリスト方式（`*` 無視 + `!` 許可）は安全だが「install.sh を編集せず新規設定が自動同期される」という目的に反するため不採用。
- **スクリプト分離**: 一回限りの移行（既存の実 `~/.config` を repo へ取り込む処理）は専用の `migrate-config.sh` に分離する。`install.sh` は「クリーンなリンク生成」だけを行う冪等な処理に保ち、常駐の設定処理に一回限りの移行ロジックを混ぜない（関心の分離）。

### トレードオフ（既知のリスクと緩和）

`~/.config` 全体が repo 配下になるため、今後あらゆるアプリが書き込む新規ファイルが `git status` に現れ、`git add -A` で秘匿情報・ノイズを誤コミットするリスクがある。緩和策:
- 既知の秘匿・状態・キャッシュ系を先回りで `.gitignore` に入れておく。
- コミット前に必ず `git status` を確認する運用を明文化。

## ターゲット状態

- `~/.config` は `<repo>/.config` を指すシンボリックリンク。
- 現在の個別リンク（`bat`/`cmux`/`ghostty`/`git`/`karabiner`/`nvim` と `starship.toml`）は廃止し、親リンクに吸収。
- repo に存在する `gh` も親リンク経由で自動的に有効化される（現状の取りこぼし解消）。
- `install.sh` の `.config` 個別リンク行（現 38〜46 行相当）を、`~/.config` 単一リンクの冪等処理に置換。
- 新規ファイル `migrate-config.sh`（リポジトリ直下）を追加し、一回限りの移行を担う。

## install.sh の挙動（冪等・リンク生成のみ）

`install.sh` は移行を行わない。`~/.config`（= `$HOME/.config`、以下 TARGET）を次のケースで分岐処理する。

1. **TARGET が存在しない** → `ln -s <repo>/.config TARGET`。
2. **TARGET が正しいリンク済み**（`<repo>/.config` を指す）→ 何もしない（冪等）。
3. **TARGET が別の場所へのリンク** → 削除して張り直し。
4. **TARGET が実ディレクトリ**（移行前の状態）→ **移行は行わず**、`migrate-config.sh` の実行を促す WARN を出して `.config` のリンク処理だけスキップする（破壊的操作なし・非 fatal。他の dotfiles リンクは継続）。

ホーム直下の dotfiles リンク（`.zshrc` 等）と cdr キャッシュ生成は現状維持。リンク生成の小ロジックは `migrate-config.sh` と共有できるよう関数化してもよい（実装判断）。

## migrate-config.sh の挙動（一回限り・冪等再実行可）

既存の実 `~/.config` を repo 配下へ取り込み、ディレクトリリンクへ移行する一回限りのスクリプト。安全に再実行できる。

1. **前提状態の判定**:
   - TARGET が既に正しいリンク → 移行不要。何もせず終了（冪等）。
   - TARGET が存在しない → 移行対象なし。`install.sh` の実行を案内して終了。
   - TARGET が実ディレクトリ → 以下の移行を実行。
2. `TARGET` を `TARGET.bak.<timestamp>`（例: `~/.config.bak.20260606123000`）へ丸ごと退避（無損失）。
3. `ln -s <repo>/.config TARGET`（リンク作成）。
4. 退避先 `TARGET.bak.<timestamp>` を走査し、各エントリ `e` を処理:
   - **`e` が repo 内（`<repo>/.config/*`）を指す symlink** → 無視（親リンクで吸収済み）。
   - **`e` が repo 外を指す symlink** → 警告して退避先に残す（手動判断）。
   - **`e` が実ファイル/ディレクトリ**: 相対パス `rel`、`repo_path = <repo>/.config/$rel` として:
     - `repo_path` あり & 内容一致（`diff -r` で差分なし）→ 何もしない。
     - `repo_path` あり & 内容相違 → **`diff` を表示し自動上書きしない**。原本は退避先に残るので手動反映を促す。
     - `repo_path` なし:
       - `git -C <repo> check-ignore -q ".config/$rel"` が真（`.gitignore` 対象）→ `repo_path` へコピー（追跡されない実体として配置。アプリは動作するがコミットされない）。
       - 偽（非対象）→ `repo_path` へコピー（追跡対象になる → レビュー&コミットを促す警告）。
5. 退避先 `.bak` はユーザー確認用に残す（自動削除しない）。
6. 最後に処理サマリを出力（コピーした項目／要手動反映の衝突／レビュー&コミット推奨の追跡対象）。

## .gitignore（ブロックリスト運用）

- 既存エントリは維持: `.DS_Store`, `.config/1Password/`, `.config/iterm2/`, `.config/op/`, `.config/karabiner/assets/`, `.config/karabiner/automatic_backups/`, `.config/nvim/doc/tags`。
- 現状 `~/.config` の実体は `gh` のみでアプリ由来のノイズは少ないため、初期追加は最小限とする。実装時に現状の `~/.config` を確認し、必要なら既知の秘匿/状態/キャッシュ系（`*.log`、各アプリの `cache/`・`state/` 等）を追加する。
- `gh/hosts.yml` はトークンを含まない（ユーザー名と `git_protocol` のみ。gh はトークンを OS キーチェーンに保存）。「マシン固有のアカウント情報」を repo に追跡し続けるか `.gitignore` 化するかは実装時に判断する（現状は追跡中）。
- **運用ルール**（README または CLAUDE.md に明記）:
  - 新規アプリのファイルが `git status` に現れたら、同期不要なら `.gitignore` に追記する。
  - コミット前に必ず `git status` を確認し、意図しないファイルが含まれていないか点検する。

## エラー処理・冪等性

- `migrate-config.sh` の走査ループは **per-entry でエラーを握り**、1件の衝突や失敗で全体停止しない（`set -e` 下でも該当処理を局所的に握って継続）。
- **破壊的操作を行わない**: `rm -rf` で実データを消さない。必ず `.bak` 退避。衝突時も上書きしない。
- **冪等性**: `install.sh` は正リンク済みなら no-op。`migrate-config.sh` は移行済み（正リンク状態）なら何もせず終了。退避 `.bak` はタイムスタンプ付与で二重作成・衝突を回避。

## テスト / 検証

- **migrate-config.sh のサンドボックステスト**: 偽の `HOME` を用意し、mock の `~/.config` に以下を作って `HOME=<tmp> ./migrate-config.sh` を実行、期待結果を assert する。
  - repo 内を指す symlink（→ 無視され消える）
  - repo に同パスが無い実ファイルで `.gitignore` 非対象（→ repo にコピーされ追跡対象）
  - repo に同パスが無い実ファイルで `.gitignore` 対象（→ repo にコピーされるが非追跡）
  - repo に同パスがあり内容相違の実ファイル（→ diff 表示・上書きされず・原本は `.bak` に残る）
  - 検証項目: `~/.config` がリンク化される / 各コピー先 / `.bak` 退避 / 冪等再実行（再実行で何もしない）。
- **install.sh のサンドボックステスト**: 偽の `HOME` で各ケース（TARGET 無し→リンク / 正リンク→no-op / 別リンク→張り直し / 実ディレクトリ→WARN してスキップ）を assert する。
- **実機検証**: `.bak` 退避があるため安全。`migrate-config.sh` 実行後に `ls -la ~/.config`、`git status`、各アプリ（starship/nvim/gh）の動作を確認する。

## スコープ外

- ホーム直下の dotfiles（`.zshrc` 等）のリンク方式変更。
- `.config` 以外のディレクトリの管理方式変更。
- 既存の追跡済みファイルの内容変更（移行は配置とリンクのみを対象とする）。
