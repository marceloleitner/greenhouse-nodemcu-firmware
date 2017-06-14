#!/bin/bash

graph_merged()
{
    stamp=now-${1:-2h}
    output=merged-${1:-2h}
    rrdtool graph \
	--end now --start $stamp --width 800 --height 300 \
	$output.png \
	DEF:ds0a=greenhouse_temperature.rrd:greenhouse_temperature:AVERAGE \
	LINE1:ds0a#0000FF:"Greenhouse temperature\l" \
	DEF:ds0b=greenhouse_humidity.rrd:greenhoue_humidity:AVERAGE \
	DEF:ds0c=solution_temperature.rrd:solution_temperature:AVERAGE \
	LINE1:ds0b#00CCFF:"Greenhouse humidity\l" \
	LINE1:ds0c#FF00FF:"Solution temperature\l"
}

graph()
{
    stamp=now-${2:-2h}
    output=$1-${2:-2h}
    rrdtool graph \
	--end now --start $stamp --width 800 --height 300 \
	$output.png \
	DEF:ds0a=$1.rrd:$1:AVERAGE \
	LINE1:ds0a#0000FF:"default resolution\l" \
	DEF:ds0b=$1.rrd:$1:AVERAGE:step=1800 \
	DEF:ds0c=$1.rrd:$1:AVERAGE:step=7200 \
	LINE1:ds0b#00CCFF:"resolution 1800 seconds per interval\l" \
	LINE1:ds0c#FF00FF:"resolution 7200 seconds per interval\l"
}

#graph greenhouse_temperature
#graph greenhouse_humidity
#graph solution_temperature

#graph greenhouse_temperature 1d
#graph greenhouse_humidity 1d
#graph solution_temperature 1d

# Instead of plotting one graph for each measurement, lets plot it all
# on the same graph. Though for those who want, can still plot them
# individually with the code above.
graph_merged 1d
graph_merged 7d
graph_merged 14d

