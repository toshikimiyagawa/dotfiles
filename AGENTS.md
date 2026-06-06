# dotfiles

macOS の設定ファイルを git 管理しているリポジトリ。

## 概要

このリポジトリは個人の macOS 開発環境設定を管理する dotfiles。
Zsh (zimfw)、Neovim (lazy.nvim)、Ghostty、Karabiner-Elements などの設定を含む。

`~/.config` は `.config` ディレクトリ自体を1つのシンボリックリンクとしてホームに張る（配下を丸ごと git 管理）。同期したくないもの（`.config/1Password/`、`.config/iterm2/`、`.config/op/` など）は `.gitignore` に都度追記するブロックリスト運用。コミット前に `git status` で意図しないファイルが含まれていないか確認する。

## 作業時の注意

- 設定変更は実際のホームディレクトリへのシンボリックリンク経由で反映される（`~/.config` はディレクトリ単位でリンク）
- 既存マシンで個別リンクから移行する場合は `./migrate-config.sh` を一度実行する（非破壊。退避ディレクトリを残す）
- Neovim の設定は lazy.nvim を使用しており、`.config/nvim/` 配下に格納
- Karabiner のカスタムルールは `.config/karabiner/assets/complex_modifications/` に JSON で定義
