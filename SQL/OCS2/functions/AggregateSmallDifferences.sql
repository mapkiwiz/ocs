CREATE OR REPLACE FUNCTION AggregateSmallDifferences(ageom geometry(Polygon), bgeom geometry(Polygon),
	area_tolerance double precision, width_tolerance double precision)
RETURNS geometry
AS
$func$
DECLARE

	result geometry;

BEGIN

	WITH
	small_diff AS (
        SELECT (ST_Dump(ST_Difference(bgeom, ageom))).geom
    ),
    parts AS (
        SELECT geom FROM small_diff
        WHERE ST_Area(geom) < area_tolerance
              OR ( 2 * ST_Area(geom) / ST_Perimeter(geom) < width_tolerance)
        UNION ALL
        SELECT ageom AS geom
    )
    SELECT ST_Union(geom)
    FROM parts
    INTO result;

    EXCEPTION
        WHEN OTHERS THEN
        RAISE NOTICE 'TopologyException';
        RETURN NULL;

END
$func$
LANGUAGE plpgsql STRICT IMMUTABLE;