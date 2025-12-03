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
  local STATUS=$(git status --long 2>&1)
  local BRANCH=$(git branch 2>/dev/null | grep '^*' | colrm 1 2)
  local DIR_NAME="${PWD##*/}"
  local DEFAULT="%b%f"
  local GREEN="%b%F{green}"
  local RED="%b%F{red}"
  local YELLOW="%b%F{yellow}"
  local LAVENDER="%B%F{magenta}"

  if [[ "$STATUS" == *'not a git repository'* ]]; then
    # Not in a git repo - just show directory in lavender
    PS1+="$LAVENDER%1d"
    return
  fi

  # Determine git status color
  local GIT_COLOR="$DEFAULT"
  if [[ "$STATUS" != *'working tree clean'* ]]; then
    if [[ "$STATUS" == *'Changes to be committed'* ]]; then
      GIT_COLOR="$GREEN"
    fi
    if [[ "$STATUS" == *'Changes not staged for commit'* ]] || [[ "$STATUS" == *'Unmerged paths'* ]]; then
      GIT_COLOR="$RED"
    fi
  else
    if [[ "$STATUS" == *'Your branch is ahead'* ]]; then
      GIT_COLOR="$YELLOW"
    fi
  fi

  # Show consolidated or separate format
  if [[ "$BRANCH" == "$DIR_NAME" ]]; then
    # Branch matches directory - show once with git color
    PS1+="$GIT_COLOR%1d"
  else
    # Branch differs - show directory:branch
    PS1+="$LAVENDER%1d$DEFAULT:$GIT_COLOR$BRANCH"
  fi

  # Add untracked files indicator
  if [[ "$STATUS" == *'Untracked files'* ]]; then
    PS1+="$RED?"
  fi
}

__prompt_command() {
  local LAST_COMMAND_SUCCESS=$[$? == 0]
  local DEFAULT="%b%f"

  PS1=""
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
