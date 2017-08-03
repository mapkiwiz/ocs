CREATE TABLE ind_aura.ocsol AS
WITH surf_agg AS (
	SELECT
        cid,
        (cul + agrx) AS a_cult,
        (pra + prax) AS a_prair,
        (arb+pur+roc+nei+natx+art+esv+zhu) AS a_autre,
        (fort + forx) AS a_for,
        eau AS a_eau,
        bat AS a_cons,
        (cul+pra+vig+arb+nat+pur+nei+roc+natx+zhu+agrx+prax+vigx) AS a_ouv
    FROM ind_aura.ocsol_surfaces
)
SELECT
    g.gid AS cid,
    surf_agg.a_cult,
    surf_agg.a_prair,
    surf_agg.a_autre,
    surf_agg.a_for,
    surf_agg.a_eau,
    surf_agg.a_cons,
    surf_agg.a_ouv,
    ocsol_dominant.ocs1,
    COALESCE(ocsol_dominant.a_ocs1, 0) AS a_ocs1,
    ocsol_dominant.ocs2,
    COALESCE(ocsol_dominant.a_ocs2, 0) AS a_ocs2,
    clc.clc1,
    COALESCE(clc.a_clc1, 0) AS a_clc1,
    clc.clc2,
    COALESCE(clc.a_clc2, 0) AS a_clc2,
    fort.nature AS fordom,
    COALESCE(fort.surf_ha, 0) AS a_fordom,
    rpg.cult_maj,
    COALESCE(rpg.surf_ha, 0) AS a_cultma
FROM      ind.grid_500m g
LEFT JOIN surf_agg ON g.gid = surf_agg.cid
LEFT JOIN ind_aura.ocsol_dominant ON g.gid = ocsol_dominant.cid
LEFT JOIN ind_aura.clc_2012 clc ON g.gid = clc.cid
LEFT JOIN ind_aura.foret_type_dominant fort ON g.gid = fort.cid
LEFT JOIN ind_aura.rpg_cult_dominante rpg ON g.gid = rpg.cid;

ALTER TABLE ind_aura.ocsol
ADD PRIMARY KEY (cid);

-- DROP TABLE ind_aura.ocsol_surfaces;
-- DROP TABLE ind_aura.ocsol_dominant;
-- DROP TABLE ind_aura.clc_2012;
-- DROP TABLE ind_aura.foret_type_dominant;
-- DROP TABLE ind_aura.rpg_cult_dominante;