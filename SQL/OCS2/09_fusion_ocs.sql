CREATE TABLE test.ocsol AS
WITH parts AS (
	SELECT 'EAU' AS nature, geom FROM test.surf_eau_snapped
	UNION ALL
	SELECT 'INFRA' AS nature, geom FROM test.surf_infra
	UNION ALL
    SELECT 'INFRA' AS nature, geom FROM test.surf_non_infra_small
    UNION ALL
	SELECT 'FORET' AS nature, geom FROM test.surf_foret_noco
    UNION ALL
    SELECT 'BATI' AS nature, geom FROM test.surf_construite_nofor
    UNION ALL
    SELECT 'PRAIRIE' AS nature, geom FROM test.surf_prairie_snapped
    UNION ALL
    SELECT 'CULTURES' AS nature, geom FROM test.surf_cultures_snapped
    UNION ALL
    SELECT 'ARBO' AS nature, geom FROM test.surf_arboriculture_snapped
    UNION ALL
    SELECT 'AUTRE/NATURE' AS nature, geom FROM test.surf_autre WHERE st_area(geom) < 2500 AND txfor > .6
    UNION ALL
    SELECT 'AUTRE/BATI' AS nature, geom FROM test.surf_autre WHERE st_area(geom) < 2500 AND txfor <= .6
    UNION ALL
    SELECT 'AUTRE/NATURE' AS nature, geom FROM test.surf_autre WHERE st_area(geom) >= 2500 AND st_area(geom) < 5e4 AND txvurb <= .2
    UNION ALL
    SELECT 'AUTRE/BATI' AS nature, geom FROM test.surf_autre WHERE st_area(geom) >= 2500 AND st_area(geom) < 5e4 AND txvurb > .2
    UNION ALL
    SELECT 'AUTRE/?' AS nature, geom FROM test.surf_autre WHERE st_area(geom) >= 5e4
)
SELECT row_number() over() AS gid, nature, geom
FROM parts;

ALTER TABLE test.ocsol
ADD PRIMARY KEY (gid);

CREATE INDEX ocsol_geom_idx
ON test.ocsol USING GIST (geom);

CREATE TABLE test.missing_parts AS
WITH
grid as (
    SELECT geom
    FROM test.grid_ocs
    WHERE gid = 1
),
diff AS (
    SELECT st_difference((SELECT geom FROM grid), safe_union(a.geom)) AS geom
    FROM test.ocsol a
),
parts AS (
    SELECT (st_dump(geom)).geom
    FROM diff
)
SELECT row_number() over() AS gid, geom
FROM parts;