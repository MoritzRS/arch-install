# ZSH History
HISTFILE=~/.zhistory
HISTSIZE=1000
SAVEHIST=1000

# NVM Install
export NVM_DIR="/usr/local/nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

## aliases
alias ls="ls --color=auto"

# ZSH Plugins
source /usr/local/zsh-plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
source /usr/local/zsh-plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# Starship Theme
eval "$(starship init zsh)"