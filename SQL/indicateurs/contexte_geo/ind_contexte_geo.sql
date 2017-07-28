-- Indicateurs de contexte géographique
-- 
-- * paysage
-- * her1, her2 : hydroécorégion
-- * ser, rnifn : région naturelle IFN
-- * zpg : zone phytogéographique 

-- paysage

CREATE TABLE ind_aura.paysage AS
SELECT a.gid AS cid, b.pid AS pays_id
FROM ind.grid_500m a LEFT JOIN ref.paysage_aura b
     ON st_contains(b.geom, st_centroid(a.geom));

WITH
near AS (
    SELECT a.gid AS cid, b.pid AS pays_id, row_number() over(PARTITION BY cid) AS rank
    FROM ind.grid_500m a
         INNER JOIN ind_aura.paysage i ON a.gid = i.cid,
         -- INNER JOIN
         ref.paysage_aura b
    WHERE i.pays_id IS NULL
      AND st_dwithin(a.geom, b.geom, 10e3)
    ORDER BY st_distance(a.geom, b.geom)
),
-- rank AS (
--     SELECT cid, pays_id, row_number() over(PARTITION BY cid) AS rank
--     FROM near
--     GROUP BY cid
-- ),
nearest AS (
    SELECT cid, pays_id
    FROM near
    WHERE rank = 1
)
UPDATE ind_aura.paysage
SET pays_id = nearest.pays_id
FROM nearest
WHERE paysage.cid = nearest.cid;

-- her1, her2 : hydroécorégion

CREATE TABLE ind_aura.her AS
SELECT a.gid AS cid, b.code_her1, b.code_her2
FROM ind.grid_500m a LEFT JOIN zonages.her2 b
     ON st_contains(b.geom, st_centroid(a.geom));

WITH
near AS (
    SELECT a.gid AS cid, b.code_her1, b.code_her2 --, row_number() over(PARTITION BY cid) AS rank
    FROM ind.grid_500m a
         INNER JOIN ind_aura.her i ON a.gid = i.cid
         INNER JOIN zonages.her2 b ON b.geom && a.geom
    WHERE i.code_her1 IS NULL OR i.code_her2 IS NULL
    ORDER BY st_distance(a.geom, b.geom)
),
rank AS (
    SELECT cid, code_her1, code_her2, row_number() over(PARTITION BY cid) AS rank
    FROM near
),
nearest AS (
	SELECT cid, code_her1, code_her2
	FROM rank
	WHERE rank = 1
)
UPDATE ind_aura.her
SET
	code_her1 = nearest.code_her1,
	code_her2 = nearest.code_her2
FROM nearest
WHERE her.cid = nearest.cid;

-- ser, rn : sylvoécorégion et région naturelle IFN

CREATE TABLE ind_aura.rnifn AS
SELECT a.gid AS cid, b.codeser AS ser, b.regn AS rnifn
FROM ind.grid_500m a LEFT JOIN ref.rnifn b
     ON st_contains(b.geom, st_centroid(a.geom));

WITH
near AS (
    SELECT a.gid AS cid, b.codeser AS ser, b.regn AS rnifn, row_number() over(PARTITION BY cid) AS rank
    FROM ind.grid_500m a
         INNER JOIN ind_aura.rnifn i ON a.gid = i.cid,
         ref.rnifn b
    WHERE (i.ser IS NULL OR i.rnifn IS NULL)
      AND st_dwithin(a.geom, b.geom, 10e3)
    ORDER BY st_distance(a.geom, b.geom)
),
nearest AS (
    SELECT cid, ser, rnifn
    FROM near
    WHERE rank = 1
)
UPDATE ind_aura.rnifn
SET
    ser = nearest.ser,
    rnifn = nearest.rnifn
FROM nearest
WHERE rnifn.cid = nearest.cid;

-- zpg : zone phytogéographique

CREATE TABLE ind_aura.zpg AS
SELECT a.gid AS cid, b.code AS zpg
FROM ind.grid_500m a LEFT JOIN ref.zpg b
     ON st_contains(b.geom, st_centroid(a.geom));

WITH
near AS (
    SELECT a.gid AS cid, b.code AS zpg, row_number() over(PARTITION BY cid) AS rank
    FROM ind.grid_500m a
         INNER JOIN ind_aura.zpg i ON a.gid = i.cid,
         ref.zpg b
    WHERE i.zpg IS NULL
      AND st_dwithin(a.geom, b.geom, 10e3)
    ORDER BY st_distance(a.geom, b.geom)
),
nearest AS (
    SELECT cid, zpg
    FROM near
    WHERE rank = 1
)
UPDATE ind_aura.zpg
SET
    zpg = nearest.zpg
FROM nearest
WHERE zpg.cid = nearest.cid;