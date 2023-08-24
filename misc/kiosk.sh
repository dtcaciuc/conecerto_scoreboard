#!/bin/bash

# IP of the timing laptop running scoreboard
SERVERURL=http://192.168.0.2

xset s noblank
xset s off
xset -dpms

echo Looking for $SERVERURL
while [[ ! `curl -Is $SERVERURL` =~ '200 OK' ]]; do
	echo Still looking...
	sleep 5
done
echo Server found

chromium-browser \
	--kiosk \
	--noerrdialogs \
	--disable-infobars \
	--app $SERVERURL/tv
