# Lines configured by zsh-newuser-install
HISTFILE=~/.histfile
HISTSIZE=1000
SAVEHIST=1000
bindkey -e
# End of lines configured by zsh-newuser-install
# The following lines were added by compinstall
zstyle :compinstall filename '$HOME/.zshrc'

autoload -Uz compinit
compinit
# End of lines added by compinstall

export PATH="$PATH:$HOME/.local/bin"

# Define an array of plugin files
plugins=(
    "$HOME/.zsh-plugins/autosuggestions.zsh"
    "$HOME/.zsh-plugins/dirhistory.zsh"
    "$HOME/.zsh-plugins/web-search.zsh"
    "$HOME/.zsh-plugins/you-should-use.zsh"
)

for plugin in "${plugins[@]}"; do
    if [ -f "$plugin" ]; then
        source "$plugin"
    fi
done

# load aliases from .zsh_aliases file
if [ -f ~/.zsh_aliases ]; then
    . ~/.zsh_aliases
fi

function powerline_precmd() {
    PS1="$(powerline-shell --shell zsh $?)"
}

function install_powerline_precmd() {
  for s in "${precmd_functions[@]}"; do
    if [ "$s" = "powerline_precmd" ]; then
      return
    fi
  done
  precmd_functions+=(powerline_precmd)
}

if [ "$TERM" != "linux" -a -x "$(command -v powerline-shell)" ]; then
    install_powerline_precmd
fi
