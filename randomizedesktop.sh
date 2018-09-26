#!/usr/bin/env bash

# Copyright 2018-today Thanh Trung NGUYEN and Alice Charlotte Liddell

# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at

#    http://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

DEBUG=true

#necessary if script is not called from this folder
source argparser/argparser.sh
parse_args "$@"
originalParam="$@"

function isGNOME() {
	[[ $XDG_CURRENT_DESKTOP == GNOME ]] || [[ $XDG_CURRENT_DESKTOP == ubuntu:GNOME ]] || return 1
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
			echo $line >>$output
		else
			rm ${line#*Image=file://}*
			echo "$1" >>$output
		fi
	done <"$config"
	rm $config && mv $output ~/.config
	kquitapp5 plasmashell
	kstart plasmashell
}

function setPlasmaWall() {
	wget --directory-prefix=$HOME/.cache $1 2>/dev/null
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

	resultArray=()

	#the root URL
	url="www.google.com/search?q=$keyword&tbm=isch&tbs="

	#parse quality param
	if [[ $quality == "high" ]]; then
		url=$url"isz:l"
	elif [[ $quality == "medium" ]]; then
		url=$url"isz:m"
	elif [[ $quality == ge:* ]]; then
		#mp could be equal xga
		value=${quality#*ge:}
		#if is number
		[[ $value =~ ^[0-9]+$ ]] && value="${value}mp"

		url=$url"isz:lt,islt:$value"
	else
		value=${quality#*eq:}
		url=$url"isz:ex,iszw:${value%%,*},iszh:${value#*,}"
	fi

	#parse color param
	if [[ -n $color ]]; then
		if [[ $color == "color" ]]; then
			url="$url,ic:color"
		elif [[ $color == "grayscale" ]]; then
			url="$url,ic:gray"
		elif [[ $color == "transparent" ]]; then
			url="$url,ic:trans"
		else
			url="$url,ic:specific,isc:$color"
		fi
	fi

	#if test mode, just display the url
	if [[ $TEST == true ]]; then
		echo -e "$0 $originalParam => $url"
		exit
	fi

	$DEBUG && echo -e "URL (paste this on browser): $url\n"

	useragent='Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:62.0) Gecko/20100101 Firefox/62.0'
	#request to server
	wget=$(
		cat <<EOF
Request: wget -e robots=off --user-agent "$useragent" -qO - "$url" | sed 's/</\n</g' | grep 'class="*rg_meta' | sed 's/">{"/">\n{"/g' | grep 'http' | head -n $count
EOF
	)
	imagelink=$(wget -e robots=off --user-agent "$useragent" -qO - "$url" | sed 's/</\n</g' | grep 'class="*rg_meta' | sed 's/">{"/">\n{"/g' | grep 'http')
	$DEBUG && echo $wget && echo

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

	fetchImageAsJSON $1 $2 $3

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

		if $DEBUG; then echo -e "Found $url"; fi
	done
}

function pickRandomImage() {
	local size index

	size=${#images[@]}
	index=$((RANDOM % "$size"))
	result=${images[$index]}
}

function setDesktopBackground() {
	if isGNOME; then
		gsettings set org.gnome.desktop.background picture-uri "$1"
	elif isPLASMA; then
		setPlasmaWall "$1"
	fi

	$DEBUG && echo && echo "Set $1 as background"
}

checkCompatibility || exit 1
[[ ! -z $argument1 ]] || (echo "Missing param keyword" && exit 1)

#autoset quality if mode auto
if [[ -z $quality || $quality == "auto" ]]; then
	#screen resolution
	read -r quality < <(cat /sys/class/graphics/fb0/virtual_size)
fi

fetchImages "${argument1// /+}" $quality "$color"

#exit if 0 result
if [[ $? -eq 1 ]]; then
	echo "Found 0 images"
	exit 1
fi

pickRandomImage
setDesktopBackground "$result"
