#!/bin/bash

FLAGS=--quiet

function dissolve_foret {

	NAME=$1
	NO=$2

	v.in.ogr $FLAGS min_area=0.0001 snap=0.001 --overwrite -o -e input="PG:dbname=fdca user=postgres host=localhost password=sigibi" \
	layer=ocsv2.carto_clc_foret_dep where="dept='$NAME'" output=foret
	v.dissolve $FLAGS --overwrite foret column=dept output=foret_d
	v.out.postgis --overwrite $FLAGS -2 output="PG:dbname=fdca user=postgres host=localhost password=sigibi" \
	type=area in=foret_d output_layer=aux.surface_boisee_$NO	

}

while read NAME NO; do
	
	echo "Dissolving polygons of $NAME"
	dissolve_foret $NAME $NO

done <<EOF
AIN 001
ALLIER 003
ARDECHE 007
CANTAL 015
DROME 026
HAUTE-LOIRE 043
HAUTE-SAVOIE 074
ISERE 038
LOIRE 042
PUY-DE-DOME 063
RHONE 069
SAVOIE 073
EOF