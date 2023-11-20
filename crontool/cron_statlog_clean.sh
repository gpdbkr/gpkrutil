#!/bin/bash

source ~/.bashrc

find /data/utilities/statlog/*.txt.gz -mtime +30 -exec /bin/rm -f '{}' \;
find /data/utilities/statlog/*.txt -mtime +10 -exec /bin/gzip '{}' \;
