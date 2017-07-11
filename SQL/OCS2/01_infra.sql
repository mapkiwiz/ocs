SET search_path = test, ocs, public;

CREATE TABLE surf_infra AS
WITH
grid as (
    SELECT geom
    FROM ocs.grid_ocs
    WHERE gid = 1
),
route AS (
    SELECT st_intersection(st_buffer(r.geom, r.largeur/2 + 2), (SELECT geom FROM grid)) as geom
    FROM bdt.bdt_route r
    WHERE
        st_intersects(r.geom, (SELECT geom FROM grid))
        AND r.nature NOT IN ('Sentier', 'Escalier', 'Chemin') AND pos_sol = 0
),
voie_ferree AS (
    SELECT st_intersection(st_buffer(r.geom,
        CASE
            WHEN r.nature = 'LGV' THEN 15
            WHEN r.nature = 'Principale' AND r.nb_voies = 2 THEN 8
            ELSE 4
        END), (SELECT geom FROM grid)) as geom
    FROM bdt.bdt_troncon_voie_ferree r
    WHERE st_intersects(r.geom, (SELECT geom FROM grid)) AND r.pos_sol = 0
),
infra AS (
    SELECT geom FROM route
    UNION ALL SELECT geom FROM voie_ferree
),
parts AS (
    SELECT (st_dump(st_union(geom))).geom
    FROM infra
)
SELECT row_number() over() as gid, geom
FROM parts;

CREATE TABLE surf_non_infra_t AS
WITH
grid AS (
    SELECT geom
    FROM ocs.grid_ocs
    WHERE gid = 1
),
diff AS (
    SELECT st_difference((SELECT geom FROM grid), st_union(geom)) AS geom
    FROM surf_infra
    -- WHERE ...
),
parts AS (
    SELECT (st_dump(geom)).geom
    FROM diff
)
SELECT row_number() over() AS gid, geom
FROM parts
WHERE ST_GeometryType(geom) = 'ST_Polygon';

CREATE TABLE surf_non_infra AS
WITH parts AS (
    SELECT SplitWithNetworks(geom) as geom
    FROM surf_non_infra_t
)      
SELECT row_number() over() AS gid, geom
FROM parts;

ALTER TABLE surf_non_infra
ADD PRIMARY KEY (gid);

CREATE INDEX surf_non_infra_geom_idx
ON test.surf_non_infra USING GIST (geom);

CREATE TABLE test.surf_non_infra_small AS
SELECT * FROM test.surf_non_infra
WHERE st_area(geom) < 2500;

DELETE FROM test.surf_non_infra
WHERE st_area(geom) < 2500;