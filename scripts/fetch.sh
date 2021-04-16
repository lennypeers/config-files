#!/usr/bin/env bash

clear && echo

logo=(
"    .--.     "
"   |o_o |    "
"   |:_/ |    "
"  //   \ \   "
" (|     | )  "
"/'\_   _/'\  "
"\___)=(___/  "
)
# logo taken from https://ascii.co.uk/art/linux

label=$([[ "$(< ~/.t)" = day ]] && printf "\033[31m" || printf "\033[34m")
reset=$(printf "\033[0m")
. /etc/os-release
k=$(uname -r)
s=$(< /proc/uptime)
s=${s%%.*}
d=$((s/86400))
h=$((s/3600%24))
m=$((s/60%60))
[ $d = 0 ] || u="${u}${d}d "
[ $h = 0 ] || u="${u}${h}h "
[ $m = 0 ] || u="${u}${m}m"

while IFS=: read -r a b
do
	b=${b%kB}
	case $a in
	MemTotal)
		x=$((x+=b))
		t=$((t=b));;
	Shmem)
		x=$((x+=b)) ;;
	MemFree|Buffers|Cached|SReclaimable)
		x=$((x-=b));;
	esac;
done < /proc/meminfo

x=$((x/=1024))
t=$((t/=1024))

cat <<EOF
${label}${logo[0]} OS       ${reset}${PRETTY_NAME/Linux/}
${label}${logo[1]} PKG      ${reset}$(pacman -Q | wc -l)
${label}${logo[2]} UPTIME   ${reset}$u
${label}${logo[3]} EDITOR   ${reset}${EDITOR:-?}
${label}${logo[4]} SHELL    ${reset}${SHELL##*/}
${label}${logo[5]} MEMORY   ${reset}${x}/${t}
${label}${logo[6]} KERNEL   ${reset}${k%%-arch*}
EOF
