#!/bin/bash

DEP=$1

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
	ORDER BY gid
)
SELECT row_number() over() AS i, (SELECT count(*) FROM tiles) AS n, gid
FROM tiles;
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
	    echo "Group $GROUP Tile $i / $n"
	    ./make_tile.sh work$GROUP $t 2>&1 > /tmp/ocs/026_G$GROUP.log
	done

	echo "Group $GROUP done."

}

# Example usage :
#
mkdir -p /tmp/ocs
for i in {0..7};
do
	make_group $DEP 7 $i &
done