#!/bin/bash

DEP=$1

function tiles {

	DEPARTEMENT=$1
	NGROUPS=$2
	GROUP=$3

	psql -At -F " " <<EOF
WITH
groups AS (
	SELECT gid, (gid % $NGROUPS) AS gr FROM ocs.grid_ocs
	WHERE dept = '$DEPARTEMENT'
	ORDER BY gid
),
tiles AS (
	SELECT gid FROM groups
	WHERE gr = $GROUP
	AND NOT EXISTS (
		SELECT gid
		FROM ocs.carto_raw
		WHERE tileid = groups.gid
	)
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
	make_group $DEP 8 $i &
done