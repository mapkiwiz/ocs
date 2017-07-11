-- RemoveHoles
--
CREATE OR REPLACE FUNCTION removeHoles(geom geometry(Polygon))
RETURNS geometry(Polygon)
AS
$func$
DECLARE

    g geometry;
    p integer[];

BEGIN

    FOR p, g IN SELECT * FROM st_dumpRings(geom) LOOP
        IF p[1] = 0 THEN
            RETURN g;
        END IF;
    END LOOP;

END
$func$
LANGUAGE plpgsql;

-- ExtractHoles
--
CREATE OR REPLACE FUNCTION extractHoles(geom geometry(Polygon), min_area double precision DEFAULT 0)
RETURNS SETOF geometry(Polygon)
AS
$func$
DECLARE

    g geometry;
    p integer[];

BEGIN

    FOR p, g IN SELECT * FROM st_dumpRings(geom) LOOP
        IF p[1] != 0 AND st_area(g) > min_area THEN
            RETURN NEXT g;
        END IF;
    END LOOP;

END
$func$
LANGUAGE plpgsql;

-- RemoveHoles with area threshold
--
CREATE OR REPLACE FUNCTION removeHoles(geom geometry(Polygon), min_area double precision)
RETURNS geometry(Polygon)
AS
$func$
DECLARE

    exterior_ring geometry;
    ring geometry;
    interior_rings geometry[];

BEGIN

    IF ST_NumInteriorRings(geom) = 0 THEN
        RETURN geom;
    ELSE
        exterior_ring := ST_ExteriorRing(geom);
        interior_rings := array(SELECT ST_ExteriorRing(extractHoles(geom, min_area)));
        IF array_length(interior_rings, 1) = 0 THEN
            RETURN exterior_ring;
        ELSE
            RETURN ST_MakePolygon(exterior_ring, interior_rings);
        END IF;
    END IF;

END
$func$
LANGUAGE plpgsql;