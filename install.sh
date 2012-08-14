#!/bin/sh
cp unicorn.init /etc/init.d/unicorn
mkdir -p /etc/unicorn
cp unicorn_gitlab.conf /etc/unicorn
update-rc.d unicorn defaults
