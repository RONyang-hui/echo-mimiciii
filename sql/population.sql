-- 如果存在名为population的表，先删除该表
DROP TABLE IF EXISTS population;

-- 创建名为population的表，用于存储结果数据
CREATE TABLE population AS

-- 使用angus_group子查询获取icustay_id和angus字段
WITH angus_group AS (
    SELECT icustay_id, mimiciii.angus.angus
    FROM icustays
    LEFT JOIN angus USING (hadm_id)
),

-- 使用icu_age_raw子查询计算icustay_id和年龄（以年为单位）
icu_age_raw AS (
    SELECT icustay_id,
        EXTRACT('epoch' FROM (intime - dob)) / 60.0 / 60.0 / 24.0 / 365.242 AS age
    FROM icustays
    LEFT JOIN patients USING (subject_id)
),

-- 使用icu_age子查询计算icustay_id和年龄（将年龄限制在130岁以下）
icu_age AS (
    SELECT icustay_id,
        CASE WHEN age >= 130 THEN 91.5 ELSE age END AS age
    FROM icu_age_raw
),

-- 使用icu_order子查询计算icustay_id和icu_order（按照subject_id分组，按intime排序）
icu_order AS (
    SELECT icustay_id,
        RANK() OVER (PARTITION BY subject_id ORDER BY intime) AS icu_order
    FROM icustays
),

-- 使用echo子查询获取hadm_id和echo_time（注意条件：category为'echo'，description为'report'）
echo AS (
    SELECT hadm_id, chartdate AS echo_time
    FROM noteevents
    WHERE LOWER(category) LIKE 'echo'
    AND LOWER(description) LIKE 'report'
),

-- 使用echo_exclude子查询计算icustay_id和echo_exclude字段（根据条件判断是否排除）
echo_exclude AS (
    SELECT icustay_id,
        CASE WHEN BOOL_AND(echo_time < DATE_TRUNC('day', intime - INTERVAL '1' DAY) OR echo_time > outtime) THEN 1 ELSE 0 END AS echo_exclude
    FROM icustays
    LEFT JOIN echo USING (hadm_id)
    GROUP BY icustay_id
),

-- 使用echo_include子查询计算icustay_id和echo_include字段（根据条件判断是否包含）
echo_include AS (
    SELECT icustay_id,
        CASE WHEN BOOL_AND(echo_time IS NULL)
        OR BOOL_OR(echo_time BETWEEN DATE_TRUNC('day', intime - INTERVAL '1' DAY) AND outtime) THEN 1 ELSE 0 END AS echo_include
    FROM icustays
    LEFT JOIN echo USING (hadm_id)
    GROUP BY icustay_id
),

-- 使用echo_first子查询获取icustay_id和最早的echo_time（满足条件：echo_time在intime前一天和outtime之间）
echo_first AS (
    SELECT icustay_id, MIN(echo_time) AS echo_time
    FROM icustays
    LEFT JOIN echo ec USING (hadm_id)
    WHERE echo_time BETWEEN DATE_TRUNC('day', intime - INTERVAL '1' DAY) AND outtime
    GROUP BY icustay_id
),

-- 使用population子查询获取结果数据（通过左连接将各个子查询的结果合并）
population AS (
    SELECT *
    FROM (SELECT DISTINCT icustay_id, first_careunit, intime, outtime FROM icustays) a
    LEFT JOIN angus_group USING (icustay_id)
    LEFT JOIN icu_age USING (icustay_id)
    LEFT JOIN icu_order USING (icustay_id)
    LEFT JOIN echo_first USING (icustay_id)
    LEFT JOIN echo_exclude USING (icustay_id)
    LEFT JOIN echo_include USING (icustay_id)
)

-- 选择并显示population表中的所有数据
SELECT * FROM population;