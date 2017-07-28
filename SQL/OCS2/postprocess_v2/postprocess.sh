#!/bin/bash

WORK_DIR=/tmp/ocs
SCHEMA=$1
TILEID=$2
FLAGS=--quiet

g.gisenv set="DEBUG=0"

# Step 1 : remove overlapping areas and fill gaps

v.in.ogr $FLAGS min_area=0.0001 snap=0.001 --overwrite -o -e \
input="PG:dbname=fdca user=postgres host=localhost password=sigibi" \
layer=$SCHEMA.ocsol output=ocsol

v.clean $FLAGS input=ocsol tool="break,bpol,rmsa,rmdupl" output=ocsol_cleaned --overwrite
v.centroids $FLAGS --overwrite input=ocsol_cleaned output=ocsol_filled
#v.to.db $FLAGS ocsol_filled option=cat column=cat

v.out.postgis $FLAGS -2 output="PG:dbname=fdca user=postgres host=localhost password=sigibi" \
type=area in=ocsol_filled output_layer=$SCHEMA.filled

# Step 2 : join attributes

psql -f $WORK_DIR/$SCHEMA/postprocess/01_join_attributes.sql

# Step 3 : merge areas smaller than UMC
#          and simplify result

v.in.ogr $FLAGS min_area=0.0001 snap=0.001 --overwrite -o -e \
input="PG:dbname=fdca user=postgres host=localhost password=sigibi" \
layer=$SCHEMA.filled output=ocsol

v.clean $FLAGS --overwrite input=ocsol output=cleaned tool=rmarea threshold=2500
v.generalize $FLAGS --overwrite cleaned method=douglas threshold=0.5 output=simplified

v.out.postgis $FLAGS -2 output="PG:dbname=fdca user=postgres host=localhost password=sigibi" \
type=area in=simplified output_layer=$SCHEMA.simplified

# Step 4 : patch missing areas
#          and overlay unknown areas with Corine Land Cover (CLC)

psql -f $WORK_DIR/$SCHEMA/postprocess/02_patch_missing_areas.sql
psql -f $WORK_DIR/$SCHEMA/postprocess/03_overlay_clc.sql

# Step 5 : merge areas areas smaller than UMC

v.in.ogr $FLAGS min_area=0.0001 snap=0.001 --overwrite -o -e \
input="PG:dbname=fdca user=postgres host=localhost password=sigibi" \
layer=$SCHEMA.autre_clc output=autre_clc

v.clean $FLAGS --overwrite input=autre_clc output=autre_clc_cleaned tool=rmarea threshold=2500

v.out.postgis $FLAGS -2 output="PG:dbname=fdca user=postgres host=localhost password=sigibi" \
type=area in=autre_clc_cleaned output_layer=$SCHEMA.autre_clc_cleaned

# Step 6 : assembly complete layer

psql -f $WORK_DIR/$SCHEMA/postprocess/04_assembly_carto_clc.sql
