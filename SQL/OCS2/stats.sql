-- Décompte du nombre d'objets de petite surface
-- dans chaque département,
-- avant post-traitement avec GRASS

WITH
objs AS (
    SELECT b.dept, count(a.gid) AS nobj, sum(st_area(a.geom)) / 1e7 AS obj_area
    FROM ocs.carto_raw a INNER JOIN ocs.grid_ocs b ON b.gid = a.tileid
    GROUP BY b.dept
),
smalls AS (
    SELECT b.dept, count(a.gid) AS nobj, sum(st_area(a.geom)) / 1e7 AS obj_area
    FROM ocs.carto_raw a INNER JOIN ocs.grid_ocs b ON b.gid = a.tileid
    WHERE st_area(a.geom) < 2500
    GROUP BY b.dept
),
depts AS (
    SELECT dept, sum(st_area(geom)) / 1e7 AS tile_area
    FROM ocs.grid_ocs
    GROUP BY dept
)
SELECT b.dept,
       a.nobj, c.nobj AS nsmall,
       (c.nobj::numeric / a.nobj::numeric) * 100.0 AS small_ratio,
       b.tile_area,
       a.obj_area, c.obj_area AS small_area,
       (c.obj_area / a.obj_area) * 100.0 AS small_area_ratio,
       100.0 * (a.obj_area / b.tile_area) - 100.0 AS overlap
FROM depts b
     LEFT JOIN objs a ON a.dept = b.dept
     LEFT JOIN smalls c ON c.dept = b.dept
ORDER BY b.dept;

-- Ratio surface des objets / surface des tuiles
-- pour chaque département,
-- après post-traitement avec GRASS (étape 1 - suppression des recouvrements)

WITH
objs AS (
    SELECT b.dept, count(a.gid) AS nobj, sum(st_area(a.geom)) / 1e7 AS obj_area
    FROM ocs.carto a INNER JOIN ocs.grid_ocs b ON b.gid = a.tileid
    GROUP BY b.dept
),
depts AS (
    SELECT dept, sum(st_area(geom)) / 1e7 AS tile_area
    FROM ocs.grid_ocs
    GROUP BY dept
)
SELECT b.dept, a.nobj, a.obj_area, b.tile_area, 100.0 * (a.obj_area / b.tile_area) - 100.0 AS overlap
FROM objs a RIGHT JOIN depts b ON a.dept = b.dept
ORDER BY b.dept;

-- Ratio surface des objets / surface des tuiles
-- pour chaque département,
-- après post-traitement avec GRASS

WITH
objs AS (
    SELECT b.dept, count(a.gid) AS nobj, sum(st_area(a.geom)) / 1e7 AS obj_area
    FROM ocs.carto_umc a INNER JOIN ocs.grid_ocs b ON b.gid = a.tileid
    GROUP BY b.dept
),
depts AS (
    SELECT dept, sum(st_area(geom)) / 1e7 AS tile_area
    FROM ocs.grid_ocs
    GROUP BY dept
)
SELECT b.dept, a.nobj, a.obj_area, b.tile_area, 100.0 * (a.obj_area / b.tile_area) - 100.0 AS overlap
FROM objs a RIGHT JOIN depts b ON a.dept = b.dept
ORDER BY b.dept;

-- Décompte du nombre d'objets non classifiés à partir de la BD TOPO ou du RPG
-- avant croisement avec CLC
-- et ratio surface non classifiée / surface totale

WITH
objs AS (
    SELECT b.dept, count(a.gid) AS nobj, sum(st_area(a.geom)) / 1e7 AS obj_area
    FROM ocs.carto_umc a INNER JOIN ocs.grid_ocs b ON b.gid = a.tileid
    GROUP BY b.dept
),
autres AS (
    SELECT b.dept, count(a.gid) AS nobj, sum(st_area(a.geom)) / 1e7 AS obj_area
    FROM ocs.carto_umc a INNER JOIN ocs.grid_ocs b ON b.gid = a.tileid
    WHERE a.nature IN ('AUTRE/NATURE'::ocs_nature, 'AUTRE/?'::ocs_nature)
    GROUP BY b.dept
),
depts AS (
    SELECT dept, sum(st_area(geom)) / 1e7 AS tile_area
    FROM ocs.grid_ocs
    GROUP BY dept
)
SELECT b.dept,
       a.nobj, c.nobj AS nautre, (c.nobj::numeric / a.nobj::numeric) * 100.0 AS npautre,
       b.tile_area, c.obj_area AS autre_area, (c.obj_area / b.tile_area) * 100.0 AS pautre
