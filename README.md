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
    ├── 1Password/ssh/agent.toml    # 1Password SSH エージェント設定
    └── op/config                   # 1Password CLI 設定
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

各ファイルをホームディレクトリにシンボリックリンクする。

```sh
ln -sf ~/ghq/github.com/toshikimiyagawa/dotfiles/.zshrc ~/.zshrc
ln -sf ~/ghq/github.com/toshikimiyagawa/dotfiles/.zimrc ~/.zimrc
ln -sf ~/ghq/github.com/toshikimiyagawa/dotfiles/.fzf.zsh ~/.fzf.zsh
ln -sf ~/ghq/github.com/toshikimiyagawa/dotfiles/.config/ghostty ~/.config/ghostty
ln -sf ~/ghq/github.com/toshikimiyagawa/dotfiles/.config/bat ~/.config/bat
ln -sf ~/ghq/github.com/toshikimiyagawa/dotfiles/.config/nvim ~/.config/nvim
ln -sf ~/ghq/github.com/toshikimiyagawa/dotfiles/.config/karabiner ~/.config/karabiner
ln -sf ~/ghq/github.com/toshikimiyagawa/dotfiles/.config/1Password ~/.config/1Password
ln -sf ~/ghq/github.com/toshikimiyagawa/dotfiles/.config/op ~/.config/op
```

## ドキュメント

詳細は [docs/](docs/) を参照。
