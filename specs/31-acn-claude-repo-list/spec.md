# Spec: acn-claude で、コンテナの ghq・ワークスペース・ホストにだけあるリポジトリを選べるようにする

- Tier: 1
- Status: draft
- Feature slug: 31-acn-claude-repo-list
- Issue: https://github.com/toshikimiyagawa/dotfiles/issues/31

## 背景 / 意図
herdr の `Option+b` は `.config/herdr/bin/acn-claude` を新しいペインで実行する。今の動き:
- コンテナで fzf を動かし、コンテナの ghq のリポジトリだけを選ばせる。
- ghq が空なら、ホームで起動する（#29）。

これを次のように変える。
- 一覧に、コンテナのワークスペース（`/workspaces/acn-devcontainer`）と、ホストにだけあるリポジトリも出す。
- ホストにだけあるリポジトリを選んだら、コンテナで `ghq get` してから Claude を起動する。

コンテナには個人用の鍵も渡すようになった（toshikimiyagawa/acn-devcontainer#89）。そのため、個人の非公開リポジトリも取ってこられる。

## 決まり
- **一覧はホストで作り、fzf もホストで動かす。**
  - コンテナの ghq の一覧は、ssh を 1 回実行して取る（`ssh <host> ghq list`。端末は割り当てない）。
  - ホストの一覧はホストの `ghq list` で取る。
  - どちらも ghq root からの相対パス（例: `github.com/daisojapan/plansys-data`）で比べる。
- **一覧の各行**は「種類」と「対象」を空白で区切る。並びは次の順:
  1. `container  <相対パス>`: コンテナの ghq にあるもの。
  2. `workspace  /workspaces/acn-devcontainer`: 常に 1 行。パスは環境変数 `ACN_WORKSPACE_DIR` で変えられる。
  3. `get        <相対パス>`: ホストの ghq にあって、コンテナの ghq に無いもの。ただし、最後の要素が `acn-devcontainer` のものは除く（ワークスペースとして出しているため）。
- **選んだあとの動き**: 最後に `HERDR_AGENT=claude` を付けて、Homebrew の ssh で `ssh -t <host> <リモートのコマンド>` を exec する（今と同じ）。リモートのコマンドは種類ごとに次のとおり。
  - `container`: `cd "$(ghq root)/<相対パス>" && exec claude`
  - `workspace`: `cd <パス> && exec claude`
  - `get`: `ghq get <URL> && cd "$(ghq root)/<相対パス>" && exec claude`。
    - URL は、ホストのリポジトリの `remote.origin.url`（`git config --get`。insteadOf での書き換えはしない）。取れなければ相対パスをそのまま渡す。
    - `ghq get` に失敗したら、エラーと「Enter で閉じる」を表示して入力を待つ。ペインがすぐに閉じないようにするため。
  - 引数や相対パスは、リモートのシェルに渡すためにシングルクォートで囲む（今の `quote` を使う）。
- **fzf で何も選ばなかったら**（Esc など）、何もせずに終了する（ペインは閉じる）。
- **コンテナの一覧を取る ssh が失敗したら**（コンテナが止まっているなど）、エラーと「Enter で閉じる」を表示して入力を待ち、終了する。
- **#29 の「ghq が空ならホームで起動」はやめる。** 一覧には常にワークスペースが出るので、何も選べないことは無くなるため。
- **`acn-claude <dir>` は今のまま**（`cd <dir> && exec claude`）。
- **テストのために、外部コマンドを環境変数で差し替えられるようにする。**
  - `ACN_SSH_BIN`（今もある）、`ACN_FZF`（既定 `fzf`）、`ACN_GHQ`（既定 `ghq`。ホストの ghq）。
- **ヘッダのコメント**（使い方）を新しい動きに合わせて直す。

