#!/usr/bin/env bash

while true; do
	[[ -f /sys/devices/platform/applesmc.768//fan1_input ]] && \
	echo " $(cat /sys/devices/platform/applesmc.768//fan1_input) RPM"
	sleep 10
done
