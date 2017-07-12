#!/bin/bash

SCHEMA=$1
CELLID=$2
WORKING_DIR=/tmp/ocs

echo "Using schema $SCHEMA"
echo "Processing cell $CELLID ..."

psql <<EOF

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
	echo >> $WORKING_DIR/$SCHEMA/$f
	cat $f >> $WORKING_DIR/$SCHEMA/$f

done

ls steps/*.sql |
while read f; do

	echo "SET search_path = $SCHEMA, ocs, public;" > $WORKING_DIR/$SCHEMA/$f
	echo >> $WORKING_DIR/$SCHEMA/$f
	cat $f >> $WORKING_DIR/$SCHEMA/$f

done

ls $WORKING_DIR/$SCHEMA/functions/*.sql |
while read f; do

	psql -f $f

done

ls $WORKING_DIR/$SCHEMA/steps/*.sql |
while read f; do

	echo Running step $f
	psql -f $f

done