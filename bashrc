# If not running interactively, don't do anything
# avoid bind: warning: line editing not enabled
case $- in
    *i*) ;;
      *) return;;
esac

export PLATFORM
PLATFORM=$(uname -s)
[ -f /etc/bashrc ] && . /etc/bashrc

### Append to the history file
shopt -s histappend

### Check the window size after each command ($LINES, $COLUMNS)
shopt -s checkwinsize

### Bash completion
[ -f /etc/bash_completion ] && . /etc/bash_completion

### Perform file completion in a case insensitive fashion
bind "set completion-ignore-case on"
### Display matches for ambiguous patterns at first tab press
bind "set show-all-if-ambiguous on"

# Don't put duplicate lines in the history and do not add lines that start with a space
export HISTCONTROL=erasedups:ignoredups:ignorespace

# Don't record some commands
export HISTIGNORE="&:[ ]*:exit:ls:bg:fg:history:clear"

export PROMPT_DIRTRIM=2

### man bash
export HISTSIZE=
export HISTFILESIZE=
export HISTTIMEFORMAT="%Y/%m/%d %H:%M:%S:   "
[ -z "$TMPDIR" ] && TMPDIR=/tmp

# Aliases
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'
alias ......='cd ../../../../..'

alias cd.='cd ..'
alias cd..='cd ..'
alias p='pwd'
alias l='ls -alF'
alias la='ls -al'
alias ll='ls -l'

## Git
alias ga='git add'
alias gb='git branch'
alias gc='git checkout'
alias gd='git diff'
alias gr='git remote'
alias gs='git status'
alias gpom="git push origin master"
alias gitv='git log --color --graph --pretty=format:"%Cred%h%Creset -%C(green)%d%Creset %s %C(yellow)(%cr) %C(blue)<%an>%Creset" --abbrev-commit --'
## up: cd .. when you're too lazy to use the spacebar
alias up="cd .."

## space: gets space left on disk
alias space="df -h"

## restart: a quick refresh for your shell instance.
alias restart="source ~/.bashrc"

### Tmux
alias tmux="tmux -2"

exists() {
    command -v "$1" >/dev/null 2>&1
}

if [ "$PLATFORM" = Darwin ]; then
  # For coreutils installed by brew
  # use these commands with their normal names, instead of the prefix 'g'
  PATH="/usr/local/opt/coreutils/libexec/gnubin:$PATH"
  MANPATH="/usr/local/opt/coreutils/libexec/gnuman:$MANPATH"
  if exists brew; then
    # For bash installed by brew
    [ -f "$(brew --prefix)/share/bash-completion/bash_completion" ] && . "$(brew --prefix)/share/bash-completion/bash_completion"
  fi
fi

### Colored ls
if exists "dircolors"; then
  eval "$(dircolors -b)"
  alias ls='ls --color=auto'
  alias grep='grep --color=auto'
elif [ "$PLATFORM" = Darwin ]; then
  alias ls='ls -G'
fi

# Prompt
function nonzero_return() {
	RETVAL=$?
	[ $RETVAL -ne 0 ] && echo "$RETVAL"
}

### git-prompt
# To show */+/% may have an impact on the performance
# Displays a * and + next to the branch name if there are unstaged (*) and staged (+) changes
# export GIT_PS1_SHOWDIRTYSTATE=true
# Displays a % if there are untracked files
# export GIT_PS1_SHOWUNTRACKEDFILES=true

if [ ! -e ~/.git-prompt.sh ]; then
  curl https://raw.githubusercontent.com/git/git/master/contrib/completion/git-prompt.sh -o ~/.git-prompt.sh
fi
source "$HOME/.git-prompt.sh"

# PROMPT_COMMAND='history -a; history -c; history -r; printf "\[\e[38;5;59m\]%$(($COLUMNS - 4))s\r" "$(__git_ps1) ($(date +%m/%d\ %H:%M:%S))"'
PROMPT_COMMAND='history -a; printf "\[\e[38;5;59m\]%$(($COLUMNS - 4))s\r" "$(__git_ps1) ($(date +%m/%d\ %H:%M:%S))"'

if [ "$PLATFORM" = Darwin ]; then
  PS1="\\[\\e[95m\\]\\w \\[\\e[1;93m\\]❯\\[\\e[1;92m\\]❯\\[\\e[1;96m\\]❯ \\[\\e[0m\\]"
