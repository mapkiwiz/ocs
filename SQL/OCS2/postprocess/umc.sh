#!/bin/bash

SOURCE_SCHEMA=$1
WORK_SCHEMA=$2
TILEID=$3
FLAGS=

psql <<EOF

	DROP SCHEMA IF EXISTS $WORK_SCHEMA CASCADE;
	CREATE SCHEMA $WORK_SCHEMA;

EOF

v.in.ogr $FLAGS min_area=0.0001 snap=0.001 --overwrite -o -e \
input="PG:dbname=fdca user=postgres host=localhost password=sigibi" \
layer=$SOURCE_SCHEMA.carto_pre_umc where="tileid=$TILEID" output=ocsol

v.clean $FLAGS --overwrite input=ocsol output=cleaned tool=rmarea threshold=2500

v.out.postgis $FLAGS -2 in=cleaned output="PG:dbname=fdca user=postgres host=localhost password=sigibi" \
type=area output_layer=$WORK_SCHEMA.cleaned

psql <<EOF

	INSERT INTO $SOURCE_SCHEMA.carto_umc (nature, area, geom, tileid)
	SELECT trim(nature)::ocs_nature, st_area(geom) as area, geom, tileid
	FROM $WORK_SCHEMA.cleaned ;

EOF