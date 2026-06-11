# Zsh 設定

## ファイル構成

| ファイル | 役割 |
|----------|------|
| `.zshrc` | Zsh メイン設定。エイリアス、環境変数、キーバインド、関数など |
| `.zprofile` | ログインシェル向け設定。Homebrew PATH、Python PATH など |
| `.zimrc` | zimfw のモジュール定義 |
| `.fzf.zsh` | fzf の PATH 設定と shell integration の初期化 |

---

## .zshrc

### 履歴

```zsh
setopt HIST_IGNORE_ALL_DUPS   # 重複コマンドは古いものを削除
setopt IGNORE_EOF             # Ctrl+D でシェルを終了しない
```

### キーバインド

| キー | 動作 |
|------|------|
| `Ctrl+S` | `fzf-cdr`: cdr の履歴から fzf でディレクトリ選択して cd |
| `Ctrl+Q` | `ghq-fzf_change_directory`: ghq 管理リポジトリを fzf で選択して cd |
| `Escape` | `send-break` (コマンドライン入力をキャンセル) |

- キーマップは emacs モード (`bindkey -e`)
- `KEYTIMEOUT=1` でキーシーケンスの待機時間を短縮

### エイリアス

```zsh
alias vi="nvim"
alias vim="nvim"
```

### 環境変数

| 変数 | 値 |
|------|-----|
| `GOPATH` | `~/go` |
| `PYENV_ROOT` | `~/.pyenv` |
| `PATH` | `$GOPATH/bin`, `$PYENV_ROOT/bin` を追加 |

### fzf オプション

```zsh
FZF_DEFAULT_OPTS='--no-height --reverse'
FZF_CTRL_R_OPTS='--preview "echo {}"'
```

### cdr (ディレクトリ履歴)

```zsh
zstyle ':chpwd:*' recent-dirs-max 500
zstyle ':chpwd:*' recent-dirs-file "$HOME/.cache/shell/chpwd-recent-dirs"
```

最大 500 件のディレクトリ履歴を `~/.cache/shell/chpwd-recent-dirs` に保存。

### cdpath

```zsh
cdpath=(~ ..)
```

`cd` 時に `~` と親ディレクトリも自動的に検索対象に含める。

### zimfw 初期化

Homebrew 経由でインストールした zimfw を使用 (`/opt/homebrew/opt/zimfw`)。
`.zimrc` が更新されている場合は自動的に `init.zsh` を再生成する。

### Starship

```zsh
export STARSHIP_CONFIG="$HOME/.config/starship.toml"
eval "$(starship init zsh)"
```

プロンプトは [Starship](https://starship.rs/) で描画する。設定ファイルは `.config/starship.toml`（[tools.md](tools.md#starship) 参照）。

---

## .zimrc

zimfw のモジュール設定。

### 読み込みモジュール

| モジュール | 役割 |
|-----------|------|
| `environment` | Zsh 組み込みオプションの適切なデフォルト設定 |
| `input` | 入力イベントに対する適切なキーバインド設定 |
| `utility` | ls・grep・less のカラー化などユーティリティエイリアス |
| `zsh-users/zsh-completions` | 追加の補完定義 |
| `completion` | スマートなタブ補完 (補完定義を追加するモジュールより後に読み込む必要あり) |
| `zsh-users/zsh-syntax-highlighting` | Fish 風のシンタックスハイライト |
| `zsh-users/zsh-autosuggestions` | Fish 風のオートサジェスト |
| `fzf` | fzf との統合 |
| `prompt-pwd` | プロンプト用のパス短縮表示 |

---

## .fzf.zsh

```zsh
PATH="${PATH:+${PATH}:}/opt/homebrew/opt/fzf/bin"
source <(fzf --zsh)
```

Homebrew でインストールした fzf を PATH に追加し、`fzf --zsh` で Ctrl+T / Ctrl+R / Alt+C などの shell integration を有効化する。
