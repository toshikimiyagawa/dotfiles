set -x LANG ja_JP.UTF8
set -x GOPATH $HOME/go/
set -U fish_prompt_pwd_dir_length 0

function fish_prompt
  set status_face (set_color green)"\$ "

  set prompt (set_color yellow)"["(pwd)"/]"

  echo $prompt
  echo $status_face
end
