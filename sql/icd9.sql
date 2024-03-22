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
