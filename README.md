# Zsh Demo Magic
Inspired by a talk from [Illya Chekrygin at KubeCon 2023] using [demo-magic], I
wanted to try to make it feel more like my normal zsh shell.

- Documentation (and FAQ – if any) can found in this README.
- Feel free to file issues to report bugs, ask questions, or request features.
- Feel free to open a pull request.

# How It Works
I would have preferred to make this a executable script instead of needing to
source the file. However this is not possible as it needs to access variables
that could not be handed back up to the parent shell. (Or at least it would
introduce additional complexity, I would like to avoid.)

# How to Use it
Help can be displayed by executing the script directly `zsh zsh-demo-magic.zsh`.
```
% zsh zsh-demo-magic.zsh
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
```

# Integration for [p10k]
If you have `POWERLEVEL9K_LEFT_PROMPT_ELEMENTS` set you will get another
function for the `demo` segment. The segment displays the index of the current
command and the total commands (e.g. `7/42`) and a pause symbol
`ZSH_DEMO_MAGIC_PAUSED_ICON` that can be configured.

# Tools that Work Great in Conjunction
- `[fc -p]`: `fc` is builtin command from `zsh` and `-p` can be used to
  temporarily change the history file. Switch back with `fc -P`.
- `[prenv]`: My own tool to switch through environments
- `[tmuxinator]`: Create and manage tmux sessions

# Missing Features, Issues, Limitations
- prevent restart
- easy jump to command (relative or absolute), e.g. `zsh-demo-jump -1`,
  `zsh-demo-jump 5`, and `zsh-demo-jump +5`
- <kbd>Ctrl-C</kbd> interrupts typing animation, pop command from stack but does
  not increase index in p10k prompt
- typing randomisation not good enough (uniform instead of normal distribution)
- multiline might not behave like expected
- `#show` cannot be used as noop action (`#show echo noop`)
  workaround: `# echo noop`
- p10k segment needs to be set beforehand
- replace sensitive data in output?

[Illya Chekrygin at KubeCon 2023]: https://www.youtube.com/watch?v=2IPf_AyKSsU
[demo-magic]: https://github.com/paxtonhare/demo-magic
[p10k]: https://github.com/romkatv/powerlevel10k/blob/master/README.md
[fc -p]: https://zsh.sourceforge.io/Doc/Release/Shell-Builtin-Commands.html
[prenv]: https://github.com/syphdias/prenv
[tmuxinator]: https://github.com/tmuxinator/tmuxinator
