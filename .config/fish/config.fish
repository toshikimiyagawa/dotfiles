set -x LANG ja_JP.UTF8
set -x GOPATH $HOME/go/
set -x PATH $PATH $GOPATH/bin
set -U fish_prompt_pwd_dir_length 0
set -U FZF_LEGACY_KEYBINDINGS 0
alias vi='nvim'

function fish_prompt
  set status_face (set_color green)"\$ "

  set prompt (set_color yellow)"["(pwd)"/]"

  echo $prompt
  echo $status_face
end