FROM depts b
     LEFT JOIN objs a ON a.dept = b.dept
     LEFT JOIN autres c ON c.dept = b.dept
ORDER BY b.dept;

-- Nombre de tuiles manquantes

WITH
tiles AS (
    SELECT a.tileid, sum(st_area(a.geom)) AS area
    FROM ocs.carto_clc a
    GROUP BY a.tileid
)
SELECT b.dept, count(b.gid)
FROM tiles a
     RIGHT JOIN ocs.grid_ocs b ON a.tileid = b.gid
WHERE a.area is null
GROUP BY b.dept
ORDER BY b.dept;

-- Nombre de tuiles incomplètes ou avec un recouvrement
-- au-delà d'un certain seuil de surface

WITH
tiles AS (
    SELECT a.tileid, sum(st_area(a.geom)) AS area
    FROM ocs.carto_clc a
    GROUP BY a.tileid
),
incomplete AS (
    SELECT b.dept, b.gid as tileid
    FROM tiles a
         INNER JOIN ocs.grid_ocs b ON a.tileid = b.gid
    WHERE abs(st_area(b.geom) - a.area) > 1e4
)
SELECT dept, count(tileid)
FROM incomplete
GROUP BY dept
ORDER BY dept;

-- Nombre de tuiles manquantes, incomplètes ou avec un recouvrement
-- au-delà d'un certain seuil de surface

WITH
tiles AS (
    SELECT a.tileid, sum(st_area(a.geom)) AS area
    FROM ocs.carto_clc a
    GROUP BY a.tileid
),
incomplete AS (
    SELECT b.dept, b.gid as tileid
    FROM tiles a
         RIGHT JOIN ocs.grid_ocs b ON a.tileid = b.gid
    WHERE abs(st_area(b.geom) - coalesce(a.area,0)) > 1e4
)
SELECT dept, count(tileid)
FROM incomplete
GROUP BY dept
ORDER BY dept;

-- Liste des tuiles incomplètes ou avec un recouvrement
-- au-delà d'un certain seuil de surface

WITH
tiles AS (                                       
    SELECT a.tileid, sum(st_area(a.geom)) AS area
    FROM ocs.carto_clc a
    GROUP BY a.tileid
)           
SELECT b.dept, b.gid as tileid, st_area(b.geom) - a.area AS delta
FROM tiles a
     INNER JOIN ocs.grid_ocs b ON a.tileid = b.gid
WHERE abs(st_area(b.geom) - a.area) > 1e4
ORDER BY b.dept, delta desc;

-- Validation MC OCS vs. CLC

CREATE TABLE ocs.validation AS
WITH
random_points AS (
    SELECT dept, gid, (st_dump(st_generatepoints(geom, 1000))).geom
    FROM ocs.grid_ocs
),
points AS (
    SELECT row_number() over() AS gid, dept, gid as tileid, geom
    FROM random_points
),
ocs AS (
        SELECT a.gid, b.nature
    FROM points a
         LEFT JOIN ocs.carto_clc b
         ON st_contains(b.geom, a.geom)
),
clc AS (
    SELECT a.gid, b.code_12 AS code_clc
    FROM points a
         LEFT JOIN ref.clc_2012 b
         ON st_contains(b.geom, a.geom)
)
SELECT a.gid, a.dept, a.tileid, b.nature, c.code_clc
FROM points a
     INNER JOIN ocs b ON a.gid = b.gid
     INNER JOIN clc c ON a.gid = c.gid;