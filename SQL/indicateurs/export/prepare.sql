CREATE TABLE ind.grid_500m_dept_rel AS
SELECT DISTINCT a.gid, b.depart AS dept
FROM ind.grid_500m a
INNER JOIN bdt.bdt_commune b ON st_intersects(a.geom, b.geom);