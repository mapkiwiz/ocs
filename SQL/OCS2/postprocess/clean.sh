#!/bin/bash

SCHEMA=$1
TILEID=$2

psql <<EOF

DROP SCHEMA IF EXISTS $SCHEMA CASCADE;
CREATE SCHEMA $SCHEMA;

EOF

g.proj -c proj4="+proj=lcc +lat_1=49 +lat_2=44 +lat_0=46.5 +lon_0=3 +x_0=700000 +y_0=6600000 +ellps=GRS80 +towgs84=0,0,0,0,0,0,0 +units=m +no_defs"
v.in.ogr min_area=0.0001 snap=0.001 --overwrite -o -e input="PG:dbname=fdca user=postgres host=localhost password=sigibi" \
layer=ocs.carto_raw where="tileid=$TILEID" output=ocsol
v.clean input=ocsol tool="break,bpol,rmsa,rmdupl" output=ocsol_cleaned --overwrite
v.centroids --overwrite input=ocsol_cleaned output=ocsol_filled
v.out.postgis --quiet -2 in=ocsol_filled output="PG:dbname=fdca user=postgres host=localhost password=sigibi" type=area output_layer=$SCHEMA.ocsol

mkdir -p /tmp/ocs/$SCHEMA
echo "SET search_path = work4, ocs, public;" > /tmp/ocs/$SCHEMA/postprocess.sql
cat 01_merge_tags.sql >> /tmp/ocs/$SCHEMA/postprocess.sql
cat 02_copy.sql >> /tmp/ocs/$SCHEMA/postprocess.sql
psql < /tmp/ocs/$SCHEMA/postprocess.sql
