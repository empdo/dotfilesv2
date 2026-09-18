#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
alias grep='grep --color=auto'
PS1='[\u@\h \W]\$ '


if [[ -z $DISPLAY && $(tty) == /dev/tty1 ]]; then
	exec Hyprland
fi

export GTK_THEME=Adwaita:dark
export MOZ_ENABLE_WAYLAND=1
export JAVA_HOME=/usr/lib/jvm/java-25-openjdk/bin/java
export PATH=$JAVA_HOME/bin:$PATH

# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH

# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time Oh My Zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
#
ZSH_THEME="robbyrussell"

source $ZSH/oh-my-zsh.sh

if [ -z "$TMUX" ]; then
  tmux new-session -s "kitty-$(date +%s)"
fi
