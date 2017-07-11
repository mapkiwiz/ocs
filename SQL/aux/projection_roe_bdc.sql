CREATE OR REPLACE FUNCTION snap_on_nearest_bdc_cde(pin geometry(Point), tolerance double precision)
RETURNS TABLE (geom geometry(Point), code_hydro varchar(8), distance double precision)
AS
$func$
DECLARE

    nearest_ml geometry;
    nearest_part geometry;

BEGIN

    SELECT a.code_hydro, a.geom FROM ref.bdc_cours_eau_2014 a
    ORDER BY a.geom <-> pin
    LIMIT 1
    INTO code_hydro, nearest_ml;

    IF st_distance(nearest_ml, pin) <= tolerance
    THEN

        WITH
        parts AS (
            SELECT a.geom FROM st_dump(nearest_ml) a
        )
        SELECT a.geom FROM parts a
        ORDER BY st_distance(a.geom, pin)
        LIMIT 1
        INTO nearest_part;

        geom := st_force2d(st_lineinterpolatepoint(nearest_part, st_linelocatepoint(nearest_part, pin)));
        distance := st_distance(pin, geom);
        RETURN NEXT;

    ELSE

        geom := pin;
        distance := 0.0;
        code_hydro := NULL;
        RETURN NEXT;

    END IF;

END
$func$
LANGUAGE plpgsql IMMUTABLE STRICT;

CREATE TABLE ref.bdc_roe AS
WITH
prj AS (
    SELECT gid, (snap_on_nearest_bdc_cde(geom, 50.0)).*
    FROM ref.roe
)
SELECT prj.gid, prj.geom, prj.code_hydro, prj.distance
FROM prj;

ALTER TABLE ref.bdc_roe
ADD PRIMARY KEY (gid);

CREATE INDEX bdc_roe_geom_idx
ON ref.bdc_roe (geom);