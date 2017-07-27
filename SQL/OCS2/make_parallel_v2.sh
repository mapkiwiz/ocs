#!/bin/bash

SCHEMA=work
TIMER_OUTPUT="/tmp/ocs/times.txt"
TIMER_FORMAT="%C \treal %E\t user %U\tsys %S\tstatus %x"
TIMER="/usr/bin/time -o $TIMER_OUTPUT --append"

function tiles {

	GROUP=$1

	psql -At -F " " <<EOF
WITH
groups AS (
	SELECT gid AS tileid, (gid % 8) AS gr FROM ocs.grid_ocs
	WHERE dept IN ('SAVOIE', 'HAUTE-SAVOIE')
	ORDER BY dept, random()
),
tiles AS (
	SELECT tileid FROM groups
	WHERE gr = $GROUP
	AND NOT EXISTS (
		SELECT gid
		FROM ocsv2.carto_clc
		WHERE tileid = groups.tileid
		LIMIT 1
	)
)
SELECT row_number() over() AS i, (SELECT count(*) FROM tiles) AS n, tileid
FROM tiles;
EOF

}

function make_group {

	GROUP=$1

	tiles $GROUP | while read i n t;
	do
	    echo "Group $GROUP Tile $i / $n"
	    $TIMER -f '%C \treal %E\t user %U\tsys %S\tstatus %x' ./make_tile_v2.sh "$i/$n" $SCHEMA$GROUP $t 2>&1 > /dev/null
	done

	echo "Group $GROUP done."

}

# Example usage :
#
mkdir -p /tmp/ocs
for i in {0..7};
do
	make_group $i &
done

# kill command
# killall make_controls.sh make_tile_v2.sh psql