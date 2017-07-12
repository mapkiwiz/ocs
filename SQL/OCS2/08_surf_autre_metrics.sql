SET search_path = test, ocs, public;

--
-- Calcul des caractéristiques des micropolygones et des surfaces autres
--

-- Croisement avec la couche BDT Zone de végétation (bdt_zone_vegetation)

ALTER TABLE surf_autre
ADD COLUMN txfor double precision;

WITH
surface AS (
	SELECT a.gid, sum(st_area(safe_intersection(a.geom, b.geom))) as for
	FROM surf_autre a
	LEFT JOIN bdt.bdt_zone_vegetation b ON st_intersects(a.geom, b.geom)
	GROUP BY a.gid
)
UPDATE surf_autre
SET txfor = coalesce(surface.for, 0) / st_area(surf_autre.geom)
FROM surface
WHERE surf_autre.gid = surface.gid;

-- Taux de voisinage urbanisé

ALTER TABLE surf_autre
ADD COLUMN txvurb double precision;

WITH
vurb AS (
    SELECT gid, st_buffer(geom, 20) AS geom
    FROM surf_autre
),
surface AS (
    SELECT a.gid, st_area(a.geom) AS varea, sum(st_area(st_intersection(a.geom, b.geom))) as for
    FROM vurb a
    LEFT JOIN surf_construite b ON st_intersects(a.geom, b.geom)
    GROUP BY a.gid, a.geom
)
UPDATE surf_autre
SET txvurb = coalesce(surface.for, 0) / (surface.varea - st_area(surf_autre.geom))
FROM surface
WHERE surf_autre.gid = surface.gid;

-- Taux d'infrastructure dans le voisinage

ALTER TABLE surf_autre
ADD COLUMN txinfra double precision;

WITH
vurb AS (
    SELECT gid, st_buffer(geom, 20) AS geom
    FROM surf_autre
),
surface AS (
    SELECT a.gid, sum(st_area(a.geom)) AS varea, sum(st_area(st_intersection(a.geom, b.geom))) as infra
    FROM vurb a
    LEFT JOIN surf_infra b ON st_intersects(a.geom, b.geom)
    GROUP BY a.gid
)
UPDATE surf_autre
SET txinfra = coalesce(surface.infra, 0) / (surface.varea - st_area(surf_autre.geom))
FROM surface
WHERE surf_autre.gid = surface.gid;

-- Taux de surface en eau dans le voisinage

ALTER TABLE surf_autre
ADD COLUMN txveau double precision;

WITH
vurb AS (
    SELECT gid, st_buffer(geom, 20) AS geom
    FROM surf_autre
),
surface AS (
    SELECT a.gid, sum(st_area(a.geom)) AS varea, sum(st_area(st_intersection(a.geom, b.geom))) as eau
    FROM vurb a
    LEFT JOIN surf_eau b ON st_intersects(a.geom, b.geom)
    GROUP BY a.gid
)
UPDATE surf_autre
SET txveau = coalesce(surface.eau, 0) / (surface.varea - st_area(surf_autre.geom))
FROM surface
WHERE surf_autre.gid = surface.gid;