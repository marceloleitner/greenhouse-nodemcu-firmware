#!/bin/bash
#
# Use to initiallize the .rrd files, one for each
#

create()
{
rrdtool create $1.rrd \
   --start now-2h --step 5m \
   DS:$1:GAUGE:10m:$2:$3 \
   RRA:AVERAGE:0.5:1:10d \
   RRA:AVERAGE:0.5:1h:18M \
   RRA:AVERAGE:0.5:1d:10y
}

create greenhouse_temperature -10 60
create greenhouse_humidity 0 100
create solution_temperature -10 60
