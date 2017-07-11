CREATE OR REPLACE FUNCTION test.SnapOnNonInfra(ageom geometry, area_tolerance double precision, width_tolerance double precision)
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
        FROM test.surf_non_infra b
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