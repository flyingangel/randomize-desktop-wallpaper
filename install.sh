#!/usr/bin/env bash

#check root right
[[ $(id -u) -ne 0 ]] && echo "Please run as root" && exit 1

#set working dir
currentDir=$(dirname -- $(realpath $0))
cd $currentDir

function askKeyword() {
	read -r -p "Choose a keyword: " keyword

	[[ -z $keyword ]] && echo "Empty keyword. Exiting now." && exit 1
}

function askQuality() {
	local resolution
	declare -a qualities

	qualities+=("auto")
	qualities+=("high")
	qualities+=("medium")
	qualities+=("ge:")
	qualities+=("eq:")

	question=$(
		cat <<EOF
Choose the image quality:
1   auto        Image will be greater or equal than your screen resolution (default)
2   high        High quality image
3   medium      Medium quality image
4   greater     Greater than a chosen size
5   equal       Exactly equal a chosen size
>
EOF
	)
	read -r -p "$question" quality
	echo

	#default to quality 1
	[[ -z $quality ]] && quality=1

	if [[ $quality -eq 4 || $quality -eq 5 ]]; then
		read -r -p "Choose a resolution (e.g 1920,1280): " resolution
	fi

	#empty string if quality auto
	[[ $quality -eq 1 ]] && quality="" || quality="--quality=${qualities[$quality - 1]}"
	quality="$quality$resolution"
}

function askInterval() {
	declare -a presets

	presets+=("*/15 * * * *")
	presets+=("*/30 * * * *")
	presets+=("*/60 * * * **")
	presets+=("0 0 * * *")
	presets+=("0 0 * * 0")

	question=$(
		cat <<EOF
Change image every:
1   15 minutes (default)
2   30 minutes
3   1 hour
4   1 day
5   1 week
>
EOF
	)
	read -r -p "$question" interval
	echo

	[[ -z $interval ]] && interval=1

	interval=${presets[$interval - 1]}
}

#install dependancy
git submodule update --init --recursive
askKeyword
askQuality
askInterval

user=$(whoami)

line="$interval\t$user\tbash $currentDir/randomizedesktop.sh $keyword $quality"
echo -e "$line" >/etc/cron.d/randomize-desktop
echo "Custom interval can be changed in /etc/cron.d/randomize-desktop"
echo "Done"
