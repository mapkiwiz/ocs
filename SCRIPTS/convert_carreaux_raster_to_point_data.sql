create table ref.insee_pop_2010_200m_v as
with pixels as ( 
	select ST_PixelAsPolygons(rast) as p from ref.insee_pop_2010_200m
)
select row_number() over() as gid, (pixels.p).val as pop,  st_centroid((pixels.p).geom) as geom
from pixels;

alter table ref.insee_pop_2010_200m_v
add primary key (gid) ;

create index insee_pop_2010_200m_v_geom_idx
on ref.insee_pop_2010_200m_v using gist (geom) ;