-- Etape 1
-- Préparation de deux tables auxiliaires :
-- 1. Un tampon de 5 m de largeur 
--    autour des troncons (TRONCON_COURS_EAU) et des surfaces en eau (SURFACE_EAU) de la BDT ;
--    on ne garde que les sections qui ont un régime permanent (regime = 'Permanent')
-- 2. Un découpage par grandes mailles des tronçons (TRONCON_COURS_EAU) de la BDT

DROP SCHEMA IF EXISTS ripi CASCADE;
CREATE SCHEMA ripi;

-- Si nécessaire, ajouter les index suivants
-- pour diminuer drastiquement le temps de traitement

-- CREATE INDEX bdt_troncon_cours_eau_geom_2d_idx
-- ON bdt.bdt_troncon_cours_eau USING GIST (st_force2d(geom)) ;

-- CREATE INDEX bdt_surface_eau_geom_2d_idx
-- ON bdt.bdt_surface_eau USING GIST (st_force2d(geom)) ;

CREATE TABLE ripi.cde_buffer_5m AS
WITH
surf AS (
    SELECT b.gid as cid, (st_dump(st_buffer(st_union(st_intersection(st_force2d(a.geom), b.geom)), 5))).geom as geom
    FROM bdt.bdt_surface_eau a
         INNER JOIN ocs.grid_ocs b ON st_intersects(st_force2d(a.geom), b.geom)
         INNER JOIN bdt.bdt_troncon_cours_eau c ON st_intersects(st_force2d(a.geom), st_force2d(c.geom))
    WHERE a.regime = 'Permanent'
    GROUP BY b.gid
),
lin AS (
    SELECT b.gid as cid, (st_dump(st_buffer(st_union(st_intersection(st_force2d(a.geom), b.geom)), 5))).geom as geom
    FROM bdt.bdt_troncon_cours_eau a
         INNER JOIN ocs.grid_ocs b ON st_intersects(st_force2d(a.geom), b.geom)
    WHERE a.regime = 'Permanent'
    GROUP BY b.gid
),
surf_and_lin AS (
    SELECT * FROM surf
    UNION SELECT * FROM lin
)
SELECT cid, (st_dump(st_union(geom))).geom
FROM surf_and_lin
GROUP BY cid;

CREATE TABLE ripi.lin_by_grid AS
SELECT b.gid as cid, (st_dump(st_intersection(st_force2d(a.geom), b.geom))).geom
FROM bdt.bdt_troncon_cours_eau a
     INNER JOIN ocs.grid_ocs b ON st_intersects(st_force2d(a.geom), b.geom)
WHERE a.regime = 'Permanent';

DELETE FROM ripi.lin_by_grid
WHERE ST_GeometryType(geom) != 'ST_LineString';

CREATE INDEX lin_by_grid_geom_idx
ON ripi.lin_by_grid USING GIST (geom);

CREATE VIEW aux.surface_eau AS
SELECT *
FROM ocsv2.carto_clc
WHERE nature = 'EAU';