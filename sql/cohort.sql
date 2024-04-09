-- 如果存在名为population的表，先删除该表
DROP TABLE IF EXISTS cohort;
-- 创建名为population的表，用于存储结果数据
CREATE TABLE cohort AS
select distinct *,
    case when echo_time is null then 0 else 1 end as echo
from population
left join (select subject_id, hadm_id, icustay_id from icustays) icu using (icustay_id)
where angus = 1
and age >= 18
and icu_order = 1
and first_careunit in ('MICU', 'SICU')
and echo_include = 1;




CREATE TABLE cohort AS
select *,
    case when chartdate is null then 0 else 1 end as echo
from population
left join (select subject_id, hadm_id, icustay_id from icustays) icu using (icustay_id)
where angus = 1 #筛选免疫性疾病
and age >= 10
and icu_order = 1
and first_careunit in ('MICU', 'SICU')
and echo_include = 1; drug = 'Hydroxychloroquine Sulfate'
