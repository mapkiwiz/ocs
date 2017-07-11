CREATE TABLE test.surf_ouverte AS
WITH
foret AS (
    SELECT geom
    FROM test.surf_foret_snapped
    WHERE st_area(geom) >= 2500
),
diff AS (
    SELECT a.gid, coalesce(safe_difference(a.geom, safe_union(b.geom)), a.geom) AS geom
    FROM test.surf_nino a LEFT JOIN foret b ON st_intersects(a.geom, b.geom)
    GROUP BY a.gid
),
parts AS (
    SELECT (st_dump(geom)).geom
    FROM diff
)
SELECT row_number() over() AS gid, geom, st_area(geom), st_geometrytype(geom)
FROM parts
WHERE ST_GeometryType(geom) = 'ST_Polygon'
      AND st_area(geom) >= 2500;

ALTER TABLE test.surf_ouverte
ADD PRIMARY KEY (gid);

CREATE INDEX surf_ouverte_geom_idx
ON test.surf_ouverte USING GIST (geom);

CREATE OR REPLACE FUNCTION SnapOnSurfOuverte(ageom geometry, area_tolerance double precision, width_tolerance double precision)
RETURNS geometry
AS
$func$
DECLARE

    temp geometry;
    target geometry;

BEGIN

    temp := ageom;

    WITH
    small_diff AS (
        SELECT (ST_Dump(ST_Difference(b.geom, ageom))).geom
        FROM test.surf_ouverte b
        WHERE st_contains(b.geom, st_centroid(ageom))
    ),
    parts AS (
        SELECT geom FROM small_diff
        WHERE st_area(geom) < area_tolerance
              OR ( 2 * st_area(geom) / st_perimeter(geom) < width_tolerance)
        UNION ALL SELECT ageom AS geom
    )
    SELECT st_union(geom)
    FROM parts
    INTO temp;

    RETURN temp;

END
$func$
LANGUAGE plpgsql IMMUTABLE STRICT;
