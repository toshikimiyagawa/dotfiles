# Spec: 入力待ちでも裏でシェルやサブエージェントが動いている Claude を、herdr のエージェント一覧で見分けられるようにする

- Tier: 1
- Status: draft
- Feature slug: 43-herdr-bg-indicator
- Issue: https://github.com/toshikimiyagawa/dotfiles/issues/43

## 背景 / 意図
Claude Code が裏でシェル（run_in_background）やサブエージェントを動かしているときも、入力欄は空くので、herdr の状態は idle や done になる。そのため一覧では、裏で処理が動いているのか、本当に何もしていないのかが分からない。
herdr の状態の印は 5 種類に決まっていて、増やせない。代わりに、状態の印のすぐ右に `⧗` を出す。

判定の手がかり（手で確かめた。Claude Code 2.1.316）:
- 裏に処理があるとき、画面の下のモード表示の行の末尾に `↓ to manage` が付く。
  - シェルのとき: `⏵⏵ auto mode on · 1 shell · ↓ to manage`
  - サブエージェントのとき: `⏵⏵ auto mode on (shift+tab to cycle) · esc to interrupt · ↓ to manage`。その下に、タスクの一覧（`⏺ main`、`◯ general-purpose …`）が出る。
- 裏に何も無いとき: `⏵⏵ auto mode on (shift+tab to cycle)`。`↓ to manage` は無い。

## 決まり
- **監視スクリプト** `.config/herdr/bin/herdr-bg-watch`（新規、実行可能、`#!/bin/sh`、POSIX）
  - 一定の間隔（既定 3 秒。環境変数 `HERDR_BG_WATCH_INTERVAL`）で、次を繰り返す。
    1. `herdr pane list` で、`agent` が `claude` のペインを列挙する（JSON は `jq` で読む）。
    2. それぞれのペインの画面の下のほう（`herdr agent read <pane> --source visible --lines 12`）に `↓ to manage` があるかを調べる。
    3. あるペインには、`herdr pane report-metadata <pane> --source herdr-bg-watch --token bg=⧗ --ttl-ms 10000` を送る。あるあいだは毎回送り直して、TTL を延ばす。
    4. 前の回で印を送ったが、今回は無いペインには、`--clear-token bg` を送る。
  - **終わる条件**: `herdr pane list` が 3 回続けて失敗したら（herdr のサーバーが無い）、終わる。
  - **1 つだけ動かす**: ロック用のディレクトリ（`${TMPDIR:-/tmp}/herdr-bg-watch.$(id -u).lock`。中に pid のファイル）を `mkdir` で作る。
    - 作れて、中の pid のプロセスが生きているなら、何もせずに 0 で終わる。
    - 生きていなければ（古いロック）、取り直す。
    - 終わるときにロックを消す（`trap`）。
  - `herdr` と `jq` のコマンドは、環境変数 `HERDR_BG_WATCH_HERDR`・`HERDR_BG_WATCH_JQ` で変えられる（テスト用）。
  - `HERDR_BG_WATCH_ONCE=1` のときは、1 回だけ回して終わる（テスト用）。
  - 監視の 1 回で失敗したペイン（読めないなど）は飛ばして、続ける。
- **`.zshrc`**: herdr のペインの中（`HERDR_PANE_ID` があり、herdr のコマンドがある）では、監視スクリプトを裏で起動する。
  - 形: `nohup ~/.config/herdr/bin/herdr-bg-watch >/dev/null 2>&1 &!`
  - 二重起動は、スクリプトのロックが防ぐ。
  - 置く場所は、既存の `_herdr_report_dir` のブロックの中。
- **`config.toml`**: エージェント一覧の 1 行目を `["state_icon", "$bg", <$loc の項目>]` にする。
  - herdr は項目の間に ` · ` を入れるので、`◐ ⧗ · h plansys-data` のように見える。`$bg` が無いときは、`◐ h plansys-data` になる（今と同じ）。
  - コメントで、`$bg` を送るのが `bin/herdr-bg-watch` であることを書く。
- **テスト** `test/test_herdr_bg_watch.sh`（新規。`test/run.sh` が実行する。CI でも走る）。偽の herdr と jq を使う（jq は本物でもよい。CI の ubuntu にはある）。
  - B1: claude のペインが 2 つあり、片方の画面の下に `↓ to manage` があるとき、1 回回すと、そのペインにだけ `--token bg=⧗` と `--ttl-ms 10000` と `--source herdr-bg-watch` で送る。
  - B2: claude ではないペイン（`agent` が無い、または別の値）は読まない。
  - B3: 印を送ったペインが、次の回で `↓ to manage` を出さなくなったら、`--clear-token bg` を送る。一度も送っていないペインには送らない。
  - B4: `herdr pane list` が 3 回続けて失敗すると、終わる（0 で終わる。待ち時間は `HERDR_BG_WATCH_INTERVAL=0` にする）。
  - B5: ロックを持つプロセスが生きているとき、2 つ目は何もせずにすぐ終わる（herdr を呼ばない）。
  - B6: 古いロック（pid のプロセスが無い）は取り直して、動く。
  - B7: 終わったあと、ロックのディレクトリが残らない。

## 受入条件
- [ ] SAC-1: 裏に処理がある Claude のペインにだけ、`$bg` に `⧗` が送られる。（B1・B2）
  - 手動: 裏で `sleep` を動かした Claude のペインで、一覧に `⧗` が出る。（元 Issue: 43-AC1）
- [ ] SAC-2: 裏の処理が終わると印が消える。監視が止まっても、TTL で古い印は残らない。（B3。TTL は `--ttl-ms 10000` を B1 で確かめる）
  - 手動: `sleep` が終わると、数秒で `⧗` が消える。（元 Issue: 43-AC2）
- [ ] SAC-3: 監視は 1 つだけ動き、herdr のサーバーが無くなれば終わる。（B4〜B7）
  - 手動: herdr のペインでシェルを何度開いても、`herdr-bg-watch` のプロセスは 1 つ。（元 Issue: 43-AC3）
- [ ] SAC-4: `bash test/run.sh` が通る。`herdr config check` が通る。

## スコープ外
- herdr の状態（idle・done など）そのものを変えること。
- Claude 以外のエージェント。
- 裏の処理の数や種類（シェルかサブエージェントか）を出すこと。
- launchd などで、herdr の外から常駐させること。

## 制約 / 前提
- Claude Code の画面の文言（`↓ to manage`）に頼る。Claude Code の更新で文言が変わったら、印が出なくなる（壊れはしない）。
- macOS の `/bin/sh` と ubuntu（CI）の dash で動くこと。
- herdr の metadata の TTL は 1〜86400000 ミリ秒。
