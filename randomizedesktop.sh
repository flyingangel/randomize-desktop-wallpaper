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

source argparser/argparser.sh
parse_args "$@"

function isGNOME {
  [[ $XDG_CURRENT_DESKTOP == GNOME ]] || [[ $XDG_CURRENT_DESKTOP == ubuntu:GNOME ]] || return 1
}

function isPLASMA {
  [[ $XDG_CURRENT_DESKTOP == KDE ]] || return 1
}

function reconf() {
  readonly output=/tmp/plasma-org.kde.plasma.desktop-appletsrc
  readonly config=~/.config/plasma-org.kde.plasma.desktop-appletsrc
  [[ ! -e $output ]] || rm $output
  while IFS= read line
  do
      if [[ $line != "Image=file://"* ]]; then
        echo $line >> $output
      else
        rm ${line#*Image=file://}
        echo "$1" >> $output
      fi
  done <"$config"
  rm $config && mv $output ~/.config
  kquitapp5 plasmashell
  kstart plasmashell
}

function setPlasmaWall {
  wget --directory-prefix=$HOME/.cache $1 2>/dev/null
  wall=~/.cache/"${1##*/}"
  reconf "Image=file://$wall"
}

function checkCompatibility {
  if ! isGNOME && ! isPLASMA; then
    echo "Unsupported DE. This program requires GNOME 3 or Plasma 5."
    return 1
  fi
}

#fetch image from google
function fetchImageAsJSON {
  resultArray=()

  count=10
  keyword="universe"
  #todo convert space to url entities
  useragent='Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:62.0) Gecko/20100101 Firefox/62.0'
  [[ ! -z $1 ]] && link="www.google.com/search?q=${keyword}&tbs=isz:ex,iszw:$1,iszh:$2&tbm=isch" || link="www.google.com/search?q=${keyword}&tbm=isch"
  imagelink=$(wget -e robots=off --user-agent "$useragent" -qO - "$link" | sed 's/</\n</g' | grep 'class="*rg_meta' | sed 's/">{"/">\n{"/g' | grep 'http' | head -n $count)

  IFS=$'\n'
  for i in $imagelink; do
    resultArray+=("$i")
  done
}

#return images list as array
function fetchImages {
  local temp url

  fetchImageAsJSON $1 $2

  images=()

  #get url from JSON
  for i in "${resultArray[@]}"; do

    #fetch json key & value
    temp=$(echo "$i" | sed 's/\\\\\//\//g' | sed 's/[{}]//g' | awk -v k="text" '{n=split($0,a,","); for (i=1; i<=n; i++) print a[i]}' | sed 's/\"\:\"/\|/g' | sed 's/[\,]/ /g' | sed 's/\"//g' | grep -w "ou")
    #fetch value
    url=${temp##*|}
    [[ $url =~ "?" ]] && images+=("${url%%"?"*}") || images+=("$url")

    if $DEBUG; then echo "Found $url"; fi
  done
}

function getScreenRes {
  read res < <(cat /sys/class/graphics/fb0/virtual_size);
  local w="${res%%,*}"
  local h="${res#*,}"
  fetchImages $w $h
}

function pickRandomImage {
  local size index

  size=${#images[@]}
  index=$((RANDOM % "$size"))
  result=${images[$index]}
}

function setDesktopBackground {
  if isGNOME; then
    gsettings set org.gnome.desktop.background picture-uri "$1"
  elif isPLASMA; then
    setPlasmaWall "$1"
  fi

  if $DEBUG; then echo "Set $1 as background"; fi
}

checkCompatibility || exit 1
#fetch image return array of images
[[ -z $quality ]] && [[ -z $bestfit ]] && getScreenRes || fetchImages
pickRandomImage
setDesktopBackground "$result"
