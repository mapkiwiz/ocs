CREATE TABLE surf_agricole AS
WITH
agricole AS (
    SELECT geom FROM surf_prairie
    UNION ALL
    SELECT geom FROM surf_cultures
    UNION ALL
    SELECT geom FROM surf_arboriculture
)
SELECT row_number() over() AS gid, geom
FROM agricole;

ALTER TABLE surf_agricole
ADD PRIMARY KEY (gid);

CREATE INDEX surf_agricole_geom_idx
ON surf_agricole USING GIST (geom);

CREATE TABLE surf_non_agricole AS
WITH
diff AS (
    SELECT a.gid, coalesce(safe_difference(a.geom, safe_union(b.geom)), a.geom) AS geom
    FROM surf_ouverte a LEFT JOIN surf_agricole b ON st_intersects(a.geom, b.geom)
    GROUP BY a.gid
),
parts AS (
    SELECT (st_dump(geom)).geom
    FROM diff
)
SELECT row_number() over() AS gid, geom, st_area(geom), st_geometrytype(geom)
FROM parts
WHERE ST_GeometryType(geom) = 'ST_Polygon';

ALTER TABLE surf_non_agricole
ADD PRIMARY KEY (gid);

CREATE INDEX surf_non_agricole_geom_idx
ON surf_non_agricole USING GIST (geom);

CREATE TABLE surf_autre AS
WITH
diff AS (
    SELECT a.gid, coalesce(safe_difference(a.geom, safe_union(b.geom)), a.geom) AS geom
    FROM surf_non_agricole a LEFT JOIN surf_construite b ON st_intersects(a.geom, b.geom)
    GROUP BY a.gid
),
parts AS (
    SELECT (st_dump(geom)).geom
    FROM diff
)
SELECT row_number() over() AS gid, geom, st_area(geom) AS area
FROM parts
WHERE ST_GeometryType(geom) = 'ST_Polygon';

ALTER TABLE surf_autre
ADD PRIMARY KEY (gid);

CREATE INDEX surf_autre_geom_idx
ON surf_autre USING GIST (geom);