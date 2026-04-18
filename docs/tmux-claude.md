# tmux + Claude ベストプラクティス

tmux でウィンドウを分割し、Claude Code・ファイラー・git 情報を同時に表示する構成のまとめ。

## 推奨レイアウト

```
┌─────────────────────┬──────────────┐
│                     │   yazi       │
│   claude            │  (ファイラー) │
│                     ├──────────────┤
│                     │  git (lazygit│
│                     │  or tig)     │
└─────────────────────┴──────────────┘
```

- 左ペイン (幅 60-65%): `claude` — メインの作業スペース
- 右上ペイン: `yazi` — ファイラー。ファイル確認・移動用
- 右下ペイン: `lazygit` または `tig` — git ツリー・差分確認用

## セットアップ

### 必要ツール

```sh
brew install yazi        # ファイラー
brew install lazygit     # git TUI (推奨)
brew install tig         # git ツリービューア (軽量な代替)
brew install tmux
```

### セッション起動スクリプト

`~/.local/bin/dev` として保存して `chmod +x` する。

```sh
#!/usr/bin/env bash
# tmux dev session: claude + yazi + lazygit

SESSION="dev"
DIR="${1:-$PWD}"

# セッションが既にあれば attach
if tmux has-session -t "$SESSION" 2>/dev/null; then
  tmux attach-session -t "$SESSION"
  exit 0
fi

tmux new-session -d -s "$SESSION" -c "$DIR"

# 左ペイン: claude
tmux send-keys -t "$SESSION" "claude" Enter

# 右カラムを作成 (幅 35%)
tmux split-window -t "$SESSION" -h -p 35 -c "$DIR"

# 右上: yazi
tmux send-keys -t "$SESSION" "yazi" Enter

# 右下: lazygit
tmux split-window -t "$SESSION" -v -p 50 -c "$DIR"
tmux send-keys -t "$SESSION" "lazygit" Enter

# フォーカスを左 (claude) に戻す
tmux select-pane -t "$SESSION":0.0

tmux attach-session -t "$SESSION"
```

### tmux.conf 推奨設定

```tmux
# ペイン操作をvim風に
bind h select-pane -L
bind j select-pane -D
bind k select-pane -U
bind l select-pane -R

# ペインリサイズ
bind -r H resize-pane -L 5
bind -r J resize-pane -D 5
bind -r K resize-pane -U 5
bind -r L resize-pane -R 5

# マウス有効
set -g mouse on

# ペイン境界線を見やすく
set -g pane-border-style fg=colour238
set -g pane-active-border-style fg=colour75
```

## 運用のコツ

- **yazi ↔ claude の連携**: yazi でファイルパスをコピー (`y`) して claude に貼り付けると、ファイルの場所を素早く渡せる
- **lazygit でのコミット**: claude が変更したファイルを lazygit でレビューしてコミットする流れが自然
- **ペイン固定**: claude ペインは左に固定し、右カラムのツールは用途に応じて入れ替える (`yazi` → `nvim` など)
- **セッション名を用途で分ける**: `dev` (開発作業)、`infra` (インフラ作業) など用途別にセッションを使い分ける

## 参考

- [yazi](https://github.com/sxyazi/yazi)
- [lazygit](https://github.com/jesseduffield/lazygit)
- [tig](https://github.com/jonas/tig)
