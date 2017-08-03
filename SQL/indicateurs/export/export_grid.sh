#!/bin/bash

DATABASE=fdca
OUTPUT_DIR=/mnt/data/FCAURA/PRODUCTION/INDICATEURS

function export_grid_aura {

	pgsql2shp -f $OUTPUT_DIR/AURA/GRID_500M_LA93_AURA.shp $DATABASE ind.grid_500m

}

function export_grid {

	NAME=$1
	NO=$2

	pgsql2shp -f $OUTPUT_DIR/DEPARTEMENTS/$NAME/GRID_500M_LA93_$NO.shp $DATABASE ind.grid_500m_$NO

}

export_grid_aura

while read NAME NO; do
	
	export_grid $NAME $NO

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