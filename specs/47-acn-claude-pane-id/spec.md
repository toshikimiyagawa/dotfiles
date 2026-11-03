# Spec: acn-claude で起動したコンテナの claude に CLAUDE_MOBILE_PANE_ID を渡す

- Tier: 1
- Status: frozen
- Feature slug: 47-acn-claude-pane-id
- Issue: https://github.com/toshikimiyagawa/dotfiles/issues/47

## 背景 / 意図
ホストの claude-mobile（toshikimiyagawa/claude-mobile#6・PR #16）は、コンテナの claude のプロセスの環境変数 `CLAUDE_MOBILE_PANE_ID`（無ければ `HERDR_PANE_ID`）から herdr のペイン ID を読み、ペインとセッション（会話の記録）を対応付ける。
いまの `acn-claude` はこの変数を付けないので、対応付けは「ペインのメタデータの `dir` と、プロセスの cwd のフォルダ名が 1 対 1 のとき」に限られる。同じフォルダで devcontainer の Claude を 2 つ以上動かすと、どちらも対応付かず、会話が表示されない。
コンテナの sshd は `AcceptEnv LANG LC_* COLORTERM` だけなので、`SendEnv` ではなく、ssh のリモートのコマンドで変数を付ける（claude-mobile が自分で起動するときの `cd <dir> && exec env CLAUDE_MOBILE_PANE_ID=<pane> claude` に合わせる）。sshd は変えない。

## 決まり
対象は `.config/herdr/bin/acn-claude` の、リモートのコマンドの `exec claude` の全か所。
- 引数でディレクトリを渡したとき（`acn-claude <dir>`）
- 一覧で選んだ `container` 行
- 一覧で選んだ `workspace` 行
- 一覧で選んだ `get` 行（`ghq get` のあとの起動）

内容:
- `HERDR_PANE_ID` が空でないとき、`exec claude` を `exec env CLAUDE_MOBILE_PANE_ID=<ペイン ID> claude` にする。
  - `<ペイン ID>` は `$HERDR_PANE_ID` の値。リモートのシェルに渡すので、既存の `quote` で囲む（例: `exec env CLAUDE_MOBILE_PANE_ID='w9:p9' claude`）。
- `HERDR_PANE_ID` が空、または未設定のとき（herdr の外）は付けない。リモートのコマンドは今と同じ（`exec claude`）。
- 4 か所とも同じ組み立てを使う（1 か所で作って使い回す）。
- 変えないもの: `cd` の部分、`ghq get` の部分と失敗時の処理、`ssh` の引数（`-t -o SendEnv=COLORTERM <host>`）、`HERDR_AGENT=claude`、herdr への metadata の送信。

## テスト
`test/test_acn_claude.sh`（偽の ssh・fzf・ghq・herdr を使う既存の仕組み。`HERDR_PANE_ID` は `run_acn` が `FAKE_PANE_ID`（既定 `w9:p9`）から渡す）に足す。既存の T2・T3・T4・T7・T8 の「リモートのコマンドの期待値」は、herdr のペイン内（`HERDR_PANE_ID=w9:p9`）で動かしているため、`exec env CLAUDE_MOBILE_PANE_ID='w9:p9' claude` に更新する。
- P1: container 行を選ぶと、リモートのコマンドが `cd "$(ghq root)"/'github.com/a/both' && exec env CLAUDE_MOBILE_PANE_ID='w9:p9' claude` になる。
- P2: workspace 行を選ぶと、`cd '/workspaces/acn-devcontainer' && exec env CLAUDE_MOBILE_PANE_ID='w9:p9' claude` になる。
- P3: get 行を選ぶと、リモートのコマンドが `... && cd "$(ghq root)"/'github.com/a/hostonly' && exec env CLAUDE_MOBILE_PANE_ID='w9:p9' claude` で終わる。
- P4: `acn-claude <dir>` で、`cd '/work/my dir' && exec env CLAUDE_MOBILE_PANE_ID='w9:p9' claude` になる。
- P5: herdr の外（`FAKE_PANE_ID` が空）では、4 か所すべてで、リモートのコマンドに `CLAUDE_MOBILE_PANE_ID` も `env` も含まれず、`exec claude` のまま。
- P6: 変数が実際にリモートのシェルで claude のプロセスの環境に入る。偽の claude（`env` の値を記録するもの）に対し、P4 のリモートのコマンドを `sh -c` で実行すると、`CLAUDE_MOBILE_PANE_ID=w9:p9` が見える。ペイン ID に空白や `'` を含む値（例: `w1:p 2'x`）でも、同じ値のまま渡る。

## 受入条件
- [ ] SAC-1: herdr のペイン内で `acn-claude` を実行すると、リモートのコマンドが `exec env CLAUDE_MOBILE_PANE_ID=<そのペインの ID を quote したもの> claude` になり、コンテナの claude のプロセスの環境変数 `CLAUDE_MOBILE_PANE_ID` がそのペインの ID になる。4 か所すべてで。（P1〜P4・P6）
  - 元 Issue: 1 つ目の AC。
- [ ] SAC-2: herdr の外で実行したときは付かない（今と同じ）。（P5）
  - 元 Issue: 2 つ目の AC。
- [ ] SAC-3: 同じフォルダで 2 つ起動しても、ホストの claude-mobile の一覧で、それぞれのペインに正しい会話が表示される。
  - このリポジトリのテストでは確かめられない（claude-mobile 側の動作）。手動で確かめる。この spec の範囲で自動テストできるのは、SAC-1 で各ペインの claude に別々のペイン ID が渡ること（P1〜P4・P6）まで。
  - 元 Issue: 3 つ目の AC。
- [ ] SAC-4: `bash test/run.sh` が通る。`sh -n` と `dash -n`（あれば）が `acn-claude` に通る。

## スコープ外
- コンテナの sshd の設定（`AcceptEnv`）の変更。
- claude-mobile 側の変更。
- `acn-claude` の起動の流れ・一覧・metadata の送信の変更。
- `HERDR_PANE_ID` 以外の値を `CLAUDE_MOBILE_PANE_ID` に使うこと。

## 制約 / 前提
- `acn-claude` は `/bin/sh` で動く。macOS は bash 3.2 の sh モード、CI（ubuntu）は dash。POSIX の範囲で書く。
- テストは macOS と ubuntu CI で動く。bash 3.2 互換。本物の ssh・fzf・ghq・コンテナには依存しない。
- リモートのシェルでの `env` の使用は、claude-mobile が自分で起動するときと同じ形。
