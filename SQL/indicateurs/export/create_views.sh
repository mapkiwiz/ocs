#!/bin/bash

function create_view {

	NAME=$1
	NO=$2

	psql <<EOF
		CREATE OR REPLACE VIEW ind.grid_500m_$NO AS
		SELECT a.*
		FROM ind.grid_500m a
		INNER JOIN ind.grid_500m_dept_rel b ON a.gid = b.gid
		WHERE b.dept = '$NAME';
EOF

}

while read NAME NO; do
	
	create_view $NAME $NO

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