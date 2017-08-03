-- Dépend de :
-- * ind_ocsol.sql

CREATE TABLE ind_aura.ocsol_dominant AS
WITH
dom AS (
    SELECT *
    FROM ind_aura.ocsol_sparse
    WHERE surf_rank = 1
),
subdom AS (
    SELECT *
    FROM ind_aura.ocsol_sparse
    WHERE surf_rank = 2
)
SELECT a.gid AS cid,
       b.nature as ocs1, COALESCE(b.surf_ha, 0) as a_ocs1,
       c.nature as ocs2, COALESCE(c.surf_ha, 0) as a_ocs2,
       a.geom
FROM ind.grid_500m a
     LEFT JOIN dom b ON a.gid = b.cid
     LEFT JOIN subdom c ON a.gid = c.cid;