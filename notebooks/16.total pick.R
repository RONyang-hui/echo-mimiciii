library(RPostgreSQL)
library(Matching)
library(tidyverse)

data_dir <- file.path("..", "data")
sql_dir <- file.path("..", "sql")

drv <- dbDriver("PostgreSQL")
con <- dbConnect(drv, dbname = "mimic")
dbSendQuery(con, "set search_path=echo,public,mimiciii;")

ventfreedays <- dbGetQuery(con, "select icustay_id, ventfreeday28 from subgroup;")
head(ventfreedays)

full_data <- readRDS(file.path(data_dir, "full_data_ps.rds"))
head(full_data)

ps_matches_df <- data.table::fread(file.path(data_dir, "ps_matches_df.csv"), data.table = FALSE)

head(ps_matches_df)

matches_df <- ps_matches_df %>%
spread(group, icustay_id) %>%
select(ctrl, trtd) %>%
rename(icustay_id = ctrl, match = trtd)

head(matches_df)


features <- c("age", "gender", "first_careunit", "weight",
              "saps", "sofa", "elix_score", "vent", "vaso", "sedative",
              "icd_chf", "icd_afib", "icd_renal", "icd_liver",
              "icd_copd", "icd_cad", "icd_stroke", "icd_malignancy",
              "icu_adm_weekday", "icu_adm_hour",
              "vs_map_first", "vs_heart_rate_first", "vs_temp_first", "vs_cvp_flag",
              "lab_wbc_first", "lab_hemoglobin_first", "lab_platelet_first",
              "lab_sodium_first", "lab_potassium_first", "lab_bicarbonate_first",
              "lab_chloride_first", "lab_bun_first", "lab_lactate_first",
              "lab_creatinine_first", "lab_ph_first", "lab_po2_first", "lab_pco2_first",
              "lab_bnp_flag", "lab_troponin_flag", "lab_creatinine_kinase_flag")


covariates <- full_data %>%
select(c("icustay_id", features))

names(covariates) <- names(covariates) %>%
str_replace_all("lab_|vs_|icd_|_first", " ") %>%
str_replace_all("_", " ") %>%
str_replace_all("\\s+$|^\\s+", "") %>%
str_replace_all("vent", "ventilation use") %>%
str_replace_all("vaso", "vasopressor use") %>%
str_replace_all("sedative", "sedative use") %>%
str_replace_all("elix score", "elixhauser score") %>%
str_replace_all("flag", "(tested)") %>%
str_replace_all("cvp \\(tested\\)", "cvp (measured)") %>%
str_replace_all("icustay id", "icustay_id")

head(covariates)
names(covariates)


result <- full_data %>%
left_join(ventfreedays, by = "icustay_id") %>%
left_join(matches_df, by = "icustay_id") %>%
select(icustay_id, echo_int, icu_los_day, mort_28_day_int, ventfreeday28, match, ps) %>%
setNames(c("icustay_id", "echo", "icu length of stay", "28 day mortality",
           "ventilation free days (28 days)", "match id", "propensity score")) %>%
left_join(covariates, by = "icustay_id")

head(result)
str(result)

data.table::fwrite(result, file.path(data_dir, "ps_details.csv"))