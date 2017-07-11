CREATE OR REPLACE FUNCTION ind.t_expo(expo double precision)
RETURNS varchar(2)
AS
$func$
DECLARE
BEGIN

    CASE
        WHEN expo < 24.5 THEN RETURN 'N';
        WHEN expo < 69.5 THEN RETURN 'NE';
        WHEN expo < 114.5 THEN RETURN 'E';
        WHEN expo < 159.5 THEN RETURN 'SE';
        WHEN expo < 204.5 THEN RETURN 'S';
        WHEN expo < 249.5 THEN RETURN 'SW';
        WHEN expo < 294.5 THEN RETURN 'W';
        WHEN expo < 339.5 THEN RETURN 'NW';
        ELSE RETURN 'N';
    END CASE;

END
$func$
LANGUAGE plpgsql IMMUTABLE STRICT;

CREATE OR REPLACE VIEW ind.relief AS
SELECT gid,
       alti_mean as alt_moy, 
       alti_min as alt_min,
       alti_max as alt_max,
       profil_mea as pente,
       expo_mean as expo,
       ind.t_expo(expo_mean) as t_expo,
       tpi300_mea as tpi_300,
       tpi1000_me as tpi_1000, 
       tpi2000_me as tpi_2000
  FROM ind.relief_cantal;

CREATE OR REPLACE VIEW ind.ocsol AS
WITH
clc1 AS (
    SELECT *
    FROM ind.clc_2012_cantal
    WHERE surf_rank = 1
),
clc2 AS (
    SELECT *
    FROM ind.clc_2012_cantal
    WHERE surf_rank = 2
),
foret AS (
    SELECT *
    FROM ind.foret_type_dominant_cantal
    WHERE surf_rank = 1
)
SELECT a.cid as gid,
       a.surf_arboriculture as a_arbo,
       a.surf_cultures as a_cult,
       a.surf_prairie as a_prair,
       a.surf_autre as a_autre, 
       a.surf_foret as a_for,
       a.surf_eau as a_eau,
       a.surf_construite as a_cons,
       a.surf_ouverte as a_ouv,
       a.surf_totale as a_total,
       coalesce(b.code_12, 'NA') as clc1,
       coalesce(b.surf_ha, 0) as a_clc1,
       coalesce(c.code_12, 'NA') as clc2,
       coalesce(d.nature, 'SANS FORET') as t_for,
       coalesce(d.surf_ha, 0) as a_t_for
  FROM ind.ct_ocsol_cantal a
       LEFT JOIN clc1 b ON a.cid = b.cid
       LEFT JOIN clc2 c ON a.cid = c.cid
       LEFT JOIN foret d ON a.cid = d.cid;

CREATE OR REPLACE VIEW ind.eco_paysage AS
SELECT a.gid,
       coalesce(b.length_m, 0) as l_cde,
       coalesce(c.length_m, 0) as l_drain,
       coalesce(d.length_m, 0) as l_ecofor,
       coalesce(e.length_m, 0) as l_haie,
       coalesce(f.num_obj, 0) as h_clc,
       coalesce(g.num_obj, 0) as h_for,
       coalesce(h.value, 0) as shdi_for,
       coalesce(i.num_obj, 0) as m_foret,
       coalesce(j.num_obj, 0) as m_ouvert,
       coalesce(k.num_obj, 0) as m_urbain
    FROM ind.grid_500m a
        LEFT JOIN ind.cde_principal_longueur_cantal b ON a.gid = b.cid
        LEFT JOIN ind.densite_drainage_cantal c ON a.gid = c.cid
        LEFT JOIN ind.ecotone_foret_longueur_cantal d ON a.gid = d.cid
        LEFT JOIN ind.haie_longueur_cantal e ON a.gid = e.cid
        LEFT JOIN ind.clc_frag_cantal f ON a.gid = f.cid
        LEFT JOIN ind.foret_frag_cantal g ON a.gid = g.cid
        LEFT JOIN ind.foret_frag_shannon_cantal h ON a.gid = h.cid
        LEFT JOIN ind.patch_foret_cantal i ON a.gid = i.cid
        LEFT JOIN ind.patch_ouvert_cantal j ON a.gid = j.cid
        LEFT JOIN ind.patch_urbain_cantal k ON a.gid = k.cid
    WHERE a.dept = 'CANTAL';

CREATE OR REPLACE VIEW ind.zonages_1 AS
SELECT a.gid,
    b.in_contr,
    b.in_sage,
    b.in_scot,
    c.code_her1 as her1,
    c.code_her2 as her2
    FROM ind.grid_500m a
         LEFT JOIN ind.ct_zonages_presence_cantal b ON a.gid = b.cid
         LEFT JOIN ind.her_cantal c ON a.gid = c.cid
    WHERE a.dept = 'CANTAL';