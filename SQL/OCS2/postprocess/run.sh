#!/bin/bash

DEPARTEMENT=$1
WORK_SCHEMA=$2
WORK_DIR=/tmp/ocs

function tiles {

	psql -At -F " " <<EOF
WITH tiles AS (
	SELECT gid FROM ocs.grid_ocs
	WHERE dept = '$DEPARTEMENT'
	AND EXISTS (
		SELECT gid
		FROM ocs.carto_raw
		WHERE tileid = grid_ocs.gid
	)
	AND NOT EXISTS (
		SELECT gid
		FROM ocs.carto
		WHERE tileid = grid_ocs.gid
	)
	ORDER BY gid
)
SELECT row_number() over() AS i, (SELECT count(*) FROM tiles) AS n, gid
FROM tiles;
EOF

}

tiles | while read i n t;
do

	echo "Cleaning tile $i / $n"
	if [ -d $WORK_DIR/$WORK_SCHEMA ]; then
		rm -rf $WORK_DIR/$WORK_SCHEMA
	fi
	mkdir -p $WORK_DIR/$WORK_SCHEMA
	grass -c EPSG:2154 $WORK_DIR/$WORK_SCHEMA/grass --exec $(pwd)/clean.sh $WORK_SCHEMA $t

done