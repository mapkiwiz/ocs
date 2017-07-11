-- Création d'une grille avec un pas de 500 m
-- compatible avec la grille de référence de l'Agence européenn de l'environnement (EEA)
-- http://www.eea.europa.eu/data-and-maps/data/eea-reference-grids-1

-- Prérequis :
-- création d'une table avec un polygone unique décrivant la zone à couvrir
-- dans cet exemple,
-- on a fait l'union des départements GeoFLA de la région Auvergne-Rhône-Alpes
-- dans la table ref.fla_region_aura

-- Données en entrée :
-- - zone à couvrir = ref.fla_region_aura
-- - référentiel administratif = ref.fla_departement

-- Paramètres :
-- - pas de la grille, ici 500 m
-- - largeur du tampon pour inclure les carreaux en bordure de zone, ici 5000 m (5 km)

-- Données en sortie :
-- table ref.aura_grid_500m contenant les cellules de la grille

-- étape 1 :
-- création de la grille dans le rectangle englobant de la zone à couvir

create table ref.aura_grid_500m as
with region as (
	select st_extent(st_transform(st_buffer(geom, 5000), 3035)) as extent
	from ref.fla_region_aura),
coords as (
	select ceil(st_xmax(region.extent) / 1000) * 1000 as xmax,
	       ceil(st_ymax(region.extent) / 1000) * 1000 as ymax,
	       floor(st_xmin(region.extent) / 1000) * 1000 as xmin,
	       floor(st_ymin(region.extent) / 1000) * 1000 as ymin
	from region
),
extent as (
	select st_setsrid(st_makebox2d(st_makepoint(coords.xmin, coords.ymin), st_makepoint(coords.xmax, coords.ymax)), 3035) as geom
	from coords
),
grid as (
	select st_makegrid_2d(extent.geom, 500, 500) as geom
	from extent
)
select row_number() over() as gid, st_xmin(geom) as eoforigin, st_ymin(geom) as noforigin, geom
from grid;

alter table ref.aura_grid_500m
add primary key (gid);

create index aura_grid_500m_geom_idx
on ref.aura_grid_500m using gist (geom);

-- étape 2 :
-- jointure avec la table du référentiel administratif
-- pour récuper la région et le département
-- correspondant au centroïde de chaque cellule de la grille

alter table ref.aura_grid_500m
add column region varchar(30),
add column dept varchar(30);

with match as (
	select g.gid, d.nom_region, d.nom_dept
	from ref.aura_grid_500m g
	inner join ref.fla_departement d on st_contains(st_transform(d.geom, 3035), st_centroid(g.geom))
)
update ref.aura_grid_500m
set region = match.nom_region, dept = match.nom_dept
from match
where aura_grid_500m.gid = match.gid;

-- étape 3 :
-- élimination des cellules de la grille
-- situés à plus de 5 km de la zone à couvrir

with outside as (
	select distinct g.gid
	from ref.aura_grid_500m g, ref.fla_region_aura r
	where (g.region is null or g.region not in ('AUVERGNE', 'RHONE-ALPES'))
	      and not st_dwithin(st_transform(r.geom, 3035), g.geom, 5000)
)
delete from ref.aura_grid_500m
using outside
where aura_grid_500m.gid = outside.gid;

-- une autre version de l'étape 3
-- qui pourrait être plus rapide 

-- with buffer as (
-- 	select st_transform(st_buffer(r.geom, 5000), 3035) as geom
-- 	from ref.fla_region_aura r
-- ),
-- outside as (
-- 	select distinct g.gid
-- 	from tmp.aura_grid_500m g, buffer r
-- 	where (g.region is null or g.region not in ('AUVERGNE', 'RHONE-ALPES'))
-- 	      and not st_intersects(r.geom, g.geom)
-- )
-- delete from tmp.aura_grid_500m
-- using outside
-- where aura_grid_500m.gid = outside.gid;

-- Finalement, on réécrit la table
-- en fonction de l'index spatial

cluster verbose tmp.aura_grid_500m
using aura_grid_500m_geom_idx ;