テスト（`test/test_acn_claude.sh`。`test/run.sh` が実行し、CI の Tests でも走る）:
- 偽の ssh・fzf・ghq を一時ディレクトリに作り、環境変数で差し替えて `acn-claude` を実行する。
  - 偽の ssh: 引数と `HERDR_AGENT` を記録する。`-t` が無い呼び出し（一覧の取得）には、決めておいたコンテナの一覧を返す。
  - 偽の fzf: 入力を記録し、環境変数で指定した種類の行を選んで出力する。
  - 偽の ghq: ホストの一覧と、ghq root（一時ディレクトリ）を返す。ホストのリポジトリは一時ディレクトリに `git init` し、`remote.origin.url` を設定しておく。
- 調べること:
  - T1: fzf に渡された一覧に `container` 行・`workspace` 行・`get` 行がこの順で出る。コンテナにもあるものは `get` に出ない。`acn-devcontainer` は `get` に出ない。
  - T2: `container` 行を選ぶと、最後の ssh が `-t` 付きで、`HERDR_AGENT=claude` が付き、リモートのコマンドが `cd` してから `exec claude` する。
  - T3: `workspace` 行を選ぶと、リモートのコマンドが `/workspaces/acn-devcontainer` に `cd` する。
  - T4: `get` 行を選ぶと、リモートのコマンドが、ホストの `remote.origin.url` で `ghq get` してから、そのディレクトリで `exec claude` する。失敗時に入力を待つ処理を含む。
  - T5: fzf が何も返さなければ、`-t` 付きの ssh は実行されない。
  - T6: 一覧の取得の ssh が失敗したら、`-t` 付きの ssh は実行されず、0 以外で終わる。テストでは標準入力を空にして、入力待ちがすぐ終わるようにする。
  - T7: `acn-claude <dir>` は、一覧を取らずに、`<dir>` に `cd` して `exec claude` する。

## 受入条件
- [ ] SAC-1: 一覧に、コンテナの ghq・ワークスペース・ホストにだけあるリポジトリ（acn-devcontainer を除く）が、種類が分かる形で出る。（T1）（元 Issue: 31-AC1）
- [ ] SAC-2: コンテナの ghq・ワークスペースを選ぶと、そのディレクトリで Claude が起動する。（T2・T3。手動: herdr の `Option+b` で起動し、`herdr agent explain` が `claude`）（元 Issue: 31-AC2）
- [ ] SAC-3: ホストにだけあるリポジトリを選ぶと、コンテナで `ghq get` してから、そのディレクトリで Claude が起動する。（T4。手動: 実際に 1 つ取ってきて起動する）（元 Issue: 31-AC3）
- [ ] SAC-4: `ghq get` に失敗したら、エラーを表示し、ペインを閉じずに入力を待つ。（T4）（元 Issue: 31-AC4）
- [ ] SAC-5: `acn-claude <dir>` は今までどおり。（T7）（元 Issue: 31-AC5）
- [ ] SAC-6: 何も選ばなかったときと、コンテナに繋がらないときは、Claude を起動しない。（T5・T6）
- [ ] SAC-7: `bash test/run.sh` が通る（CI の Tests）。

## スコープ外
- コンテナの ghq にあってホストに無いリポジトリを、ホストに取ってくること。
- `ghq get` の認証の設定（acn-devcontainer#89 で済んでいる）。
- herdr のキーの設定（`config.toml`）の変更。

## 制約 / 前提
- `acn-claude` は `/bin/sh`（macOS では bash 3.2 の sh モード）で動くこと。
- コンテナの ghq root は `~/ghq`。ただし、リモートでは `$(ghq root)` で求める。
- herdr の判定のため、最後の ssh は Homebrew の ssh を使い、`HERDR_AGENT=claude` を付ける（#27 と同じ）。一覧の取得の ssh には付けない（ペインで動くのは一瞬なので、どちらでもよいが、付けない）。
- `.sdd/catalog.json` は無い。この変更には、画面・API・テーブルなどカタログに載せるものが無い。
