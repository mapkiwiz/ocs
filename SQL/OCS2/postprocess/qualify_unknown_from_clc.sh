#!/bin/bash

SCHEMA=$1
TILEID=$2
FLAGS=--quiet

psql <<EOF

	DROP SCHEMA IF EXISTS $SCHEMA CASCADE;
	CREATE SCHEMA $SCHEMA;

	CREATE TABLE $SCHEMA.autre_clc AS
	SELECT * FROM ocs.autre_clc_069
	WHERE tileid = $TILEID;

EOF

v.in.ogr $FLAGS min_area=0.0001 snap=0.001 --overwrite -o -e input="PG:dbname=fdca user=postgres host=localhost password=sigibi" \
layer=$SCHEMA.autre_clc output=autre_clc
v.clean $FLAGS --overwrite input=autre_clc output=autre_clc_cleaned tool=rmarea threshold=2500
v.out.postgis $FLAGS -2 in=autre_clc_cleaned output="PG:dbname=fdca user=postgres host=localhost password=sigibi" type=area \
output_layer=$SCHEMA.autre_clc_cleaned

psql <<EOF

	INSERT INTO ocs.autre_clc_cleaned (code_12, geom, tileid)
	SELECT code_12, geom, $TILEID AS tileid
	FROM $SCHEMA.autre_clc_cleaned;

EOF
