#!/usr/bin/env zsh

if cat ~/.config/termite/config | grep day > /dev/null 2>&1
	then export THEME=day
	else export THEME=night
fi

if [[ $1 = day || $1 = d ]]; then
	export THEME=day
elif [[ $1 = night || $1 = n ]]; then
	export THEME=night
else
	[[ $THEME = day ]] && $0 n || $0 d
	exit 0
fi

killall dunst 2>/dev/null 1>&2

hsetroot -cover ~/dotfiles/wallpaper/${THEME}.png
ln -sf ~/dotfiles/${THEME}-theme/termite-conf ~/.config/termite/config
ln -sf ~/dotfiles/${THEME}-theme/zathurarc ~/.config/zathura/zathurarc
ln -sf ~/dotfiles/${THEME}-theme/dunstrc ~/.config/dunst/dunstrc
ln -sf ~/dotfiles/${THEME}-theme/rofi.rasi ~/.config/rofi/config.rasi
killall -USR1 termite >/dev/null 2>&1
dunst >/dev/null 2>&1 &!
echo $THEME

# vim: set ts=4 sts=4 sw=4 noet :
