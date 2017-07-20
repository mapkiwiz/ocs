#!/bin/bash

function create_view {

    DEPNAME=$1
    DEPNO=$2
 
    psql <<EOF

        CREATE OR REPLACE VIEW ocs_cleaned.carto_$DEPNO as
        SELECT a.*
        FROM ocs.carto a inner join ocs.grid_ocs b on b.gid = a.tileid
        WHERE b.dept = '$DEPNAME';

        CREATE OR REPLACE VIEW ocs_final.carto_$DEPNO as
        SELECT a.*
        FROM ocs.carto_umc a inner join ocs.grid_ocs b on b.gid = a.tileid
        WHERE b.dept = '$DEPNAME';

EOF

}

while read no name; do

    create_view $no $name

done <<EOF
AIN 001
ALLIER 002
ARDECHE 008
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