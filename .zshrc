# bindkey
bindkey -e
bindkey "^?"    backward-delete-char
bindkey "^H"    backward-delete-char
bindkey "^[[3~" delete-char
bindkey "^[[1~" beginning-of-line
bindkey "^[[4~" end-of-line

#Ctrl-sで端末ロックしないようにする
stty stop undef

export LANG=ja_JP.UTF-8
export EDITOR=vim
export VISUAL=vim
export ALTERNATE_EDITOR=vim
#export ANDROID_SWT=~/android-sdks/tools/lib/x86
export JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk1.7.0_71.jdk/Contents/Home
#export MAVEN_HOME=/usr/local/maven
#export M2_HOME=/usr/local/maven
#export EMR_HOME=/usr/local/emr
#export PATH=$MAVEN_HOME/bin:$JAVA_HOME/bin:$HOME/bin:$EMR_HOME:/usr/local/share/python:/usr/local/Cellar/s3cmd/1.5.0/bin/:/Users/t_miyagawa/pear/bin/:$PATH
#export CLASSPATH=/usr/local/Cellar/hadoop/1.2.1/libexec/hadoop-core-1.2.1.jar:$CLASSPATH
#export HADOOP_OPTS="-Djava.security.krb5.realm=OX.AC.UK -Djava.security.krb5.kdc=kdc0.ox.ac.uk:kdc1.ox.ac.uk"
export HOMEBREW_GITHUB_API_TOKEN=7c0a8f65d5cf6acd84220d5c211910bfe685aeef

#export LSCOLORS=GxFxCxdxBxegedabagacad
if [ $TERM = "xterm" ] ; then
    export TERM=xterm-256color
fi

if [ $USER = "root" ] ; then
    HISTFILE=$HOME/.zsh_history_root
else
    HISTFILE=$HOME/.zsh_history
fi
HISTSIZE=100000
SAVEHIST=100000

## 補完機能の強化
autoload -U compinit
compinit

## コアダンプサイズを制限
#limit coredumpsize 102400

## 出力の文字列末尾に改行コードが無い場合でも表示
unsetopt promptcr

## 色を使う
setopt prompt_subst

## ビープを鳴らさない
setopt nobeep

## 内部コマンド jobs の出力をデフォルトで jobs -l にする
setopt long_list_jobs

## 補完候補一覧でファイルの種別をマーク表示
setopt list_types

## サスペンド中のプロセスと同じコマンド名を実行した場合はリジューム
setopt auto_resume

## 補完候補を一覧表示
setopt auto_list

## 直前と同じコマンドをヒストリに追加しない
setopt hist_ignore_dups

## cd 時に自動で push
setopt autopushd

## 同じディレクトリを pushd しない
setopt pushd_ignore_dups

## ファイル名で #, ~, ^ の 3 文字を正規表現として扱う
setopt extended_glob

## TAB で順に補完候補を切り替える
setopt auto_menu

## zsh の開始, 終了時刻をヒストリファイルに書き込む
setopt extended_history

## =command を command のパス名に展開する
setopt equals

## --prefix=/usr などの = 以降も補完
setopt magic_equal_subst

## ヒストリを呼び出してから実行する間に一旦編集
setopt hist_verify

# ファイル名の展開で辞書順ではなく数値的にソート
setopt numeric_glob_sort

## 出力時8ビットを通す
setopt print_eight_bit

## ヒストリを共有
setopt share_history

## 補完候補のカーソル選択を有効に
zstyle ':completion:*:default' menu select=1

## ディレクトリ名だけで cd
setopt auto_cd

## カッコの対応などを自動的に補完
setopt auto_param_keys

## ディレクトリ名の補完で末尾の / を自動的に付加し、次の補完に備える
setopt auto_param_slash

## 先頭がスペースで始まる場合ヒストリに追加しない
setopt hist_ignore_space

autoload -U compinit
compinit

#if [ $TERM = "xterm-256color" ] ; then
## 補完候補の色づけ
zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}

##色付け
autoload -U colors
colors

## Default shell configuration
#
# set prompt
#
#
if [ $TERM = "xterm-256color" ] ; then
    PROMPT="%{$fg[green]%}[%/]%{[m%}"$'\n'"%% "
else
    PROMPT="%{[38;5;48m%}[%/]%{[m%}"$'\n'"%% "
fi
PROMPT2="%{[31m%}%_%%%{[m%} "
SPROMPT="%{[31m%}%r is correct? [n,y,a,e]:%{[m%} "
#else
#    PROMPT="[%/]"$'\n'"%% "
#    PROMPT2="%_%% "
#    SPROMPT="%r is correct? [n,y,a,e]: "
#fi


# #chpwd () {
# #	# for cdd
# #	_reg_pwd_screennum
# #
# #	update-git-status
# #}

#     update-git-status () {
# 	local ret
# 	ret=$(git branch -a 2>/dev/null | grep "^*" | tr -d '\* ')
# 	if [ "$ret" = "" ]; then
# 	    PROMPT="$PROMPT_EXIT$PROMPT_CWD$PROMPT_L"
# 	else
# 	    PROMPT="$PROMPT_EXIT$PROMPT_CWD [32m%}($ret)%{[m%}$PROMPT_L"
# 	fi
#     }
# fi

alias gd='dirs -v; echo -n "select number: "; read newdir; cd +"$newdir"'

#preexec() {
    #  echo ${PWD};
#    if [ $TERM == "screen" ]; then
#        tmux rename-window "[${PWD}] $1"
#    fi
#}

#if which rbenv > /dev/null; then eval "$(rbenv init -)"; fi


if [ -e ~/.zshrc_local ]; then
    source ~/.zshrc_local
fi

if [ -e ~/.zshrc_percol ]; then
    source ~/.zshrc_percol
fi

if [ -e ~/.zshrc_anyenv ]; then
    source ~/.zshrc_anyenv
fi
#export TMUX_TMPDIR=/var/run/tmux
export GOPATH="$HOME/go/"
export PATH=$GOPATH/bin:$PATH
