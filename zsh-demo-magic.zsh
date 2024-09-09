#!/usr/bin/env zsh
# Script to demo some commands

if [[ $ZSH_EVAL_CONTEXT == 'toplevel' ]]; then
    cat << EOHELP
Define your commands in a file \$ZSH_DEMO_MAGIC_COMMANDS_FILE
Every line is a command. It can be augmented with special comments.

Initialize:
    source \"${0}\"" [start]

Function Usage:
    zsh-demo-start  # start or restart 
    zsh-demo-pause
    zsh-demo-resume
    zsh-demo-end

Comment augmentations:
  [COMMAND ARGS] [#show FAKECOMMAND] [#[no]wait] [#[no]animation]

  #show        execute everything before #show but show everything before it
               e.g. \`cat /etc/hosts #show curl google.com\`

  #wait        only display command but wait for enter to send it;
               default behavior with ZSH_DEMO_MAGIC_WAIT=true
  #nowait      display command and send it;
               default behavior with ZSH_DEMO_MAGIC_WAIT=false
  #animation   type command
               default behaviour with ZSH_DEMO_MAGIC_ANIMATIONS=true
  #noanimation instantly show command
               default behaviour with ZSH_DEMO_MAGIC_ANIMATIONS=false

Configuration:
  ZSH_DEMO_MAGIC_COMMANDS_FILE
    path to file with commands
  ZSH_DEMO_MAGIC_ANIMATIONS
    default: true; animate typing
  ZSH_DEMO_MAGIC_WAIT
    default: true; Wait for Enter after
  ZSH_DEMO_MAGIC_ANIMATION_SPEED_CPS
    default: 10; characters per second
  ZSH_DEMO_MAGIC_ANIMATION_SPEED_CPS_RANDOMNESS
    default: 50; 1 for no randomness; animation speed
  ZSH_DEMO_MAGIC_DEBUG
    don't strip #augmentation
EOHELP
    exit 0
fi


# settings
typeset -g ZSH_DEMO_MAGIC_COMMANDS_FILE
typeset -g ZSH_DEMO_MAGIC_ANIMATIONS="${ZSH_DEMO_MAGIC_ANIMATIONS:-true}"
typeset -g ZSH_DEMO_MAGIC_WAIT="${ZSH_DEMO_MAGIC_WAIT:-true}"
typeset -g ZSH_DEMO_MAGIC_ANIMATION_SPEED_CPS=10
typeset -g ZSH_DEMO_MAGIC_ANIMATION_SPEED_CPS_RANDOMNESS=50
typeset -g ZSH_DEMO_MAGIC_DEBUG="${ZSH_DEMO_MAGIC_DEBUG:-false}"

# p10k segement config
typeset -g ZSH_DEMO_MAGIC_PAUSED_ICON="${ZSH_DEMO_MAGIC_PAUSED_ICON:- 󰏤}"

# state
typeset -g _ZSH_DEMO_MAGIC_STATUS=stopped


if [[ -n "${POWERLEVEL9K_LEFT_PROMPT_ELEMENTS}" ]]; then
    function prompt_demo() {
        # FIXME: Ctrl-C shows the next index number
        if [[ "${_ZSH_DEMO_MAGIC_STATUS}" != "stopped" && -n "${_ZSH_DEMO_MAGIC_COMMANDS}" && ${_ZSH_DEMO_MAGIC_COMMANDS_INDEX} -le ${#_ZSH_DEMO_MAGIC_COMMANDS} ]]; then
            # FIXME: Make customization of icons more inline with p10k way of doing things
            [[ "${_ZSH_DEMO_MAGIC_STATUS}" == "paused" ]] \
                && _ZSH_DEMO_MAGIC_PAUSED_ICON="${ZSH_DEMO_MAGIC_PAUSED_ICON}" \
                || _ZSH_DEMO_MAGIC_PAUSED_ICON=""
            p10k segment -f 197 -t "${_ZSH_DEMO_MAGIC_COMMANDS_INDEX}/${#_ZSH_DEMO_MAGIC_COMMANDS}${_ZSH_DEMO_MAGIC_PAUSED_ICON}"
        fi
    }
fi

function zsh-demo-start() {
    # check if everything is in order
    if [[ ! -e "${ZSH_DEMO_MAGIC_COMMANDS_FILE}" ]]; then
        echo "File \"${ZSH_DEMO_MAGIC_COMMANDS_FILE}\" does not exist " \
            "or ZSH_DEMO_MAGIC_COMMANDS_FILE has not been definied" >&2
        return 1
    fi
    _ZSH_DEMO_MAGIC_COMMANDS=("${(@f)$(cat "${ZSH_DEMO_MAGIC_COMMANDS_FILE}")}")
    # remove empty lines
    _ZSH_DEMO_MAGIC_COMMANDS=("${(@)_ZSH_DEMO_MAGIC_COMMANDS:#""}")
    _ZSH_DEMO_MAGIC_COMMANDS_INDEX=1
    _ZSH_DEMO_MAGIC_COMMANDS_TOTAL=${#_ZSH_DEMO_MAGIC_COMMANDS}

    # find and save binding for Enter key
    if [[ ! -n "${_ENTER_KEY_BINDING}" ]]; then
        _ENTER_KEY_BINDING="$(bindkey '^M')"
        _ENTER_KEY_BINDING="${_ENTER_KEY_BINDING##* }"
    fi

    # append zsh-demo-end function _ZSH_DEMO_MAGIC_COMMANDS
    typeset -g _ZSH_DEMO_MAGIC_COMMANDS
    _ZSH_DEMO_MAGIC_COMMANDS+=("zsh-demo-end #nowait")

    # set demo bindkey to Enter key
    bindkey '^M' demo-accept-line

    _ZSH_DEMO_MAGIC_STATUS=running
}

function zsh-demo-pause () {
    _ZSH_DEMO_MAGIC_STATUS=paused
}

function zsh-demo-resume () {
    _ZSH_DEMO_MAGIC_STATUS=running
}

function zsh-demo-end() {
    # restore binding for Enter key
    bindkey '^M' "${_ENTER_KEY_BINDING}"

    # clear remaining commands and index
    unset _ZSH_DEMO_MAGIC_COMMANDS _ZSH_DEMO_MAGIC_COMMANDS_INDEX _ZSH_DEMO_MAGIC_COMMANDS_TOTAL

    _ZSH_DEMO_MAGIC_STATUS=stopped
}


function fill-buffer-slow() {
    for i in ${(@s::)1}; do
        LBUFFER=${LBUFFER}$i
        zle .reset-prompt
        zle -R

        # FIXME: should be a normal distribution of +-Rand/2 around 1
        sleep $((
            1 /
            (ZSH_DEMO_MAGIC_ANIMATION_SPEED_CPS
              * (1 + (RANDOM % ZSH_DEMO_MAGIC_ANIMATION_SPEED_CPS_RANDOMNESS 
                       - ZSH_DEMO_MAGIC_ANIMATION_SPEED_CPS_RANDOMNESS / 2
                     ) / 100.
                 )
            )
        ))
    done
}

function demo-accept-line() {
    # run command from show
    if [[ -n "${_ZSH_DEMO_MAGIC_NEXT_COMMAND_EVAL}" && "${_ZSH_DEMO_MAGIC_NEXT_COMMAND_SHOW}" == "${BUFFER}" ]]; then
        # echos needed to make space
        echo
        eval "${_ZSH_DEMO_MAGIC_NEXT_COMMAND_EVAL}"
        echo

        # cleanup
        unset _ZSH_DEMO_MAGIC_NEXT_COMMAND_SHOW
        unset _ZSH_DEMO_MAGIC_NEXT_COMMAND_EVAL

        # show new prompt
        BUFFER=""
        zle .reset-prompt
        zle -R
        # hacky way to redraw demo_prompt elements to update index
        # https://github.com/romkatv/zsh4humans/issues/65
        if [[ -n "${Z4H}" ]]; then
            -z4h-redraw-prompt
        fi

        return
    fi

    # run normal interaction
    if [[ "${_ZSH_DEMO_MAGIC_STATUS}" != "running" \
            || "$BUFFER" != "" \
            || ${_ZSH_DEMO_MAGIC_COMMANDS_INDEX} -gt ${#_ZSH_DEMO_MAGIC_COMMANDS} ]]; then
        zle "${_ENTER_KEY_BINDING}"
        return
    fi

    # pop current line
    # TODO: make local?
    cmd="${_ZSH_DEMO_MAGIC_COMMANDS[${_ZSH_DEMO_MAGIC_COMMANDS_INDEX}]}"
    ((_ZSH_DEMO_MAGIC_COMMANDS_INDEX++))

    local -a _strip_patterns=()
    local _strip_pattern _wait _animation

    # wait
    if [[ "${ZSH_DEMO_MAGIC_WAIT}" == "true" ]]; then
        _wait="true"
    else
        _wait="false"
    fi
    # TODO: think about how conflicts should be resolved
    if [[ "${cmd}" =~ "#wait" ]]; then
        _wait="true"
        _strip_patterns+=(" #wait")
    fi
    if [[ "${cmd}" =~ "#nowait" ]]; then
        _wait="false"
        _strip_patterns+=(" #nowait")
    fi

    # animation
    if [[ "${ZSH_DEMO_MAGIC_ANIMATIONS}" == "true" ]]; then
        _animation="true"
    else
        _animation="false"
    fi
    # TODO: think about how conflicts should be resolved
    if [[ "${cmd}" =~ "#animation" ]]; then
        _animation="true"
        _strip_patterns+=(" #animation")
    fi
    if [[ "${cmd}" =~ "#noanimation" ]]; then
        _animation="false"
        _strip_patterns+=(" #noanimation")
    fi

    # strip all found pattern
    # needs to be done before #show
    if [[ "${ZSH_DEMO_MAGIC_DEBUG}" != "true" ]]; then
        for _strip_pattern in ${(@)_strip_patterns}; do
            cmd="${cmd//${_strip_pattern}}"
        done
    fi

    if [[ "${cmd}" =~ " #show" ]]; then
        # cannot be local since we need it in next function
        local literal_show="#show"

        _ZSH_DEMO_MAGIC_NEXT_COMMAND_EVAL="${cmd// ${literal_show}*}"
        # remove everything before #show and #show
        if [[ "${ZSH_DEMO_MAGIC_DEBUG}" != "true" ]]; then
            cmd=${cmd//*${literal_show} }
        fi
        _ZSH_DEMO_MAGIC_NEXT_COMMAND_SHOW="${cmd}"
    fi

    if [[ "$_animation" == "true" ]]; then
        # builtin echo -n "$cmd" | pv -qL ${ZSH_DEMO_MAGIC_ANIMATION_SPEED_CPS:-20}
        fill-buffer-slow "$cmd"
    fi

    # always set BUFFER in case animation gets interrupted by SIGINT
    LBUFFER=${cmd}
    zle .reset-prompt
    zle -R

    # Press "enter"
    if [[ "${_wait}" == "false" ]]; then
        zle "${_ENTER_KEY_BINDING}"
    fi
}
zle -N demo-accept-line

if [[ "$1" == "start" ]]; then
    zsh-demo-start
fi
