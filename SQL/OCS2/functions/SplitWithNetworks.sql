CREATE OR REPLACE FUNCTION SplitWithNetworks(ageom geometry)
RETURNS SETOF geometry
AS
$func$
DECLARE

    ls geometry;
    t geometry;

BEGIN

    t := ageom;

    FOR ls IN
        WITH
        lines AS (
            SELECT geom FROM bdt.bdt_route r
            WHERE st_intersects(r.geom, ageom)
                   AND r.nature NOT IN ('Sentier', 'Escalier', 'Chemin')
            UNION ALL
            SELECT geom FROM bdt.bdt_troncon_voie_ferree r
            WHERE st_intersects(r.geom, ageom)
            UNION ALL
            SELECT geom FROM bdt.bdt_troncon_cours_eau r
            WHERE st_intersects(r.geom, ageom)
                  AND r.regime = 'Permanent'
        )
        SELECT (ST_Dump(geom)).geom
        FROM lines
    LOOP

        t := ST_Split(t, ls);

    END LOOP;

    RETURN QUERY
    WITH parts AS (
        SELECT (ST_Dump(t)).geom
    )
    SELECT geom
    FROM parts
    WHERE ST_GeometryType(geom) = 'ST_Polygon';


END
$func$
LANGUAGE plpgsql VOLATILE STRICT;