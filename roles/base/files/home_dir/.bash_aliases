# To debug, enable the 'set -x' line
export PS4='+ ${BASH_SOURCE:-}:${FUNCNAME[0]:-}:L${LINENO:-}:   '
# set -x
_XTRACE=

alias vi=vim
export EDITOR=vim

# Setup 'fd' command. In Fedora it is 'fd', in Ubuntu it is 'fdfind'
if command -v fd >/dev/null; then
    FD_CMD="fd"
elif command -v fdfind >/dev/null; then
    FD_CMD="fdfind"
    alias fd="fdfind"
else
    FD_CMD=""
fi

# Setup 'bat' command. In Fedora it is 'bat', in Ubuntu it is 'batcat'
if command -v bat >/dev/null; then
    alias cat="bat"
    alias cap="bat -p"
elif command -v batcat >/dev/null; then
    alias cat="batcat"
    alias cap="batcat -p"
fi

# enable color support of ls and also add handy aliases
if [[ -x /usr/bin/dircolors ]]; then
    # Load our custom ~/.dircolors file if we have one
    if [[ -r ~/.dircolors ]]; then
        eval "$(dircolors -b ~/.dircolors)"
    else
        eval "$(dircolors -b)"
    fi
    alias ls="ls --color=auto -A"
    alias ll="ls --color=auto -Al"
    # exa versions of l* commands, if exa present
    if command -v exa >/dev/null; then
        alias lh="exa --color=auto --color-scale --classify --long --all --group-directories-first --header --binary --links --group --modified --git"
        alias lho="exa --color=auto --color-scale --classify --long --all --group-directories-first --header --binary --links --group --modified --git --sort age --reverse"
        alias l2="exa --color=auto --color-scale --classify --long --all --group-directories-first --header --binary --links --group --modified --git --extended"
    fi

    alias dir='dir --color=auto'
    alias vdir='vdir --color=auto'

    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'

    alias ag="ag --pager 'less -RF'"
fi

# don't put duplicate lines in the history. See bash(1) for more options
# ... or force ignoredups and ignorespace
export HISTCONTROL=ignoredups:ignorespace
# append to the history file, don't overwrite it
shopt -s histappend
# Set history file length to unlimited. (See HISTSIZE and HISTFILESIZE in bash(1)
export HISTSIZE=-1
export HISTFILESIZE=-1
export HISTTIMEFORMAT="%Y-%m-%d %T  "

function _jlvillal_prompt_command {
    # Write previous command to history file so that, any new shell immediately
    # gets the history lines from all previous shells.
    history -a
    # Log each command to our log file
    local log_file
    local log_msg
    log_file=~/.logs/bash/bash-history-$(date "+%Y-%m-%d").log
    log_msg="$(date "+%Y-%m-%d.%H:%M:%S") $(pwd) $(HISTTIMEFORMAT= history 1)"
    echo "${log_msg}" >> ${log_file}
}

# Enable FZF if present
for FZF_KEYBINDINGS_FILE in /usr/share/fzf/shell/key-bindings.bash /usr/share/doc/fzf/examples/key-bindings.bash
do
    if [[ -f ${FZF_KEYBINDINGS_FILE} ]]; then
        _XTRACE=$(set +o | grep xtrace)
        set +o xtrace
        source ${FZF_KEYBINDINGS_FILE}
        ${_XTRACE}
        # If we have ripgrep in our path, use it
        if command -v rg >/dev/null; then
            # Use 'command' just in case of aliases
            export FZF_DEFAULT_COMMAND="command rg --files --no-ignore --hidden --follow -g "!{.git,node_modules}/*" 2> /dev/null"
            export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
        fi
        if [[ -n ${FD_CMD} ]]; then
            export FZF_DEFAULT_COMMAND="command ${FD_CMD} . $HOME"
            export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
            export FZF_CTRL_T_COMMAND="command ${FD_CMD} . ."
            export FZF_ALT_C_COMMAND="command ${FD_CMD} --type d --hidden . ${HOME} | grep -v '\.tox'"
        fi
        break
    fi
done

# Enable FZF completions if available
if [[ -f /usr/share/doc/fzf/examples/completion.bash ]]; then
    _XTRACE=$(set +o | grep xtrace)
    set +o xtrace
    source /usr/share/doc/fzf/examples/completion.bash
    ${_XTRACE}
fi

# Prefer Starship if installed, otherwise try powerline
if command -v starship >/dev/null; then
    # Use Starship
    eval "$(starship init bash)"
else
    for POWERLINE_PROMPT_FILE in /usr/share/powerline/bash/powerline.sh /usr/share/powerline/bindings/bash/powerline.sh; do
        if [[ -f ${POWERLINE_PROMPT_FILE} ]]; then
            source ${POWERLINE_PROMPT_FILE}
            break
        fi
    done
fi

# Create our logs bash directory if needed
mkdir -p ~/.logs/bash
# When displaying prompt, write previous command to history file so that, any
# new shell immediately gets the history lines from all previous shells.
if [[ -n "${PROMPT_COMMAND}" ]]; then
    # Have an existing PROMPT_COMMAND, which is almost always the case
    PROMPT_COMMAND="_jlvillal_prompt_command;${PROMPT_COMMAND}"
else
    # We didn't have a PROMPT_COMMAND defined
    PROMPT_COMMAND='_jlvillal_prompt_command;printf "\033]0;%s@%s:%s\007" "${USER}" "${HOSTNAME%%.*}" "${PWD/#$HOME/~}"'
fi

# Remove unneeded temp variables
unset FD_CMD _XTRACE

set +x
