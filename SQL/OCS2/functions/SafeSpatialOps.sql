-- http://gis.stackexchange.com/questions/50399/how-best-to-fix-a-non-noded-intersection-problem-in-postgis

CREATE OR REPLACE FUNCTION safe_intersects(geom_a geometry, geom_b geometry, tolerance double precision default 0.0000001)
RETURNS boolean AS
$$
BEGIN
    RETURN ST_Intersects(geom_a, geom_b);
    EXCEPTION
        WHEN OTHERS THEN
            BEGIN
                RETURN ST_Intersects(ST_Buffer(geom_a, tolerance), ST_Buffer(geom_b, tolerance));
                EXCEPTION
                    WHEN OTHERS THEN
                        RETURN FALSE;
    END;
END
$$
LANGUAGE 'plpgsql' STABLE STRICT;

CREATE OR REPLACE FUNCTION safe_intersection(geom_a geometry, geom_b geometry, tolerance double precision default 0.0000001)
RETURNS geometry AS
$$
BEGIN
    RETURN ST_Intersection(geom_a, geom_b);
    EXCEPTION
        WHEN OTHERS THEN
            BEGIN
                RETURN ST_Intersection(ST_Buffer(geom_a, tolerance), ST_Buffer(geom_b, tolerance));
                EXCEPTION
                    WHEN OTHERS THEN
                        RETURN ST_GeomFromText('POLYGON EMPTY');
    END;
END
$$
LANGUAGE 'plpgsql' STABLE STRICT;

CREATE OR REPLACE FUNCTION safe_difference(geom_a geometry, geom_b geometry, tolerance double precision default 0.0000001)
RETURNS geometry AS
$$
BEGIN
    RETURN ST_Difference(geom_a, geom_b);
    EXCEPTION
        WHEN OTHERS THEN
            BEGIN
                RETURN ST_Difference(ST_Buffer(geom_a, tolerance), ST_Buffer(geom_b, tolerance));
                EXCEPTION
                    WHEN OTHERS THEN
                        RETURN geom_a;
    END;
END
$$
LANGUAGE 'plpgsql' STABLE STRICT;

CREATE OR REPLACE FUNCTION safe_union(geom_a geometry, geom_b geometry, tolerance double precision default 0.0000001)
RETURNS geometry AS
$$
BEGIN
    RETURN ST_Union(geom_a, geom_b);
    EXCEPTION
        WHEN OTHERS THEN
            BEGIN
                RETURN ST_Union(ST_Buffer(geom_a, tolerance), ST_Buffer(geom_b, tolerance));
                EXCEPTION
                    WHEN OTHERS THEN
                        RETURN ST_GeomFromText('POLYGON EMPTY');
    END;
END
$$
LANGUAGE 'plpgsql' STABLE STRICT;

CREATE OR REPLACE FUNCTION safe_union(geom_a geometry, geom_b geometry)
RETURNS geometry AS
$$
DECLARE
   tolerance double precision := 0.5;
BEGIN
    RETURN ST_Union(geom_a, geom_b);
    EXCEPTION
        WHEN OTHERS THEN
            BEGIN
                RETURN ST_Union(ST_Buffer(geom_a, tolerance), ST_Buffer(geom_b, tolerance));
                EXCEPTION
                    WHEN OTHERS THEN
                        RETURN ST_GeomFromText('POLYGON EMPTY');
    END;
END
$$
LANGUAGE 'plpgsql' STABLE STRICT;

CREATE AGGREGATE safe_union(geometry(Polygon)) (
	SFUNC='safe_union',
	STYPE='geometry',
	INITCOND='POLYGON EMPTY');