#!/bin/bash

SCHEMA=$1
TILEID=$2
WORKING_DIR=/tmp/ocs
FLAGS=

function copy_scripts {

	SCRIPT_DIR=$1

	mkdir $WORKING_DIR/$SCHEMA/$SCRIPT_DIR

	ls $SCRIPT_DIR/*.sql |
	while read f; do

		echo "SET search_path = $SCHEMA, public;" > $WORKING_DIR/$SCHEMA/$f
		echo "SET client_min_messages TO WARNING;" >> $WORKING_DIR/$SCHEMA/$f
		echo >> $WORKING_DIR/$SCHEMA/$f
		cat $f >> $WORKING_DIR/$SCHEMA/$f

	done

}

function run_scripts {

	SCRIPT_DIR=$1

	ls $WORKING_DIR/$SCHEMA/$SCRIPT_DIR/*.sql |
	while read f; do

		echo Running step $f
		psql $FLAGS -f $f

	done

}

function run_postprocess {

	mv $WORKING_DIR/$SCHEMA/postprocess_v2 $WORKING_DIR/$SCHEMA/postprocess
	rm -rf $WORKING_DIR/$SCHEMA/grass
	grass -c EPSG:2154 $WORKING_DIR/$SCHEMA/grass --exec $(pwd)/postprocess_v2/postprocess.sh $SCHEMA $TILEID

}

function setup {

	psql $FLAGS <<EOF

SET client_min_messages TO WARNING;

DROP SCHEMA IF EXISTS $SCHEMA CASCADE;
CREATE SCHEMA $SCHEMA;

CREATE TABLE $SCHEMA.grid_ocs AS
SELECT 1 AS gid, $TILEID AS tileid, geom
FROM ocs.grid_ocs
WHERE gid = $TILEID;

EOF

	if [ -d $WORKING_DIR/$SCHEMA ]; then
		rm -rf $WORKING_DIR/$SCHEMA
	fi

	mkdir -p $WORKING_DIR/$SCHEMA

}

function copy_results {

	psql <<EOF

	SET client_min_messages TO WARNING;
	SET search_path = $SCHEMA, public;

	DELETE FROM ocsv2.simplified
	WHERE tileid = $TILEID;

	INSERT INTO ocsv2.simplified (tileid, geom, nature)
	SELECT $TILEID AS tileid, geom, trim(nature)::ocsv2.ocs_nature
	FROM simplified;

	DELETE FROM ocsv2.carto_clc
	WHERE tileid = $TILEID;

	INSERT INTO ocsv2.carto_clc (tileid, geom, nature, code_clc)
	SELECT $TILEID AS tileid, geom, nature, code_clc
	FROM carto_clc;

EOF

}

echo "Using schema $SCHEMA"
echo "Processing tile $TILEID ..."

setup

copy_scripts functions
copy_scripts steps_v2
copy_scripts postprocess_v2
copy_scripts finalize
copy_scripts validation

run_scripts functions
run_scripts steps_v2
run_postprocess

copy_results