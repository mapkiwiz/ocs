#!/bin/bash

OUTPUT_DIR="/mnt/data/FCAURA/PRODUCTION/OCSOL"
DATABASE=fdca

mkdir -p $OUTPUT_DIR/cleaned
mkdir -p $OUTPUT_DIR/final

while read name no;
do

	pgsql2shp -f $OUTPUT_DIR/cleaned/OCSOL_CLEANED_L93_$no.shp -r $DATABASE ocs_cleaned.carto_$no
	cp -v ../../STYLES/ocsol.qml $OUTPUT_DIR/cleaned/OCSOL_CLEANED_L93_$no.qml
	pgsql2shp -f $OUTPUT_DIR/final/OCSOL_L93_$no.shp -r $DATABASE ocs_final.carto_$no
	cp -v ../../STYLES/ocsol.qml $OUTPUT_DIR/final/OCSOL_L93_$no.qml

done <<EOF
AIN 001
ALLIER 002
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