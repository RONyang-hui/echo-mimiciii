with vasofirstday as (
    select icustay_id,
           max(case when starttime between intime and intime + interval '1 day' and
               starttime <= outtime then 1 else 0 end) as vaso
    from cohort
    left join vasopressordurations using (icustay_id)
    group by icustay_id
)

, icu_adm_wday as (
    select icustay_id,
           extract(dow from intime) as icu_adm_weekday,
           extract(hour from intime) as icu_adm_hour
    from cohort
)

, mort as (
    select co.hadm_id,
           coalesce(adm.deathtime, pat.dod, null) as deathtime
    from cohort co
    left join (select hadm_id, deathtime from admissions) adm using (hadm_id)
    left join patients pat using (subject_id)
)

, mort_28 as (
    select hadm_id,
           case when deathtime <= (co.intime + interval '28' day) then 1 else 0 end as mort_28_day
    from cohort co
    natural left join mort
)

, basics as (
    select *,
           extract(epoch from (outtime - intime))/24.0/60.0/60.0 as icu_los_day
    from cohort co
    natural left join (select subject_id, gender from patients) g
    natural left join (select icustay_id, weight from weightfirstday) w
    natural left join (select icustay_id, saps from saps) sa
    natural left join (select icustay_id, sofa from sofa) so
    natural left join (select hadm_id, elixhauser_vanwalraven as elix_score
                       from elixhauser_ahrq_score) elix
    natural left join (select icustay_id, vent from ventfirstday) vent
    natural left join vasofirstday
    natural left join icu_adm_wday
    natural left join mort
    natural left join mort_28
)

select * from basics;



/*
    This SQL query retrieves various patient information from the 'mimiciii.cohort' table and joins it with other tables to calculate additional metrics.
    The query includes the following CTEs (Common Table Expressions):
    
    - vasofirstday: Calculates whether a patient received vasopressor medication on their first day in the ICU.
    - icu_adm_wday: Extracts the weekday and hour of ICU admission for each patient.
    - mort: Retrieves the death time for each patient from the 'mimiciii.admissions' and 'mimiciii.patients' tables.
    - mort_28: Determines whether a patient died within 28 days of ICU admission.
    - basics: Combines all the calculated metrics with the original patient information to create a comprehensive dataset.
    
    The final SELECT statement retrieves all columns from the 'basics' CTE, returning the complete dataset.
*/

DROP MATERIALIZED VIEW IF EXISTS basics CASCADE;
CREATE MATERIALIZED VIEW basics AS
WITH vasofirstday AS (
    SELECT icustay_id,
           MAX(CASE WHEN starttime BETWEEN intime AND intime + INTERVAL '1 day' AND
               starttime <= outtime THEN 1 ELSE 0 END) AS vaso
    FROM mimiciii.cohort
    LEFT JOIN vasopressordurations USING (icustay_id)
    GROUP BY icustay_id
), icu_adm_wday AS (
    SELECT icustay_id,
           EXTRACT(DOW FROM intime) AS icu_adm_weekday,
           EXTRACT(HOUR FROM intime) AS icu_adm_hour
    FROM mimiciii.cohort
), mort AS (
    SELECT co.hadm_id,
           COALESCE(adm.deathtime, pat.dod, NULL) AS deathtime
    FROM mimiciii.cohort co
    LEFT JOIN (SELECT hadm_id, deathtime FROM mimiciii.admissions) adm USING (hadm_id)
    LEFT JOIN mimiciii.patients pat USING (subject_id)
), mort_28 AS (
    SELECT hadm_id,
           CASE WHEN deathtime <= (co.intime + INTERVAL '28' DAY) THEN 1 ELSE 0 END AS mort_28_day
    FROM mimiciii.cohort co
    NATURAL LEFT JOIN mort
), basics AS (
    SELECT DISTINCT *,
           EXTRACT(EPOCH FROM (outtime - intime))/24.0/60.0/60.0 AS icu_los_day
    FROM mimiciii.cohort co
    NATURAL LEFT JOIN (SELECT subject_id, gender FROM mimiciii.patients) g
    NATURAL LEFT JOIN (SELECT icustay_id, weight FROM mimiciii.weightfirstday) w
    NATURAL LEFT JOIN (SELECT icustay_id, saps FROM mimiciii.saps) sa
    NATURAL LEFT JOIN (SELECT icustay_id, sofa FROM mimiciii.sofa) so
    NATURAL LEFT JOIN (SELECT hadm_id, elixhauser_vanwalraven AS elix_score
                       FROM mimiciii.elixhauser_ahrq_score) elix
    NATURAL LEFT JOIN (SELECT icustay_id, vent FROM mimiciii.ventfirstday) vent
    NATURAL LEFT JOIN vasofirstday
    NATURAL LEFT JOIN icu_adm_wday
    NATURAL LEFT JOIN mort
    NATURAL LEFT JOIN mort_28
)
SELECT DISTINCT * FROM basics;



