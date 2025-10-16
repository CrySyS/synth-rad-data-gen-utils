#!/bin/bash
SENSORNUM=5

for ((i=1; i <= SENSORNUM; i++));
do
  influx write     --bucket rds-test-bucket     --org rds-test-org     "rad_dr,id=$i rad_measurement=-1.0 $(date +%s%N)"
done
