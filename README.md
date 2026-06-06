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

`install.sh` はホーム直下の dotfiles（`.zshrc` など）と `~/.config` のシンボリックリンクを作成する（冪等。ホーム直下の既存ファイルは `.bak` に退避してから上書き）。`~/.config` は **ディレクトリ自体を1つのリンク**として張るため、`.config/` 配下に置いた設定は自動で同期対象になる。

### 既存マシンの移行

`~/.config` がすでに実ディレクトリの場合、`install.sh` は警告を出して `.config` のリンクをスキップする。その場合は一度だけ移行スクリプトを実行する:

```sh
./migrate-config.sh
```

`~/.config` を `~/.config.bak.<timestamp>` に退避してからディレクトリリンクを張り、退避先の実ファイルを repo へ取り込む（衝突は差分表示のみで自動上書きしない・非破壊）。完了後、退避ディレクトリは内容を確認のうえ削除してよい。

### 設定の追加・除外

- `.config/` 配下に設定を追加したら `git add` してコミットするだけ（親リンク経由で同期されるので `install.sh` の編集は不要）。
- 同期したくないもの（秘匿情報・キャッシュ・マシン固有の状態ファイルなど）は `.gitignore` に都度追記する（ブロックリスト運用）。
- `~/.config` 全体が repo 配下になるため、コミット前に必ず `git status` で意図しないファイルが含まれていないか確認する。

> **注意**: `.config/1Password`, `.config/iterm2`, `.config/op` は `.gitignore` で git 管理外のため手動で設定する。

## ドキュメント

詳細は [docs/](docs/) を参照。

## TODO

やりたいこと・アイデアは [GitHub Issues](https://github.com/toshikimiyagawa/dotfiles/issues) で管理。
