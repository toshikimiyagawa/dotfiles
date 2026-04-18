# ツール設定

---

## Ghostty

設定ファイル: `.config/ghostty/config`

```
font-family = Menlo
font-family = FiraCode Nerd Font
font-size = 14
shell-integration-features = ssh-terminfo,ssh-env
```

| 設定 | 値 | 説明 |
|------|-----|------|
| `font-family` | Menlo, FiraCode Nerd Font | フォントをこの順で試す。Nerd Font はアイコン表示に使用 |
| `font-size` | 14 | フォントサイズ |
| `shell-integration-features` | `ssh-terminfo,ssh-env` | SSH 接続時に terminfo と環境変数を転送し、リモートでも正しく表示 |

---

## bat

設定ファイル: `.config/bat/config`

`cat` の代替ツール。シンタックスハイライト付きでファイルを表示する。

```
--theme="Coldark-Cold"
```

| 設定 | 値 | 説明 |
|------|-----|------|
| `--theme` | `Coldark-Cold` | ライト系のシンタックスハイライトテーマ |

利用可能テーマの確認: `bat --list-themes`

---

## Neovim

設定ファイル: `.config/nvim/`

```
nvim/
├── init.lua           # エントリポイント
└── lua/
    └── config/
        └── lazy.lua   # lazy.nvim の設定
```

### init.lua

```lua
require("config.lazy")

if not vim.g.vscode then
    vim.opt.number = true    -- 行番号表示
    vim.opt.shiftwidth = 4   -- インデント幅 4
end
```

VSCode の Neovim 拡張機能 (`vscode-neovim`) と共有設定になっており、VSCode 上では行番号などの UI 設定をスキップする。

### lazy.nvim

プラグインマネージャーとして [lazy.nvim](https://github.com/folke/lazy.nvim) を使用。

| 設定 | 値 | 説明 |
|------|-----|------|
| `mapleader` | `Space` | リーダーキー |
| `maplocalleader` | `\` | ローカルリーダーキー |
| `install.colorscheme` | `habamax` | プラグインインストール中のカラースキーム |
| `checker.enabled` | `true` | プラグインの自動アップデートチェックを有効化 |

現在プラグイン定義 (`plugins/` ディレクトリ) はコメントアウトされており、最小構成。

---

## 1Password SSH エージェント

設定ファイル: `.config/1Password/ssh/agent.toml`

```toml
[[ssh-keys]]
vault = "個人"
```

「個人」Vault に保存されている SSH 鍵を 1Password SSH エージェント経由で使用する。

エージェントのソケットは以下に配置される:
```
~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock
```

動作確認:
```sh
SSH_AUTH_SOCK=~/Library/Group\ Containers/2BUA8C4S2C.com.1password/t/agent.sock ssh-add -l
```

### SSH 設定との連携

`.zshrc` 内で `SSH_AUTH_SOCK` を 1Password のソケットに向けることで、通常の `ssh` コマンドから透過的に 1Password の鍵が使用できる。
