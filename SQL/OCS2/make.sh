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
		WHERE tileid = grid_ocs.gid
	)
)
SELECT row_number() over() AS i, (SELECT count(*) FROM tiles) AS n, gid
FROM tiles
ORDER BY gid;
EOF

}

function make_group {

	DEPARTEMENT=$1
	NGROUPS=$2
	GROUP=$3

	export PGHOST=localhost
	export PGDATABASE=fdca
	export PGUSER=postgres
	tiles $DEPARTEMENT $NGROUPS $GROUP | while read i n t;
	do
	    echo "Tile $i / $n"
	    ./make_tile.sh work$GROUP $t
	done

	echo "Group $GROUP done."

}

# Example usage :
#
mkdir -p /tmp/ocs
make_group SAVOIE 4 0 > /tmp/ocs/073_G0.log &
make_group SAVOIE 4 1 > /tmp/ocs/073_G1.log &
make_group SAVOIE 4 2 > /tmp/ocs/073_G2.log &
make_group SAVOIE 4 3 > /tmp/ocs/073_G3.log &