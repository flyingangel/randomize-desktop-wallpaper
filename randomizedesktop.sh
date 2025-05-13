#!/usr/bin/env bash

# Copyright 2018-today Thanh Trung NGUYEN

# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at

#    http://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

#set folder of this script as root, necessary if script is not called from this folder
cd -P -- "$(dirname -- "$0")" || exit

source argparser/argparser.sh
parse_args "$@"
originalParam="$@"

function isGNOME() {
	[[ $XDG_CURRENT_DESKTOP == GNOME ]] || [[ $XDG_CURRENT_DESKTOP == ubuntu:GNOME ]] || hasGnomeShell || return 1
}

function hasGnomeShell() {
	gnomeshell=$(ps -a | grep gnome-shell)
	[[ -n $gnomeshell ]] && return 0 || return 1
}

function isPLASMA() {
	[[ $XDG_CURRENT_DESKTOP == KDE ]] || return 1
}

function reconf() {
	readonly output=/tmp/plasma-org.kde.plasma.desktop-appletsrc
	readonly config=~/.config/plasma-org.kde.plasma.desktop-appletsrc
	[[ ! -e $output ]] || rm $output
	while IFS= read line; do
		if [[ $line != "Image=file://"* ]]; then
			echo "$line" >>$output
		else
			[[ ${line#*Image=file://} =~ .cache ]] && rm "${line#*Image=file://}"*
			echo "$1" >>$output
		fi
	done <"$config"
	rm $config && mv $output ~/.config
	kquitapp5 plasmashell
	kstart plasmashell
}

function setPlasmaWall() {
	wget --directory-prefix="$HOME"/.cache "$1" 2>/dev/null
	wall=~/.cache/"${1##*/}"
	reconf "Image=file://$wall"
}

function checkCompatibility() {
	if ! isGNOME && ! isPLASMA; then
		echo "Unsupported DE. This program requires GNOME 3 or Plasma 5."
		return 1
	fi
}

#fetch image from google
function fetchImageAsJSON() {
	local url value
	local keyword=$1
	local quality=$2
	local color=$3
	local API_KEY="AIzaSyCHB4YuGiB2DRlz1tGfBak7otMVBapm8gg"
	local CX="e76a6e0aaee8c4f39"
	resultArray=()

	#the root URL
	url="https://www.googleapis.com/customsearch/v1?q=${keyword}&key=${API_KEY}&cx=${CX}&searchType=image"

	# Detect and set aspect ratio
	if [[ -n $4 ]]; then
		[[ ${4%%,*} -gt ${4#*,} ]] && r="&imgAspect=wide" || r="&imgAspect=tall"
		url+="$r"
	fi

	url+="&imgSize=${quality}"

	# Parse color param
	if [[ -n $color ]]; then
		if [[ $color == "color" ]]; then
			url+="&imgColorType=color"
		elif [[ $color == "grayscale" ]]; then
			url+="&imgColorType=gray"
		elif [[ $color == "transparent" ]]; then
			url+="&imgColorType=trans"
		else
			url+="&imgDominantColor=${color}"
		fi
	fi

	#if test mode, just display the url
	if [[ $TEST == true ]]; then
		echo -e "$0 $originalParam => $url"
		exit
	fi

	useragent='Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:62.0) Gecko/20100101 Firefox/62.0'
	#request to server
	cat <<EOF
Request: wget -e robots=off --user-agent "$useragent" -qO - "$url" | sed 's/</\n</g' | grep 'class="*rg_meta' | sed 's/">{"/">\n{"/g' | grep 'http'
EOF
	imagelink=$(wget -e robots=off --user-agent "$useragent" -qO - "$url" | sed 's/</\n</g' | grep 'class="*rg_meta' | sed 's/">{"/">\n{"/g' | grep 'http')

	#exit if 0 result
	[[ ! -z $imagelink ]] || return 1

	IFS=$'\n'
	for i in $imagelink; do
		resultArray+=("$i")
	done
}

#return images list as array
function fetchImages() {
	local temp url
	fetchImageAsJSON "$1" "$2" "$3" "$4"

	#return if fail
	[[ $? -eq 1 ]] && return 1

	images=()

	#get url from JSON
	for i in "${resultArray[@]}"; do
		#fetch json key & value
		temp=$(echo "$i" | sed 's/\\\\\//\//g' | sed 's/[{}]//g' | awk -v k="text" '{n=split($0,a,","); for (i=1; i<=n; i++) print a[i]}' | sed 's/\"\:\"/\|/g' | sed 's/[\,]/ /g' | sed 's/\"//g' | grep -w "ou")
		#fetch value
		url=${temp##*|}
		[[ $url =~ "?" ]] && url=${url%%"?"*}
		images+=("$url")
	done
}

function pickRandomImage() {
	local size index

	size=${#images[@]}
	index=$((RANDOM % "$size"))
	result=${images[$index]}
	# If url doesn't end in an image, TRY AGAIN FFS!!!!!!!!
	[[ ! $result =~ .*g$ ]] && pickRandomImage
}

function exportDBUS() {
	PID=$(pgrep gnome-session | head -n1)
	DBUS_SESSION_BUS_ADDRESS=$(grep -z DBUS_SESSION_BUS_ADDRESS /proc/"$PID"/environ | cut -d= -f2-)
	export DBUS_SESSION_BUS_ADDRESS
}

function setDesktopBackground() {
	if isGNOME; then
		exportDBUS &>/dev/null
		gsettings set org.gnome.desktop.background picture-uri "$1"
	elif isPLASMA; then
		setPlasmaWall "$1"
	fi
}

checkCompatibility || exit 1
if [[ -z $argument1 ]]; then
	echo "Missing param keyword"
	exit 1
fi

#autoset quality if mode auto
if [[ -z $quality || $quality == "auto" ]]; then
	#screen resolution
	read -r quality < <(cat /sys/class/graphics/fb0/virtual_size)
else
	read -r iar < <(cat /sys/class/graphics/fb0/virtual_size)
fi

fetchImages "${argument1// /+}" "$quality" "$color" "$iar"

#exit if 0 result
if [[ $? -eq 1 ]]; then
	echo "Found 0 images"
	exit 1
fi

pickRandomImage
setDesktopBackground "$result"
