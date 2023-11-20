#!/bin/bash
source /home/gpadmin/.bashrc

echo `hostname` `date "+%Y-%m-%d %H:%M:%S"` `grep Commit /proc/meminfo | awk '{print $1 " " $2}'`
