# dotfiles

macOS の設定ファイルを git 管理しているリポジトリ。

## 概要

このリポジトリは個人の macOS 開発環境設定を管理する dotfiles。
Zsh (zimfw)、Neovim (lazy.nvim)、Ghostty、Karabiner-Elements などの設定を含む。

`.config/1Password/`、`.config/iterm2/`、`.config/op/` は `.gitignore` で git 管理外。

## 作業時の注意

- 設定変更は実際のホームディレクトリへのシンボリックリンク経由で反映される
- Neovim の設定は lazy.nvim を使用しており、`.config/nvim/` 配下に格納
- Karabiner のカスタムルールは `.config/karabiner/assets/complex_modifications/` に JSON で定義
