#!/bin/bash

source ~/.bashrc

find ${STATLOG}/*.txt.gz -mtime +30 -exec /bin/rm -f '{}' \;
find ${STATLOG}/*.txt -mtime +10 -exec /bin/gzip '{}' \;
