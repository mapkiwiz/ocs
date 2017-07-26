#!/bin/bash

FLAGS=--quiet
SCHEMA=$1
TILEID=$2

psql <<EOF

	DROP SCHEMA IF EXISTS $SCHEMA CASCADE;
	CREATE SCHEMA $SCHEMA;

EOF

v.in.ogr $FLAGS min_area=0.0001 snap=0.001 --overwrite -o -e \
input="PG:dbname=fdca user=postgres host=localhost password=sigibi" \
layer=ocs.grid_ocs where="gid=$TILEID" type=boundary output=tile

v.in.ogr $FLAGS min_area=0.0001 snap=0.001 --overwrite -o -r \
input="PG:dbname=fdca user=postgres host=localhost password=sigibi" \
layer=ocs.carto_umc where="tileid=$TILEID" type=boundary output=objs

v.overlay $FLAGS --overwrite ainput=tile atype=area binput=objs btype=area operator=not snap=.001 output=missing

v.db.renamecolumn missing column=b_nature,nature
v.db.renamecolumn missing column=b_area,area
v.db.renamecolumn missing column=b_tileid,tileid
v.db.dropcolumn missing columns=a_cat,a_dept,a_geohash,a_boundary,b_cat
# v.db.addcolumn missing column=nat
# v.db.update missing column=nat query_column=nature
v.db.dropcolumn missing column=nature
# v.db.renamecolumn missing column=nature
v.db.addcolumn missing column=nature
v.db.update missing column=nature value='AUTRE/?'
v.db.update missing column=tileid value=$TILEID
v.to.db missing column=area option=area

v.db.addcolumn objs column=nat
v.db.update objs column=nat query_column=nature
v.db.dropcolumn objs column=nature
v.db.renamecolumn objs column=nat,nature

v.patch $FLAGS --overwrite -e input=missing,objs output=patched

v.clean $FLAGS --overwrite input=patched output=cleaned tool=break,rmdupl,rmdac

v.out.postgis $FLAGS -2 in=cleaned \
output="PG:dbname=fdca user=postgres host=localhost password=sigibi" \
type=area output_layer=$SCHEMA.patched

psql <<EOF

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
	         ON trim(a.nature) = b.nature::text
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
