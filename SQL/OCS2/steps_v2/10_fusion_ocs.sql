CREATE TABLE ocsol AS
WITH parts AS (
	SELECT 'EAU' AS nature, geom FROM surf_eau_snapped
	UNION ALL
	SELECT 'INFRA' AS nature, geom FROM surf_infra
	UNION ALL
    SELECT 'AUTRE/INFRA' AS nature, geom FROM surf_non_infra_small
    UNION ALL
	SELECT 'FORET' AS nature, geom FROM surf_foret_noco
    UNION ALL
    SELECT 'BATI' AS nature, geom FROM surf_construite_nofor
    UNION ALL
    SELECT 'PRAIRIE' AS nature, geom FROM surf_prairie_snapped
    UNION ALL
    SELECT 'CULTURES' AS nature, geom FROM surf_cultures_snapped
    UNION ALL
    SELECT 'ARBORICULTURE' AS nature, geom FROM surf_arboriculture_snapped
    UNION ALL
    SELECT 'VIGNE' AS nature, geom FROM surf_vigne_snapped
    UNION ALL
    SELECT 'NATUREL' AS nature, geom FROM surf_autre WHERE st_area(geom) < 2500 AND txfor > .6
    UNION ALL
    SELECT 'PERIURBAIN' AS nature, geom FROM surf_autre WHERE st_area(geom) < 2500 AND txfor <= .6
    UNION ALL
    SELECT 'AUTRE/?' AS nature, geom FROM surf_autre WHERE st_area(geom) >= 2500 AND st_area(geom) < 5e4 AND txvurb <= .2
    UNION ALL
    SELECT 'PERIURBAIN' AS nature, geom FROM surf_autre WHERE st_area(geom) >= 2500 AND st_area(geom) < 5e4 AND txvurb > .2
    UNION ALL
    SELECT 'AUTRE/?' AS nature, geom FROM surf_autre WHERE st_area(geom) >= 5e4
)
SELECT row_number() over() AS gid, nature, st_force2d(geom) AS geom
FROM parts
WHERE ST_GeometryType(geom) = 'ST_Polygon';

ALTER TABLE ocsol
ADD PRIMARY KEY (gid);

CREATE INDEX ocsol_geom_idx
ON ocsol USING GIST (geom);

-- CREATE TABLE missing_parts AS
-- WITH
-- grid as (
--     SELECT geom
--     FROM grid_ocs
--     WHERE gid = 1
-- ),
-- diff AS (
--     SELECT st_difference((SELECT geom FROM grid), safe_union(a.geom)) AS geom
--     FROM ocsol_cleaned a
-- ),
-- parts AS (
--     SELECT (st_dump(geom)).geom
--     FROM diff
-- )
-- SELECT row_number() over() AS gid, geom
-- FROM parts;