else
  PS1="\\[\\e[94m\\]\\u\\[\\e[36m\\]@\\[\\e[0;32m\\]\\h\\[\\e[0m\\]:\\[\\e[95m\\]\\w \\[\\e[1;93m\\]❯\\[\\e[1;92m\\]❯\\[\\e[1;96m\\]❯ \\[\\e[0m\\]"
# PS1="\[\e[95m\]\w \[\e[1;93m\]>\[\e[1;92m\]>\[\e[1;96m\]> \[\e[0m\]"
fi

keybindings() {
  bind -p | grep -F "\\C"
}

add_pwd() {
  PATH=$(pwd):$PATH
  export PATH
}

if exists "fd"; then
  export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
elif exists "rg"; then
  export FZF_DEFAULT_COMMAND='rg --files --no-ignore --hidden --follow -g "!{.git,node_modules}/*" 2> /dev/null'
elif exists "ag"; then
  export FZF_DEFAULT_COMMAND='ag --hidden --ignore .git -g ""'
fi

EXTRA=$HOME/bashrc-extra
[ -f "$EXTRA" ] && source "$EXTRA"

[ -f ~/.fzf.bash ] && source ~/.fzf.bash

export FZF_COMPLETION_TRIGGER='/'

#bind -x '"\C-w": "fzf-file-widget"'
bind '"\C-h": " \C-e\C-u`__fzf_cd__`\e\C-e\er\C-m"'

# Git
## cshow - git commit browser (enter for show, ctrl-d for diff)
cshow() {
  local out shas sha q k
  while out=$(
      gitv "$@" |
      fzf --ansi --multi --no-sort --reverse --query="$q" \
          --print-query --expect=ctrl-d); do
    q=$(head -1 <<< "$out")
    k=$(head -2 <<< "$out" | tail -1)
    shas=$(sed '1,2d;s/^[^a-z0-9]*//;/^$/d' <<< "$out" | awk '{print $1}')
    [ -z "$shas" ] && continue
    if [ "$k" = ctrl-d ]; then
      git diff --color=always $shas | less -R
    else
      for sha in $shas; do
        git show --color=always $sha | less -R
      done
    fi
  done
}

# Tmux
## tpane - switch pane (@george-b)
tpane() {
  local panes current_window current_pane target target_window target_pane
  panes=$(tmux list-panes -s -F '#I:#P - #{pane_current_path} #{pane_current_command}')
  current_pane=$(tmux display-message -p '#I:#P')
  current_window=$(tmux display-message -p '#I')

  target=$(echo "$panes" | grep -v "$current_pane" | fzf +m --reverse) || return

  target_window=$(echo $target | awk 'BEGIN{FS=":|-"} {print$1}')
  target_pane=$(echo $target | awk 'BEGIN{FS=":|-"} {print$2}' | cut -c 1)

  if [[ $current_window -eq $target_window ]]; then
    tmux select-pane -t ${target_window}.${target_pane}
  else
    tmux select-pane -t ${target_window}.${target_pane} &&
    tmux select-window -t $target_window
  fi
}

# Switch tmux-sessions
tsession() {
  local session
  session=$(tmux list-sessions -F "#{session_name}" | \
    fzf --height 40% --reverse --query="$1" --select-1 --exit-0) &&
  tmux switch-client -t "$session"
}

clone() {
  local url=$1
  git ls-remote "$url" >/dev/null 2>&1
  if [ "$?" -ne 0 ]; then
    echo "[ERROR] Unable to read from $1"
    return
  fi
  if [[ $url =~ .git$ ]]; then
    url="${url%.*}"
  fi
  if [[ $url =~ ^git@github.com ]]; then
    repo="$(basename "$url")"
    user="$(echo "${url#*:}" | cut -d'/' -f1)"
  else
    repo="$(basename "${url}")"
    user="$(basename "${url%/${repo}}")"
  fi
  local target="$HOME/src/github.com/$user/$repo"
  if [ -d "$target" ]; then
    echo "[ERROR] $user/$repo already exists!"
  else
    git clone "$1" "$target" $2
    if [ "$?" -ne 0 ]; then
      echo "[ERROR] Unable to clone from $1"
      return
    fi
  fi
  cd "$target"
}

# Docker
dip() {
  if [ -z $1 ]; then
    echo "Usage: $FUNCNAME container_name    -- Show container IP"
  else
    docker inspect --format '{{ .NetworkSettings.IPAddress }}' "$1"
  fi
}

dbash() {
  if [ -z $1 ]; then
    echo "Usage: $FUNCNAME container_name    -- Execute interactive container"
  else
    docker exec -it $1 bash -c "stty cols $COLUMNS rows $LINES && bash"
  fi
}
