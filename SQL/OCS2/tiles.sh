#!/bin/bash

function tiles {

	DEPARTEMENT=$1
	NGROUPS=$2
	GROUP=$3

	psql -At -F " " <<EOF
WITH tiles AS (
	SELECT gid FROM ocs.grid_ocs
	WHERE dept = '$DEPARTEMENT' AND (gid+$GROUP) % $NGROUPS = 0
	AND NOT EXISTS (
		SELECT gid
		FROM ocs.carto_raw
		WHERE tile_id = grid_ocs.gid
	)
)
SELECT row_number() over() AS i, (SELECT count(*) FROM tiles) AS n, gid
FROM tiles;
EOF

}

# Example usage :
#
export PGHOST=localhost
export PGDATABASE=fdca
export PGUSER=postgres
tiles HAUTE-SAVOIE 4 3 | while read i n t;
do
    echo "Tile $i / $n"
    ./make_tile.sh work3 $t
done