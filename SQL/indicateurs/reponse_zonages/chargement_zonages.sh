#!/bin/bash

psql <<EOF
    CREATE TABLE zonages.tous (
        gid serial primary key,
        zonage varchar(20),
        zone_id bigint,
        geom geometry(Polygon,2154)
    );
EOF

function import_zonage {

 DIR=$1
 SHAPEFILE=$2

 shp2pgsql -s 2154 -I -D -W LATIN1 $DIR/$SHAPEFILE zonages.$DIR | psql
 psql <<EOF
 	INSERT INTO zonages.tous (zonage, zone_id, geom)
 	SELECT '$DIR' AS zonage, gid, St_Force2D((ST_Dump(geom)).geom) AS geom
 	FROM zonages.$DIR;
EOF

}

while read d shp ;
do

	import_zonage $d $shp;

done <<EOF
forpub FOR_PUBL_L93_REG84_V201606.shp
comil contrat_metrople-shp.shp
sage Sage.shp
scot l_scot_r82.shp
apb N_ENP_APB_S_000.shp
bpm N_ENP_BPM_S_000.shp
cen cen2013_09.shp
pn N_ENP_PN_S_000.shp
pnr N_ENP_PNR_S_000.shp
ramsar N_ENP_RAMSAR_S_000.shp
rb N_ENP_RB_S_000.shp
ripn ripn2013.shp
rncfs N_ENP_RNCFS_S_000.shp
rnn N_ENP_RNN_S_000.shp
rnr N_ENP_RNR_S_000.shp
zico zico.shp
zps l_natura2000_zps_s_r82.shp
zsc l_natura2000_sic_s_r82.shp
znieff1 ZNIEFF1_G2.shp
znieff2 ZNIEFF2_G2.shp
zsens ZoneSensible_FXX.shp
zvuln ZoneVuln.shp
EOF