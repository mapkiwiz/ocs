#!/bin/bash

TARGET_SCHEMA=bdt

function remove_duplicates {

	shapefile=$1
	TABLE=bdt_$(basename $shapefile .SHP | tr '[:upper:]' '[:lower:]')

	echo Removing duplicates from $TARGET_SCHEMA.$TABLE ...

	psql <<-EOF
WITH
dups AS (
	SELECT id, count(id), min(gid) as gid
	FROM $TARGET_SCHEMA.$TABLE
	GROUP BY id
	HAVING count(id) > 1
)
DELETE FROM $TARGET_SCHEMA.$TABLE
USING dups
WHERE $TABLE.id = dups.id
      AND $TABLE.gid > dups.gid;
VACUUM FULL ANALYZE $TARGET_SCHEMA.$TABLE;
EOF

}

remove_duplicates A_RESEAU_ROUTIER/CHEMIN.SHP
remove_duplicates A_RESEAU_ROUTIER/ROUTE.SHP
remove_duplicates A_RESEAU_ROUTIER/ROUTE_NOMMEE.SHP
remove_duplicates A_RESEAU_ROUTIER/ROUTE_PRIMAIRE.SHP
remove_duplicates A_RESEAU_ROUTIER/ROUTE_SECONDAIRE.SHP
remove_duplicates A_RESEAU_ROUTIER/SURFACE_ROUTE.SHP
# remove_duplicates A_RESEAU_ROUTIER/TOPONYME_COMMUNICATION.SHP
remove_duplicates B_VOIES_FERREES_ET_AUTRES/AIRE_TRIAGE.SHP
remove_duplicates B_VOIES_FERREES_ET_AUTRES/GARE.SHP
# remove_duplicates B_VOIES_FERREES_ET_AUTRES/TOPONYME_FERRE.SHP
remove_duplicates B_VOIES_FERREES_ET_AUTRES/TRANSPORT_CABLE.SHP
remove_duplicates B_VOIES_FERREES_ET_AUTRES/TRONCON_VOIE_FERREE.SHP
remove_duplicates C_TRANSPORT_ENERGIE/CONDUITE.SHP
remove_duplicates C_TRANSPORT_ENERGIE/LIGNE_ELECTRIQUE.SHP
remove_duplicates C_TRANSPORT_ENERGIE/POSTE_TRANSFORMATION.SHP
remove_duplicates C_TRANSPORT_ENERGIE/PYLONE.SHP
remove_duplicates D_HYDROGRAPHIE/CANALISATION_EAU.SHP
remove_duplicates D_HYDROGRAPHIE/HYDRONYME.SHP
remove_duplicates D_HYDROGRAPHIE/POINT_EAU.SHP
remove_duplicates D_HYDROGRAPHIE/RESERVOIR_EAU.SHP
remove_duplicates D_HYDROGRAPHIE/SURFACE_EAU.SHP
remove_duplicates D_HYDROGRAPHIE/TRONCON_COURS_EAU.SHP
remove_duplicates E_BATI/BATI_INDIFFERENCIE.SHP
remove_duplicates E_BATI/BATI_INDUSTRIEL.SHP
remove_duplicates E_BATI/BATI_REMARQUABLE.SHP
remove_duplicates E_BATI/CIMETIERE.SHP
remove_duplicates E_BATI/CONSTRUCTION_LEGERE.SHP
remove_duplicates E_BATI/CONSTRUCTION_LINEAIRE.SHP
remove_duplicates E_BATI/CONSTRUCTION_PONCTUELLE.SHP
remove_duplicates E_BATI/CONSTRUCTION_SURFACIQUE.SHP
remove_duplicates E_BATI/PISTE_AERODROME.SHP
remove_duplicates E_BATI/RESERVOIR.SHP
remove_duplicates E_BATI/TERRAIN_SPORT.SHP
remove_duplicates F_VEGETATION/ZONE_VEGETATION.SHP
remove_duplicates G_OROGRAPHIE/LIGNE_OROGRAPHIQUE.SHP
# remove_duplicates G_OROGRAPHIE/ORONYME.SHP
remove_duplicates H_ADMINISTRATIF/CHEF_LIEU.SHP
remove_duplicates H_ADMINISTRATIF/COMMUNE.SHP
# remove_duplicates I_ZONE_ACTIVITE/PAI_ADMINISTRATIF_MILITAIRE.SHP
# remove_duplicates I_ZONE_ACTIVITE/PAI_CULTURE_LOISIRS.SHP
# remove_duplicates I_ZONE_ACTIVITE/PAI_ESPACE_NATUREL.SHP
# remove_duplicates I_ZONE_ACTIVITE/PAI_GESTION_EAUX.SHP
# remove_duplicates I_ZONE_ACTIVITE/PAI_HYDROGRAPHIE.SHP
# remove_duplicates I_ZONE_ACTIVITE/PAI_INDUSTRIEL_COMMERCIAL.SHP
# remove_duplicates I_ZONE_ACTIVITE/PAI_OROGRAPHIE.SHP
# remove_duplicates I_ZONE_ACTIVITE/PAI_RELIGIEUX.SHP
# remove_duplicates I_ZONE_ACTIVITE/PAI_SANTE.SHP
# remove_duplicates I_ZONE_ACTIVITE/PAI_SCIENCE_ENSEIGNEMENT.SHP
# remove_duplicates I_ZONE_ACTIVITE/PAI_SPORT.SHP
# remove_duplicates I_ZONE_ACTIVITE/PAI_TRANSPORT.SHP
# remove_duplicates I_ZONE_ACTIVITE/PAI_ZONE_HABITATION.SHP
remove_duplicates I_ZONE_ACTIVITE/SURFACE_ACTIVITE.SHP
remove_duplicates T_TOPONYMES/LIEU_DIT_HABITE.SHP
remove_duplicates T_TOPONYMES/LIEU_DIT_NON_HABITE.SHP
remove_duplicates T_TOPONYMES/TOPONYME_DIVERS.SHP