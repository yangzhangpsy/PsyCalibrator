#! /bin/bash
# Written by Yang Zhang 20210407 
# See details in https://www.argyllcms.com/doc/Installing_Linux.html
cd "$(dirname "$0")"

# for os systems include Gnome Color Manager. which comes with a udev rule for color instruments
if [ -f "/etc/udev/rules.d/69-cd-sensors.rules"] | [ -f "/usr/lib/udev/rules.d/69-cd-sensors.rules"]; then
    sudo usermod -a -G colord $USER
else
    if [ ! -d "/etc/udev/rules.d" ]; then
        cp -f ./55-Spyder.rules /etc/udev/rules.d/55-Spyder.rules
    else
        cp -f ./55-Spyder.rules /usr/lib/udev/rules.d/55-Spyder.rules
    fi
fi

