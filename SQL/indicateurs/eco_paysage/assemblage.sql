CREATE TABLE ind_aura.eco_paysage AS
SELECT
    g.gid AS cid,
    COALESCE(cde.length_m, 0) AS l_cde,
    COALESCE(dd.length_m, 0) AS l_drain,
    COALESCE(haie.length_m, 0) AS l_haie,
    COALESCE(ecofor.length_m, 0) AS l_ecofor,
    COALESCE(clc_frag.num_obj, 0) AS h_clc,
    COALESCE(foret_frag.num_obj, 0) AS h_for,
    (ocsol.a_for / (ocsol.a_for + ocsol.a_ouv)) AS ifp,
    CASE WHEN (ocsol.a_cult + ocsol.a_prair) > 0 THEN
    		(ocsol.a_cult / (ocsol.a_cult + ocsol.a_prair))
    	ELSE
    		0.0
    	END
    AS icp,
    COALESCE(shdi_ocs.value, 0) AS shdi_ocs,
    COALESCE(shdi_clc.value, 0) AS shdi_clc,
    COALESCE(sidi_ocs.value, 0) AS sidi_ocs,
    COALESCE(sidi_clc.value, 0) AS sidi_clc,
    COALESCE(sidi_ocs.msidi, 0) AS msid_ocs,
    COALESCE(sidi_clc.msidi, 0) AS msid_clc,
    COALESCE(lsi_ocs.value, 1) AS lsi,
    COALESCE(mesh_ocs.value, 0) AS mesh


FROM      ind.grid_500m g
LEFT JOIN ind_aura.cde_principal_longueur cde ON g.gid = cde.cid
LEFT JOIN ind_aura.densite_drainage dd ON g.gid = dd.cid
LEFT JOIN ind_aura.haie_longueur haie ON g.gid = haie.cid
LEFT JOIN ind_aura.ecotone_foret_longueur ecofor ON g.gid = ecofor.cid
LEFT JOIN ind_aura.clc_frag ON g.gid = clc_frag.cid
LEFT JOIN ind_aura.foret_frag ON g.gid = foret_frag.cid
LEFT JOIN ind_aura.shdi_ocs ON g.gid = shdi_ocs.cid
LEFT JOIN ind_aura.shdi_clc ON g.gid = shdi_clc.cid
LEFT JOIN ind_aura.sidi_ocs ON g.gid = sidi_ocs.cid
LEFT JOIN ind_aura.sidi_clc ON g.gid = sidi_clc.cid
LEFT JOIN ind_aura.lsi_ocs ON g.gid = lsi_ocs.cid
LEFT JOIN ind_aura.mesh_ocs ON g.gid = mesh_ocs.cid

LEFT JOIN ind_aura.ocsol ON g.gid = ocsol.cid
;

ALTER TABLE ind_aura.eco_paysage
ADD PRIMARY KEY (cid);

-- DROP TABLE ind_aura.cde_principal_longueur;
-- DROP TABLE ind_aura.densite_drainage;
-- DROP TABLE ind_aura.haie_longueur;
-- DROP TABLE ind_aura.ecotone_foret_longueur;
-- DROP	TABLE ind_aura.clc_frag;
-- DROP TABLE ind_aura.foret_frag;
-- DROP TABLE ind_aura.shdi_ocs;
-- DROP	TABLE ind_aura.shdi_clc;
-- DROP TABLE ind_aura.sidi_ocs;
-- DROP	TABLE ind_aura.sidi_clc;
-- DROP	TABLE ind_aura.lsi_ocs;
-- DROP	TABLE ind_aura.mesh_ocs;