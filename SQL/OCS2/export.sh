#!/bin/bash

OUTPUT_DIR="/mnt/data/FCAURA/PRODUCTION/OCSOL"
DATABASE=fdca

mkdir -p $OUTPUT_DIR/FINAL_V2

while read name no;
do

	pgsql2shp -f $OUTPUT_DIR/FINAL_V2/OCSOL_L93_$no.shp -r $DATABASE ocs_final.carto_$no
	cp -v ../../STYLES/carto_clc.qml $OUTPUT_DIR/FINAL_V2/OCSOL_L93_$no.qml

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