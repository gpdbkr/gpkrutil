#!/bin/bash
source ~/.bashrc

## source: https://knowledge.broadcom.com/external/article?articleNumber=384786

## Query the gp_segment_configuration table to list all hosts:
psql -c "SELECT DISTINCT hostname FROM gp_segment_configuration" postgres -t -A > host

## Checking the number of CPU cores on each host.
gpssh -f host "ls /sys/devices/system/cpu/cpu*/topology/core_cpus | xargs cat | sort | uniq | wc -l" > perhost
cat perhost

## Sum the results across all hosts
awk '{sum+=$NF;} END{print "Total cores of Greenplum cluster: " sum;}' perhost

