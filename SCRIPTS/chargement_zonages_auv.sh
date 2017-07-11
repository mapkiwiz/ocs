#!/bin/bash

function load2pgsql {
    shp2pgsql -s 2154 -D -I -W LATIN1 -d $1 $2 | psql
}

function populate_zonages_tous {
    psql <<EOF
    INSERT INTO $1.tous (zonage, zone_id, geom)
    SELECT '$2' as zonage, gid, geom
    FROM $1.$2;
EOF
}

psql <<EOF
    CREATE TABLE zonages.tous (
        gid serial primary key,
        zonage varchar(20),
        zone_id bigint,
        geom geometry(MultiPolygon,2154)
    );
    CREATE INDEX tous_geom_idx
    ON zonages.tous USING GIST (geom);
EOF

while read schema group table zonegeo filename ; do
    load2pgsql $schema/$group/$table/$zonegeo/$filename $schema"."$table
    populate_zonages_tous $schema $table
done <<EOF
zonages    enp    inpn_apb    FXX    N_ENP_APB_S_000.shp
zonages    enp    inpn_bpm    FXX    N_ENP_BPM_S_000.shp
zonages    enp    inpn_cen    FXX    cen2013_09.shp
zonages    enp    inpn_pn    FXX    N_ENP_PN_S_000.shp
zonages    enp    inpn_pnr    FXX    N_ENP_PNR_S_000.shp
zonages    enp    inpn_ramsar    FXX    N_ENP_RAMSAR_S_000.shp
zonages    enp    inpn_rb    FXX    N_ENP_RB_S_000.shp
zonages    enp    inpn_ripn    FXX    ripn2013.shp
zonages    enp    inpn_rncfs    FXX    N_ENP_RNCFS_S_000.shp
zonages    enp    inpn_rnn    FXX    N_ENP_RNN_S_000.shp
zonages    enp    inpn_rnr    FXX    N_ENP_RNR_S_000.shp
zonages    enp    zico    FXX    zico.shp
zonages    enp    zps    AUV    n_n2000_zps_zinf_s_r83.shp
zonages    enp    zsc    AUV    n_n2000_zsc_zinf_s_r83.shp
zonages    gestion    contrat_riviere    AUV    n_contrat_riviere_zsup_r83.shp
zonages    gestion    sage    AUV    n_sage_zinf_r83.shp
zonages    gestion    scot    AUV    n_scot_zsup_083_1.shp
zonages    gestion    site_classe    AUV    n_site_classe_s_r83.shp
zonages    gestion    site_inscrit    AUV    n_site_inscrit_s_r83.shp
zonages    gestion    znieff1    AUV    n_znieff1_zinf_s_r83.shp
zonages    gestion    znieff2    AUV    n_znieff2_zinf_s_r83.shp
zonages    gestion    zone_sensible    FXX    ZoneSensible_FXX.shp
zonages    gestion    zone_vulnerable    FXX    ZoneVuln.shp
zonages    hydro    her1    FXX    her1.shp
zonages    hydro    her2    FXX    her2.shp
EOF