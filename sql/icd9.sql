DROP MATERIALIZED VIEW IF EXISTS icd9;
CREATE MATERIALIZED VIEW icd9 AS
WITH icd9 AS (
    SELECT hadm_id,
           MAX(CASE WHEN icd9_code IN
               ('39891','40201','40291','40491', '40413', '40493',
                '4280', '4281', '42820', '42821', '42822', '42823',
                '42830', '42831', '42832', '42833', '42840', '42841',
                '42842', '42843', '4289', '428', '4282', '4283', '4284')
               THEN 1 ELSE 0 END) AS icd_chf,
           MAX(CASE WHEN icd9_code LIKE '4273%' THEN 1 ELSE 0 END) AS icd_afib,
           MAX(CASE WHEN icd9_code LIKE '585%' THEN 1 ELSE 0 END) AS icd_renal,
           MAX(CASE WHEN icd9_code LIKE '571%' THEN 1 ELSE 0 END) AS icd_liver,
           MAX(CASE WHEN icd9_code IN
               ('4660', '490', '4910', '4911', '49120',
                '49121', '4918', '4919', '4920', '4928',
                '494', '4940', '4941', '496')
               THEN 1 ELSE 0 END) AS icd_copd,
           MAX(CASE WHEN icd9_code LIKE '414%' THEN 1 ELSE 0 END) AS icd_cad,
           MAX(CASE WHEN icd9_code LIKE '430%'
               OR icd9_code LIKE '431%'
               OR icd9_code LIKE '432%'
               OR icd9_code LIKE '433%'
               OR icd9_code LIKE '434%'
               THEN 1 ELSE 0 END) AS icd_stroke,
           MAX(CASE WHEN icd9_code BETWEEN '140' AND '239' THEN 1 ELSE 0 END) AS icd_malignancy
    FROM diagnoses_icd
    GROUP BY hadm_id
)

, icd9_cohort AS (
    SELECT *
    FROM (SELECT hadm_id FROM cohort) co
    LEFT JOIN icd9 USING (hadm_id)
)

SELECT * FROM icd9_cohort;






with angus_group as (
    select icustay_id, hadm_id, mimiciii.angus.angus
    from icustays
    left join angus using (hadm_id)
)

, icu_age_raw as (
    select icustay_id,
        extract('epoch' from (intime - dob)) / 60.0 / 60.0 / 24.0 / 365.242 as age
    from icustays
    left join patients using (subject_id)
)

, icu_age as (
    select icustay_id,
        case when age >= 130 then 91.5 else age end as age
    from icu_age_raw
)

, icu_order as (
    select icustay_id,
        rank() over (partition by subject_id order by intime) as icu_order
    from icustays
)

, echo as (
    select hadm_id, chartdate as echo_time
    from noteevents
    where lower(category) like 'echo'
    and lower(description) like 'report'
)

, echo_exclude as (
    select icustay_id,
        case when bool_and(echo_time < date_trunc('day', intime - interval '1' day) or echo_time > outtime) then 1 else 0 end as echo_exclude
    from icustays left join echo using (hadm_id)
    group by icustay_id
)

, echo_include as (
    select icustay_id,
        case when bool_and(echo_time is null)
        or bool_or(echo_time between date_trunc('day', intime - interval '1' day) and outtime) then 1 else 0 end as echo_include
    from icustays left join echo using (hadm_id)
    group by icustay_id
)

, echo_first as (
    select icustay_id, min(echo_time) as echo_time
    from icustays left join echo ec using (hadm_id)
    where echo_time between date_trunc('day', intime - interval '1' day) and outtime
    group by icustay_id
)

, population as (
    select *
    from (select distinct icustay_id, first_careunit, intime, outtime from icustays) a
    left join angus_group using (icustay_id)
    left join icu_age using (icustay_id)
    left join icu_order using (icustay_id)
    left join echo_first using (icustay_id)
    left join echo_exclude using (icustay_id)
    left join echo_include using (icustay_id)

)

select population.hadm_id, *,
    CASE WHEN echo_time IS NULL THEN 0 ELSE 1 END AS echo
FROM population
LEFT JOIN (SELECT subject_id, hadm_id, icustay_id FROM icustays) icu USING (icustay_id)
WHERE angus = 1
AND age >= 18
AND icu_order = 1
AND first_careunit IN ('MICU', 'SICU')
AND echo_include = 1;





