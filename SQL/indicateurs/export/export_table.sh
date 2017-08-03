#!/bin/bash

OUTPUT_DIR=/mnt/data/FCAURA/PRODUCTION/INDICATEURS
TABLE=$1

function csv2dbf {
	INPUT=$1
	OUTPUT=$(dirname $INPUT)/$(basename $INPUT .csv).dbf
	ogr2ogr -f "ESRI Shapefile" -oo AUTODETECT_WIDTH=YES -oo AUTODETECT_TYPE=YES -oo AUTODETECT_SIZE_LIMIT=0 $OUTPUT $INPUT
}

function export_table_aura {

	psql <<EOF

		\COPY ind_aura.$TABLE TO $OUTPUT_DIR/AURA/$TABLE.csv WITH CSV HEADER;

EOF

}


function export_table {

	NAME=$1
	NO=$2
	VIEW_RELNAME="$TABLE"_$NO

	psql <<EOF

		CREATE OR REPLACE VIEW ind_aura.$VIEW_RELNAME AS
		SELECT a.*
		FROM ind_aura.$TABLE a
		INNER JOIN ind.grid_500m_dept_rel b ON a.cid = b.gid
		WHERE b.dept = '$NAME';

		\COPY (SELECT * FROM ind_aura.$VIEW_RELNAME) TO $OUTPUT_DIR/DEPARTEMENTS/$NAME/$TABLE.csv WITH CSV HEADER;

		DROP VIEW ind_aura.$VIEW_RELNAME;

EOF

}

export_table_aura
csv2dbf $OUTPUT_DIR/AURA/$TABLE.csv

while read NAME NO; do
	
	export_table $NAME $NO
	csv2dbf $OUTPUT_DIR/DEPARTEMENTS/$NAME/$TABLE.csv

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

