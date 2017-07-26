#!/bin/bash

FLAGS=--quiet
SCHEMA=$1
TILEID=$2

psql <<EOF

	DROP SCHEMA IF EXISTS $SCHEMA CASCADE;
	CREATE SCHEMA $SCHEMA;

EOF

psql <<EOF

	CREATE TABLE $SCHEMA.patched AS
	WITH
	missing AS (
	    SELECT b.gid as tileid, (st_dump(st_difference(b.geom, st_union(a.geom)))).geom
	    FROM ocs.carto_umc a INNER JOIN ocs.grid_ocs b ON a.tileid = b.gid
	    WHERE a.tileid = $TILEID
	    GROUP BY b.gid
	)
	SELECT tileid, 'AUTRE/?'::ocs_nature as nature, geom FROM missing
	UNION ALL
	SELECT tileid, nature, geom FROM ocs.carto_umc WHERE tileid = $TILEID;

	CREATE TABLE $SCHEMA.autre_clc AS
	WITH autre_clc AS (
		SELECT b.code_12, a.tileid, (st_dump(st_intersection(b.geom, a.geom))).geom AS geom
		FROM $SCHEMA.patched a LEFT JOIN ref.clc_2012 b
		     ON st_intersects(a.geom, b.geom)
		WHERE a.nature IN ('AUTRE/NATURE', 'AUTRE/?')
	)
	SELECT * FROM autre_clc;

EOF

v.in.ogr $FLAGS min_area=0.0001 snap=0.001 --overwrite -o -e input="PG:dbname=fdca user=postgres host=localhost password=sigibi" \
layer=$SCHEMA.autre_clc output=autre_clc
v.clean $FLAGS --overwrite input=autre_clc output=autre_clc_cleaned tool=rmarea threshold=2500
v.out.postgis $FLAGS -2 in=autre_clc_cleaned output="PG:dbname=fdca user=postgres host=localhost password=sigibi" type=area \
output_layer=$SCHEMA.autre_clc_cleaned

psql <<EOF

	CREATE TABLE $SCHEMA.carto_clc AS
	WITH
	ocs AS (
	    SELECT a.tileid, a.geom, (a.nature::text)::ocs_nature_clc, b.code_clc
	    FROM $SCHEMA.patched a
	         LEFT JOIN ocs.nature_clc b
	         ON a.nature = b.nature
	    WHERE a.nature NOT IN ('AUTRE/NATURE', 'AUTRE/?')
	),
	clc AS (
	    SELECT a.tileid, a.geom, b.nature, a.code_12 AS code_clc
	    FROM $SCHEMA.autre_clc_cleaned a
	         LEFT JOIN ocs.code_clc b
	         ON a.code_12 = b.code_clc
	),
	ocs_and_clc AS (
	    SELECT * FROM ocs
	    UNION ALL
	    SELECT * FROM clc
	)
	SELECT row_number() over() AS gid, tileid, geom, nature, code_clc
	FROM ocs_and_clc;

	INSERT INTO ocs.carto_clc (tileid, geom, nature, code_clc)
	SELECT tileid, geom, nature, code_clc
	FROM $SCHEMA.carto_clc;

EOF
