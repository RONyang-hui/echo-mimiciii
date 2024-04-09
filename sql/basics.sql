-- 删除名为'basics'的物化视图，如果存在的话
drop materialized view if exists basics cascade;

-- 创建名为'basics'的物化视图
create materialized view basics as
with vasofirstday as (
    -- 计算患者在icu首日是否接受了血管活性药物
    select icustay_id,
           max(case when starttime between intime and intime + interval '1 day' and
               starttime <= outtime then 1 else 0 end) as vaso
    from mimiciii.cohort
    left join mimiciii.vasopressordurations using (icustay_id)
    group by icustay_id
)

, icu_adm_wday as (
    -- 提取每位患者的icu入院日期和时间中的星期几和小时
    select icustay_id,
           extract(dow from intime) as icu_adm_weekday,
           extract(hour from intime) as icu_adm_hour
    from mimiciii.cohort
)

, mort as (
    -- 从'mimiciii.admissions'和'mimiciii.patients'表中检索每位患者的死亡时间
    select co.hadm_id,
           coalesce(adm.deathtime, pat.dod, null) as deathtime
    from mimiciii.cohort co
    left join (select hadm_id, deathtime from mimiciii.admissions) adm using (hadm_id)
    left join mimiciii.patients pat using (subject_id)
)
, mort_28 as (
    -- 确定患者是否在icu入院后的28天内死亡
    select hadm_id,
           case when deathtime <= (co.intime + interval '28' day) then 1 else 0 end as mort_28_day
    from mimiciii.cohort co
    natural left join mort
)
, basics as (
    -- 将所有计算指标与原始患者信息结合，创建综合数据集
    select *,
           extract(epoch from (outtime - intime))/24.0/60.0/60.0 as icu_los_day
    from mimiciii.cohort co
    natural left join (select subject_id, gender from mimiciii.patients) g
    natural left join (select icustay_id, weight from mimiciii.weightfirstday) w
    natural left join (select icustay_id, saps from mimiciii.saps) sa
    natural left join (select icustay_id, sofa from mimiciii.sofa) so
    natural left join (select hadm_id, elixhauser_vanwalraven as elix_score
                       from mimiciii.elixhauser_ahrq_score) elix
    natural left join (select icustay_id, vent from mimiciii.ventfirstday) vent
    natural left join vasofirstday
    natural left join icu_adm_wday
    natural left join mort
    natural left join mort_28
)
-- 检索所有列，返回完整的数据集
select * from basics;