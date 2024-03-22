select *,
    case when chartdate is null then 0 else 1 end as echo
from population
left join (select subject_id, hadm_id, icustay_id from icustays) icu using (icustay_id)
where angus = 1
and age >= 18
and icu_order = 1
and first_careunit in ('MICU', 'SICU')
and echo_include = 1;





CREATE TABLE population AS
SELECT *
FROM population
JOIN icustay_detail
USING (subject_id, hadm_id, icustay_id);



select icustay_id,
   rank() over (partition by subject_id order by intime) as icu_order from icustays
