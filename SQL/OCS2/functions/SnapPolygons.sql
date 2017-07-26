CREATE OR REPLACE FUNCTION SnapPolygons(ageom geometry(Polygon), bgeom geometry(Polygon), tolerance double precision)
RETURNS geometry(Polygon)
AS
$func$
DECLARE

    bgeom_l geometry;
    result geometry;

BEGIN

    -- IF ST_IsEmpty(bgeom) OR ST_IsEmpty(ageom)

    bgeom_l := ST_Boundary(bgeom);

    WITH
    segments_ AS (
        SELECT disaggregate((ST_Dump(ST_Boundary(ageom))).geom, tolerance) AS geom
    ),
    segments AS (
        SELECT row_number() over() AS gid, geom
        FROM segments_
    ),
    measures AS (
        SELECT gid, min(ST_Distance(ST_Centroid(geom), bgeom_l)) as bdist
        FROM segments
        GROUP BY gid
    ),
    close_segments AS (
        SELECT a.gid, a.geom, b.bdist
        FROM segments a INNER JOIN measures b
             ON a.gid = b.gid
        WHERE b.bdist <= tolerance
    ),
    buffers_ AS (
        SELECT (ST_Dump(ST_Union(ST_Buffer(geom, 2*bdist)))).geom
        FROM close_segments
    ),
    buffers AS (
        SELECT geom FROM buffers_
        -- Filter by polygon 'length'
        WHERE (ST_Perimeter(geom) / 2) > 6*tolerance
        -- Filter by polygon size
        -- WHERE ST_Area(geom) > 8*tolerance*tolerance
    ),
    -- clip AS (
    --     SELECT (ST_Dump(ST_Intersection(geom, bgeom))).geom
    --     FROM buffers
    --     WHERE ST_Intersects(geom, bgeom)
    -- ),
    parts AS (
        SELECT geom FROM buffers -- WHERE NOT ST_IsEmpty(geom)
        UNION ALL
        SELECT ageom 
    ),
    fusion AS (
        SELECT (ST_Dump(ST_Union(geom))).geom
        FROM parts
    ),
    clip AS (
        SELECT (ST_Dump(ST_Intersection(geom, bgeom))).geom
        FROM fusion
    )
    SELECT geom FROM clip
    ORDER BY ST_Area(geom) DESC
    LIMIT 1
    INTO result;

    -- RETURN result;

    IF result IS NOT NULL
    THEN
        RETURN result;
    ELSE
        RAISE NOTICE 'Empty snap result';
        RETURN NULL;
    END IF;

    EXCEPTION
        WHEN OTHERS THEN
        RAISE NOTICE 'TopologyException';
        RETURN NULL;

END
$func$
LANGUAGE plpgsql STRICT IMMUTABLE;

CREATE OR REPLACE FUNCTION SnapPolygonsWithFallback(ageom geometry(Polygon), bgeom geometry(Polygon), tolerance double precision)
RETURNS geometry(Polygon)
AS
$func$
DECLARE
BEGIN
    
    RETURN COALESCE(
            COALESCE(
                SnapPolygons(ageom, bgeom, tolerance),
                SnapPolygons(ageom, bgeom, 2*tolerance)
            ),
            ageom);

END
$func$
LANGUAGE plpgsql STRICT IMMUTABLE;