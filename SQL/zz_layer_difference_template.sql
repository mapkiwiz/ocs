WITH
to_be_removed AS (
	SELECT a.gid, st_union(st_intersection(a.geom, b.geom)) AS geom
	FROM a INNER JOIN b ON st_intersects(a.geom, b.geom)
	GROUP BY a.gid
),
diff AS (
	SELECT a.gid, (st_dump(coalesce(st_difference(a.geom, r.geom), a.geom))).geom AS geom
	FROM a LEFT JOIN to_be_removed r ON a.gid = r.gid
)
SELECT row_number() over() as gid, diff.geom
FROM diff;