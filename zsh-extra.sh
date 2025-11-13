# Keymap
bindkey -e

# History
HISTFILE="$HOME/.zsh_history"
HISTSIZE=100000
SAVEHIST=$HISTSIZE
setopt INC_APPEND_HISTORY
setopt HIST_IGNORE_DUPS
setopt HIST_REDUCE_BLANKS
setopt HIST_VERIFY

# Kill autocorrect
unsetopt CORRECT CORRECT_ALL

# Git-aware prompt
__git_branch_and_status () {
  # Get the status of the repo and color the branch name appropriately
  local STATUS=$(git status --long 2>&1)
  local BRANCH=$(git branch 2>/dev/null | grep '^*' | colrm 1 2)
  local GREEN="%b%F{green}"
  local RED="%b%F{red}"
  local YELLOW="%b%F{yellow}"
  if [[ "$STATUS" != *'not a git repository'* ]]
  then
    PS1+="$DEFAULT:"
    if [[ "$STATUS" != *'working tree clean'* ]]
    then
      if [[ "$STATUS" == *'Changes to be committed'* ]]
      then
        # green if all changes are staged
        PS1+="$GREEN"
      fi
      if [[ "$STATUS" == *'Changes not staged for commit'* ]] || [[ "$STATUS" == *'Unmerged paths'* ]]
      then
        # red if there are unstaged changes
        PS1+="$RED"
      fi
    else
      if [[ "$STATUS" == *'Your branch is ahead'* ]]
      then
        # yellow if need to push
        PS1+="$YELLOW"
      else
        # else default
        PS1+="$DEFAULT"
      fi
    fi

    PS1+="$BRANCH"

    if [[ "$STATUS" == *'Untracked files'* ]]
    then
      # red question mark to indicate untracked files
      PS1+="$RED"
      PS1+="?"
    fi
  fi
}

__prompt_command() {
  local LAST_COMMAND_SUCCESS=$[$? == 0]
  local DEFAULT="%b%f"
  local JADE="%F{36}"
  local LAVENDER="%B%F{magenta}"
  # Show current directory in lavender
  PS1="$LAVENDER%1d"
  __git_branch_and_status
  if [ $LAST_COMMAND_SUCCESS = 1 ]; then
    PS1+="%b%F{green}"
  else
    PS1+="%b%F{red}"
  fi
  PS1+=" λ.$DEFAULT "
}

precmd() { __prompt_command; }

__pretty_line() {
  # Needs 'bc' and 'tput' (ensure pkgs.bc is installed below)
  local OFFSET END LINE STUFF C
  OFFSET=$(bc <<< "16 + ($RANDOM % 36 + 1)*6")
  END=$(bc <<< "$OFFSET + 5")
  LINE=""
  for C in $(seq $OFFSET $END); do
    STUFF=$(printf ' %.0s' $(seq 1 $(bc <<< "$(tput cols)/12")))
    LINE+="\033[48;5;${C}m${STUFF}"
  done
  for C in $(seq $END $OFFSET); do
    STUFF=$(printf ' %.0s' $(seq 1 $(bc <<< "$(tput cols)/12")))
    LINE+="\033[48;5;${C}m${STUFF}"
  done
  LINE+=$(printf ' %.0s' $(seq 1 $(bc <<< "$(tput cols) - 12*($(tput cols)/12)")))
  echo -e "$LINE"
  tput sgr0
}

__clear_with_line () { clear; __pretty_line; zle redisplay }

zle -N __clear_with_line
bindkey '^L' __clear_with_line
