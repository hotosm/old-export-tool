#!/bin/sh

NOW=`date +%s`

sleep 120 &

cd /home/hot/
exec >> log/update.log 2>&1

osmosis/bin/osmosis --rri var/osmosis-status-dir --simc --wxc var/diffs/$NOW.osc || exit 1

for i in var/extracts/*osm.pbf
do
	POLY=etc/polygons/`basename $i .osm.pbf`.poly
	if [ -f $POLY ]
	then
		osmosis/bin/osmosis --rxc var/diffs/$NOW.osc --read-pbf $i --ac --bp file=$POLY clipIncompleteEntities=true --write-pbf $i.new && mv $i.new $i
	fi
done

wait
