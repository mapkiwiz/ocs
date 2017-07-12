WITH
next_cell AS (
    SELECT nextval('ocs.carto_cell_seq'::regclass) AS cell
)
INSERT INTO ocs.carto (cell, nature, area, geom)
SELECT (SELECT cell FROM next_cell) AS cell, nature, st_area(geom) as area, geom
FROM test.ocsol_cleaned;