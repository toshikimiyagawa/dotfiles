zimfw() { source /Users/toshiki/.zim/zimfw.zsh "${@}" }
zmodule() { source /Users/toshiki/.zim/zimfw.zsh "${@}" }
fpath=(/Users/toshiki/.zim/modules/git/functions /Users/toshiki/.zim/modules/utility/functions /Users/toshiki/.zim/modules/duration-info/functions /Users/toshiki/.zim/modules/git-info/functions /Users/toshiki/.zim/modules/prompt-pwd/functions /Users/toshiki/.zim/modules/zsh-completions/src /Users/toshiki/.zim/modules/archive/functions ${fpath})
autoload -Uz -- git-alias-lookup git-branch-current git-branch-delete-interactive git-branch-remote-tracking git-dir git-ignore-add git-root git-stash-clear-interactive git-stash-recover git-submodule-move git-submodule-remove mkcd mkpw duration-info-precmd duration-info-preexec coalesce git-action git-info prompt-pwd archive lsarchive unarchive
source /Users/toshiki/.zim/modules/environment/init.zsh
source /Users/toshiki/.zim/modules/git/init.zsh
source /Users/toshiki/.zim/modules/input/init.zsh
source /Users/toshiki/.zim/modules/termtitle/init.zsh
source /Users/toshiki/.zim/modules/utility/init.zsh
source /Users/toshiki/.zim/modules/duration-info/init.zsh
source /Users/toshiki/.zim/modules/eriner/eriner.zsh-theme
source /Users/toshiki/.zim/modules/completion/init.zsh
source /Users/toshiki/.zim/modules/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source /Users/toshiki/.zim/modules/zsh-history-substring-search/zsh-history-substring-search.zsh
source /Users/toshiki/.zim/modules/zsh-autosuggestions/zsh-autosuggestions.zsh
source /Users/toshiki/.zim/modules/archive/init.zsh
source /Users/toshiki/.zim/modules/fzf/init.zsh
source /Users/toshiki/.zim/modules/homebrew/init.zsh
source /Users/toshiki/.zim/modules/exa/init.zsh
