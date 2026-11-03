# Spec: ^q（ghq を fzf で選ぶ）のプレビューを直し、下に出す

- Tier: 1
- Status: frozen
- Feature slug: 49-ghq-preview-down
- Issue: https://github.com/toshikimiyagawa/dotfiles/issues/49

## 背景 / 意図
`.zshrc` の `ghq-fzf_change_directory`（`^q`）は、ghq のリポジトリを fzf で選び、右にディレクトリの中身をプレビューする。
今の eza（v0.23）は `--icons` が値（`always`/`auto`/`never`）を取るので、`eza -l -g -a --icons <パス>` がパスを `--icons` の値として読み、プレビューがエラー（`invalid value ... for '--icons [<WHEN>]'`）になる。利用者はプレビューを右ではなく下に出したい。
acn-devcontainer（solvelio/acn-devcontainer#19・`specs/19-ghq-preview-down`）が同じ直しを済ませているので、同じ形を入れる。

```zsh
src=$(ghq list | fzf --preview-window "down,$(( (LINES * 7 / 10 < LINES - 12 ? LINES * 7 / 10 : LINES - 12) - 2 ))" --preview "eza -a --icons=always --oneline $(ghq root)/{}")
```

## 決まり
- `.zshrc` の `ghq-fzf_change_directory` の `fzf` の呼び出しを、上の形にする（`local src=$(...)` の `local` は今のまま残す）。
- 直前のコメントの「右にリポジトリのディレクトリ詳細を表示」を「下に」に直す。
- 変えないもの: `^q` の割り当て、`cd` する処理、`fzf-cdr`（`^s`）、`FZF_*_OPTS` など `ghq-fzf_change_directory` 以外の fzf の設定。

## テスト
新しいテスト `test/test_zshrc_ghq_fzf.sh`（`test/run.sh` が実行する）。`.zshrc` から `ghq-fzf_change_directory` の関数の定義だけを取り出して zsh で読み込み（`~/.zshrc` ではなく、リポジトリのファイルを見る）、偽の `fzf`・`ghq`・`eza` を PATH の先頭に置いて呼ぶ。偽の `fzf` は受け取った引数を記録する。zsh が無い環境では、その旨を表示して、何もせずに通す。
- Z1: 偽の fzf が受け取った `--preview-window` の値が `down` で始まる。
- Z2: 偽の fzf が受け取った `--preview` のコマンドを、本物の eza で、ghq のリポジトリに見立てた一時ディレクトリ（中にファイルが 2 つ以上）に対して `sh -c` で実行すると、終了コード 0・標準エラーが空で、そのファイル名が出力に含まれる。本物の eza が無い環境では、この項目を飛ばす（その旨を表示する）。
- Z3: `LINES=50` のとき `--preview-window` は `down,33`、`LINES=30` のとき `down,16` になる。
- Z4: Z3 の高さを N とすると、`LINES - N - 2`（fzf のプロンプトと情報の行を除いた、リストの行数）が、どちらの `LINES` でも 10 以上で、`LINES=50` のときの N は `LINES=30` のときより大きい。

## 受入条件
- [ ] SAC-1: `ghq-fzf_change_directory` が fzf に渡すプレビューのコマンドを、ghq のリポジトリ 1 つに対して実行すると、終了コード 0・標準エラーが空で、そのリポジトリの中身（1 件以上）を表示する。（Z2）
- [ ] SAC-2: `ghq-fzf_change_directory` が fzf に渡す `--preview-window` は下（`down`）を指す。（Z1）
- [ ] SAC-3: 端末の高さ（`LINES`）が 50 行のときと 30 行のときで、プレビューの高さは式どおり（33 と 16）になり、リストに 10 行以上の候補が残り、50 行のときのプレビューは 30 行のときより大きい。（Z3・Z4）
  - 手動: 実際の端末で `^q` を押し、プレビューが下に出て、エラーが出ず、リストが見えることを確かめる（fzf の描画そのものは自動テストしない）。
- [ ] SAC-4: `bash test/run.sh` が通る。`zsh -n .zshrc` が通る。

## スコープ外
- `^q` 以外の fzf の設定（`^s` の `fzf-cdr`・`FZF_*_OPTS` など）。
- fzf を実際に描画して確かめるテスト（acn-devcontainer は tmux で描画しているが、ここでは引数の確認までにする）。
- GitHub Actions でこのテストを流すこと（CI は今までどおり）。

## 制約 / 前提
- 変更するのは `.zshrc` の `ghq-fzf_change_directory`（直前のコメントも）と、新しいテスト `test/test_zshrc_ghq_fzf.sh`。
- `.zshrc` は組織の設定でエージェントが編集できないことがある（過去の spec 43 の記述）。編集できなかったときは、実装を止めて、利用者に変更内容を渡す。
- テストは macOS で動く。bash 3.2 互換。本物の ghq・fzf・コンテナには依存しない（Z2 の eza だけは本物を使い、無ければ飛ばす）。
- fzf の既定の設定（`FZF_DEFAULT_OPTS`）はそのまま。
