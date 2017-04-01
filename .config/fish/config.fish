export LANG=ja_JP.UTF8

function fish_prompt
  set status_face (set_color green)"\$ "

  set prompt (set_color yellow)"[ "(prompt_pwd)"/ ]"

  echo $prompt
  echo $status_face
end
