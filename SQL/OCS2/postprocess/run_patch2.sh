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
		FROM ocs.carto_umc
		WHERE tileid = grid_ocs.gid
		LIMIT 1
	)
	AND NOT EXISTS (
		SELECT gid
		FROM ocs.carto_clc
		WHERE tileid = grid_ocs.gid
		LIMIT 1
	)
	ORDER BY gid
)
SELECT row_number() over() AS i, (SELECT count(*) FROM tiles) AS n, gid
FROM tiles;
EOF

}

tiles | while read i n t;
do

	echo "Qualifying unknown surface for tile $i / $n"
	if [ -d $WORK_DIR/$WORK_SCHEMA ]; then
		rm -rf $WORK_DIR/$WORK_SCHEMA
	fi
	mkdir -p $WORK_DIR/$WORK_SCHEMA
	grass -c EPSG:2154 $WORK_DIR/$WORK_SCHEMA/grass --exec $(pwd)/patch2.sh $WORK_SCHEMA $t

done