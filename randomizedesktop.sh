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

#Usage: bash randomizedesktop.sh "keyword"

DEBUG=true

function isGNOME {
    [ -x "$(command -v gsettings)" ] || return 1
}

function isPLASMA {
    #todo
    return 1
}

function checkCompatibility {
    if isGNOME; then
        result="GNOME"
        
        elif isPLASMA; then
        result="PLASMA"
    else
        echo "Unsupported system. This program requires Gnome desktop"
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
    link="www.google.com/search?q=${keyword}&tbm=isch"
    imagelink=$(wget -e robots=off --user-agent "$useragent" -qO - "$link" | sed 's/</\n</g' | grep 'class="*rg_meta' | sed 's/">{"/">\n{"/g' | grep 'http' | head -n $count)
    
    IFS=$'\n'
    for i in $imagelink; do
        resultArray+=("$i")
    done
}

#return images list as array
function fetchImages {
    local temp url
    
    fetchImageAsJSON
    
    images=()
    
    #get url from JSON
    for i in "${resultArray[@]}"; do
        #fetch json key & value
        temp=$(echo "$i" | sed 's/\\\\\//\//g' | sed 's/[{}]//g' | awk -v k="text" '{n=split($0,a,","); for (i=1; i<=n; i++) print a[i]}' | sed 's/\"\:\"/\|/g' | sed 's/[\,]/ /g' | sed 's/\"//g' | grep -w "ou")
        #fetch value
        url=${temp##*|}
        images+=("$url")
        
        if $DEBUG; then echo "Found $url"; fi
    done
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
    fi
    
    if $DEBUG; then echo "Set $1 as background"; fi
}


checkCompatibility || exit 1
#fetch image return array of images
fetchImages
pickRandomImage
setDesktopBackground "$result"