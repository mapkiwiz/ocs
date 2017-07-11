ALTER TABLE test.surf_construite_snapped
ADD PRIMARY KEY (gid);

CREATE TABLE test.surf_construite_nofor AS
WITH
foret AS (
    SELECT geom
    FROM test.surf_foret_snapped
    WHERE st_area(geom) >= 5000
),
diff AS (
    SELECT a.gid, coalesce(st_difference(a.geom, st_union(b.geom)), a.geom) AS geom
    FROM test.surf_construite_snapped a
    LEFT JOIN foret b ON st_intersects(a.geom, b.geom)
    GROUP BY a.gid
),
parts AS (
    SELECT (st_dump(geom)).geom
    FROM diff
)
SELECT row_number() over() AS gid, geom
FROM parts;

ALTER TABLE test.surf_foret_snapped
ADD PRIMARY KEY (gid);

CREATE TABLE test.surf_foret_noco AS
WITH
diff AS (
    SELECT a.gid, coalesce(st_difference(a.geom, st_union(b.geom)), a.geom) AS geom
    FROM test.surf_foret_snapped a
    LEFT JOIN test.surf_construite_nofor b ON st_intersects(a.geom, b.geom)
    GROUP BY a.gid
),
parts AS (
    SELECT (st_dump(geom)).geom
    FROM diff
)
SELECT row_number() over() AS gid, geom
FROM parts;