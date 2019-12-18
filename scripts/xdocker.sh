#!/bin/sh

# this runs an x application in docker.
# usefull if nix mucks up (fallback to ubuntu)
# https://github.com/mviereck/x11docker/wiki/Container-sound:-ALSA-or-Pulseaudio
# https://github.com/NixOS/nixpkgs/blame/05aa59afa639c188e82e565b63976fa69a7a51a6/nixos/modules/config/pulseaudio.nix#L198
# http://fabiorehm.com/blog/2014/09/11/running-gui-apps-with-docker/
docker run -v /tmp/.X11-unix:/tmp/.X11-unix -v /home/jappie:/home/jappie --device /dev/snd -e ALSA_CARD=Generic --env PULSE_SERVER=tcp:172.17.0.1:4713 -it ubuntu-blender
