# randomize-desktop-wallpaper

Script which allow Linux users to fetch images from Google and set as their desktop wallpaper periodically.

## Prerequisite

As of 2024, you'll be needing to use Google [https://developers.google.com/custom-search/v1](Custom Search JSON API) as the old engine doesn't give the direct URL anymore.

As consequence, you need to prepare 2 keys in order for this project to work.

- Custom Search Engine ID
- An API Key

## Install

Run `bash install.sh`.

This script will download dependancies, ask for configurations and install a CRON service to run it periodically. You can always change the configs later by changing arguments in file `/etc/cron.d/randomize-desktop`.

## Documentation

Syntax: `bash randomizedesktop.sh keyword [--quality value] [--color value]`

Manual run to test this app. The final options should be configured in CRON

#### Argument

`keyword` Required keyword for the images

#### Options

`--quality auto|high|medium|ge:N|eq:W,H` Set the quality of the image. Auto by default : use the user screen width/height as reference.

-   `ge:N` (greater than) is to search images which size is bigger than N megapixels e.g `--quality "ge:2"`
-   `eq:W,H` (equal) is to search images with a specific Width and Height e.g `--quality "eq:1920,1080"`

`--color colorname` filter only image with color _colorname_ ie blue|green|red.. etc.
`--color color` filter only colored image
`--color grayscale` filter only grayscale image
`--color transparent` filter only transparent image
