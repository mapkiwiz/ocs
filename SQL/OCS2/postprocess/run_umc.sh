#!/bin/bash

DEPARTEMENT=$1
WORK_SCHEMA=$2
SOURCE_SCHEMA=ocs
SRID="EPSG:2154"

function tiles {

	psql -At -F " " <<EOF
WITH tiles AS (
	SELECT gid FROM $SOURCE_SCHEMA.grid_ocs
	WHERE dept = '$DEPARTEMENT'
	AND EXISTS (
		SELECT gid
		FROM $SOURCE_SCHEMA.carto
		WHERE tileid = grid_ocs.gid
	)
	AND NOT EXISTS (
		SELECT gid
		FROM $SOURCE_SCHEMA.carto_umc
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

	echo "Collecting UMC for tile $i / $n"
	if [ -d /tmp/ocs/$WORK_SCHEMA/grass ]; then
		rm -rf /tmp/ocs/$WORK_SCHEMA/grass
	fi
	grass -c $SRID /tmp/ocs/$WORK_SCHEMA/grass --exec $(pwd)/umc.sh $SOURCE_SCHEMA $WORK_SCHEMA $t

done