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

# Session manager: one shared, persistent herdr session.
# A new window attaches to whatever tab is focused; press prefix + c in it to
# branch onto a tab of its own, and the other windows stay where they are.
# (Don't create that tab from here: `herdr tab create --focus` goes through the
# socket API, which has no client field, so its focus applies to the whole
# session and drags every attached window onto the new tab. Only navigation a
# client does itself gives that client its own view.)
if [[ -z $HERDR_ENV && -z $TMUX ]] && command -v herdr >/dev/null; then
  herdr
fi
