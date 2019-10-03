#!/bin/sh

# a simple program to make screenshotted imagges look like they were printend and scanned
# this is to trick instutions you've signed papers rather than use gimp or photoshop.
# only becomes usefull if you have a bunch of screenshots to edit
# useage:
# ./printify.sh <filename> <numbering>
# for example:
#   ./printify.sh uea $(seq 1 14)
# which will look in the current folder for uea-1.jpg and create uea-print-1.jpg

set -xe

BLUR=1

# this actually reduces noise but looks legit.
for i in $2;
    do
    ANGLE=$(awk -v min=-2 -v max=2 'BEGIN{srand(); print int(min+rand()*(max-min+1))}')
    NOISE_REDUCTION=$(awk -v min=2 -v max=3 'BEGIN{srand(); print int(min+rand()*(max-min+1))}') # noise 0 is bad
    NOISE_ADDITION=$(awk -v min=0.5 -v max=1.0 'BEGIN{srand(); print min+rand()*(max-min)}') # noise 0 is bad

    convert $1-$i.jpg -rotate $ANGLE -attenuate $NOISE_ADDITION +noise Gaussian -noise $NOISE_REDUCTION -blur $BLUR $1-print-$i.jpg;
    done;

