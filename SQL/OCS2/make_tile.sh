#!/bin/bash

SCHEMA=$1
CELLID=$2
WORKING_DIR=/tmp/ocs
FLAGS=-q

echo "Using schema $SCHEMA"
echo "Processing cell $CELLID ..."

psql $FLAGS <<EOF

SET client_min_messages TO WARNING;

DROP SCHEMA IF EXISTS $SCHEMA CASCADE;
CREATE SCHEMA $SCHEMA;

CREATE TABLE $SCHEMA.grid_ocs AS
SELECT 1 AS gid, geom
FROM ocs.grid_ocs
WHERE gid = $CELLID;

EOF

if [ -d $WORKING_DIR/$SCHEMA ]; then
	rm -rf $WORKING_DIR/$SCHEMA
fi

mkdir -p $WORKING_DIR/$SCHEMA
mkdir $WORKING_DIR/$SCHEMA/functions
mkdir $WORKING_DIR/$SCHEMA/steps

ls functions/*.sql |
while read f; do

	echo "SET search_path = $SCHEMA, ocs, public;" > $WORKING_DIR/$SCHEMA/$f
	echo "SET client_min_messages TO WARNING;" >> $WORKING_DIR/$SCHEMA/$f
	echo >> $WORKING_DIR/$SCHEMA/$f
	cat $f >> $WORKING_DIR/$SCHEMA/$f

done

ls steps/*.sql |
while read f; do

	echo "SET search_path = $SCHEMA, ocs, public;" > $WORKING_DIR/$SCHEMA/$f
	echo "SET client_min_messages TO WARNING;" >> $WORKING_DIR/$SCHEMA/$f
	echo >> $WORKING_DIR/$SCHEMA/$f
	cat $f >> $WORKING_DIR/$SCHEMA/$f

done

ls $WORKING_DIR/$SCHEMA/functions/*.sql |
while read f; do

	psql $FLAGS -f $f

done

ls $WORKING_DIR/$SCHEMA/steps/*.sql |
while read f; do

	echo Running step $f
	psql $FLAGS -f $f

done

psql $FLAGS <<EOF

	SET client_min_messages TO WARNING;

	DELETE FROM ocs.carto_raw
	WHERE tileid = $CELLID;

	INSERT INTO ocs.carto_raw (nature, tileid, geom, area)
	SELECT nature::ocs_nature, $CELLID AS tileid, geom, st_area(geom) AS area
	FROM $SCHEMA.ocsol
	WHERE ST_GeometryType(geom) = 'ST_Polygon';

EOF