# Brewfile
# Usage: brew bundle --file=./Brewfile

tap "homebrew/bundle"

# ---- Shell / Prompt ----
brew "zimfw"                  # Zsh プラグインマネージャー (.zimrc)
brew "starship"               # プロンプト (.config/starship.toml)

# ---- CLI ユーティリティ ----
brew "fzf"                    # ファジーファインダー (.fzf.zsh / zimfw fzf)
brew "ghq"                    # Git リポジトリ管理 (.zshrc の ghq-fzf)
brew "eza"                    # ls 代替 (.zshrc の ghq-fzf preview)
brew "bat"                    # cat 代替 (.config/bat/config)
brew "gh"                     # GitHub CLI (.config/gh)
brew "git"                    # Git (.gitconfig / .config/git)

# ---- エディタ ----
brew "neovim"                 # .config/nvim (lazy.nvim)

# ---- tmux + Claude 構成 (docs/tmux-claude.md) ----
brew "tmux"
brew "yazi"                   # ファイラー
brew "lazygit"                # Git TUI
brew "tig"                    # Git ツリービューア

# ---- 言語ランタイム (.zshrc / .zprofile / starship 表示) ----
brew "go"                     # GOPATH=$HOME/go
brew "pyenv"                  # PYENV_ROOT=$HOME/.pyenv

# ---- フォント (Ghostty / Nerd Font アイコン) ----
cask "font-fira-code-nerd-font"

# ---- GUI アプリ ----
cask "ghostty"                # ターミナル (.config/ghostty)
cask "karabiner-elements"     # キーボードカスタマイズ (.config/karabiner)
cask "1password"              # SSH エージェント (docs/tools.md)
cask "1password-cli"          # op コマンド (.config/op)
cask "iterm2"                 # サブターミナル (.config/iterm2)
cask "cmux"                   # cmux アプリ (.config/cmux)
