# dotfiles

macOS の設定ファイルを git 管理しているリポジトリ。

## ディレクトリ構成

```
dotfiles/
├── .zshrc                          # Zsh メイン設定
├── .zimrc                          # zimfw モジュール設定
├── .fzf.zsh                        # fzf 初期化スクリプト
└── .config/
    ├── ghostty/config              # Ghostty ターミナル設定
    ├── bat/config                  # bat (cat 代替) 設定
    ├── nvim/                       # Neovim 設定 (lazy.nvim)
    ├── karabiner/                  # Karabiner-Elements キーボード設定
    │   ├── karabiner.json          # メイン設定
    │   └── assets/complex_modifications/  # カスタムルール
    ├── 1Password/                  # 1Password 設定 (git 管理外)
    ├── iterm2/                     # iTerm2 設定 (git 管理外)
    └── op/                         # 1Password CLI 設定 (git 管理外)
```

## 必須ツール

| ツール | 用途 | インストール |
|--------|------|-------------|
| [zimfw](https://github.com/zimfw/zimfw) | Zsh プラグインマネージャー | `brew install zimfw` |
| [fzf](https://github.com/junegunn/fzf) | ファジーファインダー | `brew install fzf` |
| [ghq](https://github.com/x-motemen/ghq) | Git リポジトリ管理 | `brew install ghq` |
| [eza](https://github.com/eza-community/eza) | ls 代替 | `brew install eza` |
| [bat](https://github.com/sharkdp/bat) | cat 代替 | `brew install bat` |
| [Neovim](https://neovim.io/) | テキストエディタ | `brew install neovim` |
| [Ghostty](https://ghostty.org/) | ターミナルエミュレータ | 公式サイトから |
| [Karabiner-Elements](https://karabiner-elements.pqrs.org/) | キーボードカスタマイズ | 公式サイトから |
| [1Password](https://1password.com/) | SSH エージェント | 公式サイトから |

## セットアップ

```sh
git clone https://github.com/toshikimiyagawa/dotfiles.git ~/ghq/github.com/toshikimiyagawa/dotfiles
cd ~/ghq/github.com/toshikimiyagawa/dotfiles
bash install.sh
```

`install.sh` がホームディレクトリへのシンボリックリンクをすべて作成する。
既存ファイルがある場合は `.bak` にバックアップしてから上書きする。

> **注意**: `.config/1Password`, `.config/iterm2`, `.config/op` は git 管理外のため手動で設定する。

## ドキュメント

詳細は [docs/](docs/) を参照。

## TODO

やりたいこと・アイデアは [TODO.md](TODO.md) で管理。
