#!/bin/sh
# date en legende de planche : jour, quantieme, mois, puis l'heure apres un point median
sketchybar --set "$NAME" icon=󰥔 label="$(date '+%a %d %b · %H:%M')"
