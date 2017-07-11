SET search_path = test, ocs, public;


CREATE TABLE surf_construite_nino AS
WITH
intersection AS (
    SELECT (st_dump(st_intersection(a.geom, b.geom))).geom
    FROM surf_construite a LEFT JOIN surf_nino b
    ON st_intersects(a.geom, b.geom)
)
SELECT row_number() over() AS gid, geom
FROM intersection;

CREATE TABLE surf_construite_snapped AS
WITH
parts AS (
    SELECT SnapOnNino(2500, 5) as geom
)
SELECT row_number() over() AS gid, geom
FROM parts;