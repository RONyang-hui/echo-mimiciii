-- 删除已存在的名为 "drugs" 的物化视图
drop materialized view if exists drugs;

-- 创建名为 "drugs" 的物化视图

-- 使用公共表达式 "drug_cv"，从 "inputevents_cv" 表选择相关数据并标记药物为 "sedative"
with drug_cv as (
    select icustay_id, charttime,
           case when itemid in (30124, 30150, 30308, 30118, 30149, 30131) then 'sedative' else null end as label
    from inputevents_cv
),

-- 使用公共表达式 "drug_mv"，从 "inputevents_mv" 表选择相关数据并标记药物为 "sedative"
drug_mv as (
    select icustay_id, starttime, endtime,
           case when itemid in (221668, 221744, 225972, 225942, 222168) then 'sedative' else null end as label
    from inputevents_mv
),

-- 使用公共表达式 "drug"，根据 "cohort" 表和之前的公共表达式 "drug_cv" 和 "drug_mv" 进行关联，生成 "label" 列
drug as (
    select co.icustay_id, coalesce(dm.label, dc.label) as label
    from cohort co
    left join drug_cv dc on dc.icustay_id = co.icustay_id
        and dc.label is not null
        and dc.charttime between co.intime and co.outtime
        and dc.charttime between co.intime and co.intime + interval '1' day
    left join drug_mv dm on dm.icustay_id = co.icustay_id
        and dm.label is not null
        and dm.starttime <= co.outtime
        and dm.starttime <= co.intime + interval '1' day
        and dm.endtime >= co.intime
),

-- 使用公共表达式 "drug_unpivot"，对 "drug" 表进行聚合并转换为长格式，生成 "sedative" 标志列
drug_unpivot as (
    select icustay_id,
        max(case when label = 'sedative' then 1 else 0 end) as sedative
    from drug
    group by icustay_id
)

-- 从 "drug_unpivot" 物化视图中选择所有列
select * from drug_unpivot;