#!/usr/bin/env bash

export TEST=true

bash randomizedesktop.sh universe
bash randomizedesktop.sh universe --quality high
bash randomizedesktop.sh universe --quality medium
bash randomizedesktop.sh universe --quality ge:2
bash randomizedesktop.sh universe --quality eq:1920,1080
bash randomizedesktop.sh universe --color color
bash randomizedesktop.sh universe --color grayscale
bash randomizedesktop.sh universe --color transparent
bash randomizedesktop.sh universe --color green
bash randomizedesktop.sh universe --quality ge:2 --color green
