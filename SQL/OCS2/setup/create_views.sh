#!/bin/bash

function create_view {

    DEPNAME=$1
    DEPNO=$2
 
    psql <<EOF

        CREATE OR REPLACE VIEW ocs_final.carto_$DEPNO as
        SELECT a.*
        FROM ocsv2.carto_clc a inner join ocs.grid_ocs b on b.gid = a.tileid
        WHERE b.dept = '$DEPNAME';

EOF

}

while read name no; do

    create_view $name $no

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