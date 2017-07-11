CREATE TABLE test.surf_agricole AS
WITH
agricole AS (
    SELECT geom FROM test.surf_prairie
    UNION ALL
    SELECT geom FROM test.surf_cultures
    UNION ALL
    SELECT geom FROM test.surf_arboriculture
)
SELECT row_number() over() AS gid, geom
FROM agricole;

ALTER TABLE test.surf_agricole
ADD PRIMARY KEY (gid);

CREATE INDEX surf_agricole_geom_idx
ON test.surf_agricole USING GIST (geom);

CREATE TABLE test.surf_non_agricole AS
WITH
diff AS (
    SELECT a.gid, coalesce(safe_difference(a.geom, safe_union(b.geom)), a.geom) AS geom
    FROM test.surf_ouverte a LEFT JOIN test.surf_agricole b ON st_intersects(a.geom, b.geom)
    GROUP BY a.gid
),
parts AS (
    SELECT (st_dump(geom)).geom
    FROM diff
)
SELECT row_number() over() AS gid, geom, st_area(geom), st_geometrytype(geom)
FROM parts
WHERE ST_GeometryType(geom) = 'ST_Polygon';

ALTER TABLE test.surf_non_agricole
ADD PRIMARY KEY (gid);

CREATE INDEX surf_non_agricole_geom_idx
ON test.surf_non_agricole USING GIST (geom);

CREATE TABLE test.surf_autre AS
WITH
diff AS (
    SELECT a.gid, coalesce(safe_difference(a.geom, safe_union(b.geom)), a.geom) AS geom
    FROM test.surf_non_agricole a LEFT JOIN test.surf_construite b ON st_intersects(a.geom, b.geom)
    GROUP BY a.gid
),
parts AS (
    SELECT (st_dump(geom)).geom
    FROM diff
)
SELECT row_number() over() AS gid, geom, st_area(geom) AS area
FROM parts
WHERE ST_GeometryType(geom) = 'ST_Polygon';

-- Calcul des caractéristiques des micropolygones et des surfaces autres

ALTER TABLE test.surf_autre
ADD PRIMARY KEY (gid);

CREATE INDEX surf_autre_geom_idx
ON test.surf_autre USING GIST (geom);

-- Croisement avec la couche BDT Zone de végétation (bdt_zone_vegetation)

ALTER TABLE test.surf_autre
ADD COLUMN txfor double precision;

WITH
surface AS (
	SELECT a.gid, sum(st_area(safe_intersection(a.geom, b.geom))) as for
	FROM test.surf_autre a
	LEFT JOIN bdt.bdt_zone_vegetation b ON st_intersects(a.geom, b.geom)
	GROUP BY a.gid
)
UPDATE test.surf_autre
SET txfor = coalesce(surface.for, 0) / st_area(surf_autre.geom)
FROM surface
WHERE surf_autre.gid = surface.gid;

-- Taux de voisinage urbanisé

ALTER TABLE test.surf_autre
ADD COLUMN txvurb double precision;

WITH
vurb AS (
    SELECT gid, st_buffer(geom, 20) AS geom
    FROM test.surf_autre
),
surface AS (
    SELECT a.gid, st_area(a.geom) AS varea, sum(st_area(st_intersection(a.geom, b.geom))) as for
    FROM vurb a
    LEFT JOIN test.surf_construite b ON st_intersects(a.geom, b.geom)
    GROUP BY a.gid, a.geom
)
UPDATE test.surf_autre
SET txvurb = coalesce(surface.for, 0) / (surface.varea - st_area(surf.autre.geom))
FROM surface
WHERE surf_autre.gid = surface.gid;

-- Taux d'infrastructure dans le voisinage

ALTER TABLE test.surf_autre
ADD COLUMN txinfra double precision;

WITH
vurb AS (
    SELECT gid, st_buffer(geom, 20) AS geom
    FROM test.surf_autre
),
surface AS (
    SELECT a.gid, sum(st_area(a.geom)) AS varea, sum(st_area(st_intersection(a.geom, b.geom))) as infra
    FROM vurb a
    LEFT JOIN test.surf_infra b ON st_intersects(a.geom, b.geom)
    GROUP BY a.gid
)
UPDATE test.surf_autre
SET txinfra = coalesce(surface.infra, 0) / (surface.varea - st_area(surf.autre.geom))
FROM surface
WHERE surf_autre.gid = surface.gid;

-- Taux de surface en eau dans le voisinage

ALTER TABLE test.surf_autre
ADD COLUMN txveau double precision;

WITH
vurb AS (
    SELECT gid, st_buffer(geom, 20) AS geom
    FROM test.surf_autre
),
surface AS (
    SELECT a.gid, sum(st_area(a.geom)) AS varea, sum(st_area(st_intersection(a.geom, b.geom))) as eau
    FROM vurb a
    LEFT JOIN test.surf_eau b ON st_intersects(a.geom, b.geom)
    GROUP BY a.gid
)
UPDATE test.surf_autre
SET txveau = coalesce(surface.eau, 0) / (surface.varea - st_area(surf.autre.geom))
FROM surface
WHERE surf_autre.gid = surface.gid;