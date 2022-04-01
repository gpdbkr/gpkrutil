#!/bin/sh

# source
source ~/.bashrc

## statlog(7 days)
find $STATLOGDIR -mtime +7 -print -exec mv -f {} $STATLOGBACKUPDIR \;
