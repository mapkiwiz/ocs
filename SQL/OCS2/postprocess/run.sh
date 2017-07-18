#!/bin/bash

function tiles {

	psql -At -F " " <<EOF
WITH tiles AS (
	SELECT gid FROM ocs.grid_ocs
	WHERE EXISTS (
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
	grass --exec $(pwd)/clean.sh work4 $t

done