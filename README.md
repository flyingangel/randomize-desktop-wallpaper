# randomize-desktop-wallpaper
Run `randomizedesktop.sh`

## Install
Run `bash install.sh`. 

This script will download dependancies, ask for configurations and install a CRON service to run it periodically. You can always change the configs later `nano /etc/cron.d/randomize-desktop`

## Documentation
Syntax: `bash randomizedesktop.sh keyword [--quality value]`

Manual run to test this app. The final options should be configured in CRON


#### Argument
`keyword`  
Required keyword for the images

#### Options
`--quality auto|high|medium|ge:N|eq:W,H`  
`--color colourname`  
Set the quality of the image. Auto by default : use the user screen width/height as reference.  
`ge:N` (greater than) is to search images which size is bigger than N megapixels e.g `--quality "ge:2"`
`eq:W,H` (equal) is to search images with a specific Width and Height e.g `--quality "eq:1920,1080"`
