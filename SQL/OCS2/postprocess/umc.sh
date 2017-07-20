#!/bin/bash

SOURCE_SCHEMA=$1
WORK_SCHEMA=$2
TILEID=$3
FLAGS=

psql <<EOF

	DROP SCHEMA IF EXISTS $WORK_SCHEMA CASCADE;
	CREATE SCHEMA $WORK_SCHEMA;

EOF

psql <<EOF

	CREATE TABLE $WORK_SCHEMA.pre_umc AS
	WITH
	infra AS (
		SELECT tileid, (st_dump(st_union(geom))).geom, max(nature) AS nature
		FROM $SOURCE_SCHEMA.carto
		WHERE tileid = $TILEID AND nature IN ('INFRA', 'AUTRE/INFRA')
		GROUP BY tileid
	),
	parts AS (
		SELECT tileid, nature, geom
		FROM infra
		UNION ALL
		SELECT tileid, nature, geom
		FROM $SOURCE_SCHEMA.carto
		WHERE tileid = $TILEID AND nature NOT IN ('INFRA', 'AUTRE/INFRA')
	)
	SELECT row_number() over() AS gid, nature, st_area(geom) AS area, geom, tileid
	FROM parts ;

EOF

v.in.ogr $FLAGS min_area=0.0001 snap=0.001 --overwrite -o -e \
input="PG:dbname=fdca user=postgres host=localhost password=sigibi" \
layer=$WORK_SCHEMA.pre_umc where="tileid=$TILEID" output=ocsol

v.clean $FLAGS --overwrite input=ocsol output=cleaned tool=rmarea threshold=2500

v.out.postgis $FLAGS -2 in=cleaned output="PG:dbname=fdca user=postgres host=localhost password=sigibi" \
type=area output_layer=$WORK_SCHEMA.umc

psql <<EOF

	INSERT INTO $SOURCE_SCHEMA.carto_umc (nature, area, geom, tileid)
	SELECT trim(nature)::ocs_nature, st_area(geom) as area, geom, tileid
	FROM $WORK_SCHEMA.umc ;

EOF