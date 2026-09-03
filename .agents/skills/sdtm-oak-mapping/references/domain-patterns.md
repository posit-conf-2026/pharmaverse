# Domain patterns

Annotated skeletons for the two shapes of SDTM program in this workshop. Copy the
matching skeleton, then fill topic variables and qualifiers from the aCRF.

## Table of contents

- [Findings domain (VS)](#findings-domain-vs)
- [Special-purpose domain (DM) with reference dates](#special-purpose-domain-dm-with-reference-dates)
- [Common pitfalls](#common-pitfalls)

## Findings domain (VS)

Findings domains (VS, LB, EG) have **multiple topic values** (one per test). Map
each test in its own pipe, bind, then add common qualifiers and derivations.

```r
library(sdtm.oak)
library(pharmaverseraw)
library(dplyr)

# 1. CT spec + raw data with id vars
study_ct <- read.csv("slides/02-SDTM/metadata/sdtm_ct.csv")
vs_raw <- pharmaverseraw::vs_raw |>
  generate_oak_id_vars(pat_var = "PATNUM", raw_src = "vitals")
dm <- pharmaversesdtm::dm

# 2. One pipe per topic (test). Pattern per topic:
#    seed VSTESTCD (hardcode_ct, NO id_vars) ->
#    filter(!is.na(VSTESTCD)) ->
#    map qualifiers (each WITH id_vars = oak_id_vars())
vs_sysbp <-
  hardcode_ct(vs_raw, raw_var = "SYS_BP", tgt_var = "VSTESTCD",
              tgt_val = "SYSBP", ct_spec = study_ct, ct_clst = "C66741") |>
  dplyr::filter(!is.na(.data$VSTESTCD)) |>
  hardcode_ct(vs_raw, raw_var = "SYS_BP", tgt_var = "VSTEST",
              tgt_val = "Systolic Blood Pressure", ct_spec = study_ct,
              ct_clst = "C67153", id_vars = oak_id_vars()) |>
  assign_no_ct(vs_raw, raw_var = "SYS_BP", tgt_var = "VSORRES",
               id_vars = oak_id_vars()) |>
  hardcode_ct(vs_raw, raw_var = "SYS_BP", tgt_var = "VSORRESU",
              tgt_val = "mmHg", ct_spec = study_ct, ct_clst = "C66770",
              id_vars = oak_id_vars()) |>
  assign_ct(vs_raw, raw_var = "SUBPOS", tgt_var = "VSPOS",
            ct_spec = study_ct, ct_clst = "C71148", id_vars = oak_id_vars())

# ... repeat for vs_diabp, vs_pulse, vs_temp, vs_height, vs_weight ...
# Temperature/height/weight also convert units into VSSTRESC via mutate(), e.g.:
#   mutate(VSSTRESC = as.character(sprintf("%.2f", (as.numeric(VSORRES) - 32) * 5/9)))

# 3. Bind all topics
vs_combined <- dplyr::bind_rows(vs_diabp, vs_height, vs_pulse,
                                vs_sysbp, vs_temp, vs_weight)

# 4. Common qualifiers on the bound frame
vs <- vs_combined |>
  assign_datetime(vs_raw, raw_var = c("VTLD"), tgt_var = "VSDTC",
                  raw_fmt = c(list(c("d-m-y", "dd-mmm-yyyy")))) |>
  assign_ct(vs_raw, raw_var = "TMPTC", tgt_var = "VSTPT",
            ct_spec = study_ct, ct_clst = "TPT", id_vars = oak_id_vars()) |>
  assign_ct(vs_raw, raw_var = "INSTANCE", tgt_var = "VISIT",
            ct_spec = study_ct, ct_clst = "VISIT", id_vars = oak_id_vars()) |>
  assign_ct(vs_raw, raw_var = "INSTANCE", tgt_var = "VISITNUM",
            ct_spec = study_ct, ct_clst = "VISITNUM", id_vars = oak_id_vars()) |>
  # 5. Hardcoded attributes + standardized results
  dplyr::mutate(
    STUDYID  = "CDISCPILOT01",
    DOMAIN   = "VS",
    VSCAT    = "VITAL SIGNS",
    USUBJID  = paste0("01-", .data$patient_number),
    VSSTRESC = ifelse(is.na(VSSTRESC), VSORRES, VSSTRESC),
    VSSTRESN = as.numeric(VSSTRESC),
    VSSTRESU = ifelse(is.na(VSSTRESU), VSORRESU, VSSTRESU)
  ) |>
  arrange(USUBJID, VSTESTCD, as.numeric(VISITNUM)) |>
  # 6. Derivations
  derive_seq(tgt_var = "VSSEQ", rec_vars = c("USUBJID", "VSTESTCD")) |>
  derive_study_day(sdtm_in = ., dm_domain = dm, tgdt = "VSDTC",
                   refdt = "RFXSTDTC", study_day_var = "VSDY")

vs <- vs |>
  dplyr::mutate(VSDTC = as.character(VSDTC)) |>
  derive_blfl(sdtm_in = ., dm_domain = dm, tgt_var = "VSBLFL",
              ref_var = "RFSTDTC", baseline_visits = "BASELINE") |>
  # 7. Final variable order
  dplyr::select("STUDYID", "DOMAIN", "USUBJID", "VSSEQ", "VSTESTCD", "VSTEST",
                "VSPOS", "VSORRES", "VSORRESU", "VSSTRESC", "VSSTRESN",
                "VSSTRESU", "VSLOC", "VISITNUM", "VISIT", "VSDTC", "VSDY")
```

Full working version: `slides/02-SDTM/scripts/create_vs_domain.R`.

## Special-purpose domain (DM) with reference dates

DM has **one row per subject** and no test loop. Map each variable in a single
pipe, then derive reference dates from EX/DS/DM raw sources.

```r
library(sdtm.oak)
library(dplyr)

study_ct <- read.csv("slides/02-SDTM/metadata/sdtm_ct.csv")

# Read raw, convert blanks to NA, add id vars (one raw_src name each)
dm_raw <- pharmaverseraw::dm_raw |> admiral::convert_blanks_to_na() |>
  generate_oak_id_vars(pat_var = "PATNUM", raw_src = "dm_raw")
ex_raw <- pharmaverseraw::ec_raw |> admiral::convert_blanks_to_na() |>
  generate_oak_id_vars(pat_var = "PATNUM", raw_src = "ex_raw")
ds_raw <- pharmaverseraw::ds_raw |> admiral::convert_blanks_to_na() |>
  generate_oak_id_vars(pat_var = "PATNUM", raw_src = "ds_raw")

# Reference-date config: which raw date feeds which RF* variable
ref_date_conf_df <- tibble::tribble(
  ~raw_dataset_name, ~date_var,     ~time_var,      ~dformat,      ~tformat, ~sdtm_var_name,
  "ex_raw",       "IT.ECSTDAT", NA_character_, "dd-mmm-yyyy", NA_character_,     "RFXSTDTC",
  "ex_raw",       "IT.ECENDAT", NA_character_, "dd-mmm-yyyy", NA_character_,     "RFXENDTC",
  "ds_raw",       "IT.DSSTDAT", NA_character_,  "mm-dd-yyyy", NA_character_,      "RFSTDTC",
  "dm_raw",            "IC_DT", NA_character_,  "mm/dd/yyyy", NA_character_,      "RFICDTC",
  "ds_raw",          "DSDTCOL",     "DSTMCOL",  "mm-dd-yyyy",         "H:M",     "RFPENDTC",
  "ds_raw",          "DEATHDT", NA_character_,  "mm/dd/yyyy", NA_character_,       "DTHDTC"
)

dm <-
  assign_no_ct(dm_raw, raw_var = "PATNUM", tgt_var = "SUBJID",
               id_vars = oak_id_vars()) |>
  assign_no_ct(dm_raw, raw_var = "IT.AGE", tgt_var = "AGE",
               id_vars = oak_id_vars()) |>
  hardcode_ct(dm_raw, raw_var = "IT.AGE", tgt_var = "AGEU", tgt_val = "Year",
              ct_spec = study_ct, ct_clst = "C66781", id_vars = oak_id_vars()) |>
  assign_ct(dm_raw, raw_var = "IT.SEX", tgt_var = "SEX",
            ct_spec = study_ct, ct_clst = "C66731", id_vars = oak_id_vars()) |>
  assign_ct(dm_raw, raw_var = "IT.RACE", tgt_var = "RACE",
            ct_spec = study_ct, ct_clst = "C74457", id_vars = oak_id_vars()) |>
  assign_ct(dm_raw, raw_var = "IT.ETHNIC", tgt_var = "ETHNIC",
            ct_spec = study_ct, ct_clst = "C66790", id_vars = oak_id_vars()) |>
  assign_ct(dm_raw, raw_var = "PLANNED_ARM", tgt_var = "ARM",
            ct_spec = study_ct, ct_clst = "ARM", id_vars = oak_id_vars()) |>
  assign_no_ct(dm_raw, raw_var = "PLANNED_ARMCD", tgt_var = "ARMCD",
               id_vars = oak_id_vars()) |>
  assign_datetime(dm_raw, raw_var = "COL_DT", tgt_var = "DMDTC",
                  raw_fmt = c("m/d/y"), id_vars = oak_id_vars()) |>
  mutate(STUDYID = dm_raw$STUDY, DOMAIN = "DM",
         USUBJID = paste0("01-", dm_raw$PATNUM), COUNTRY = dm_raw$COUNTRY) |>
  # One oak_cal_ref_dates() call per RF* variable
  oak_cal_ref_dates(ds_in = ., der_var = "RFXSTDTC", min_max = "min",
                    ref_date_config_df = ref_date_conf_df,
                    raw_source = list(ex_raw = ex_raw, ds_raw = ds_raw, dm_raw = dm_raw)) |>
  oak_cal_ref_dates(ds_in = ., der_var = "RFXENDTC", min_max = "max",
                    ref_date_config_df = ref_date_conf_df,
                    raw_source = list(ex_raw = ex_raw)) |>
  oak_cal_ref_dates(ds_in = ., der_var = "RFSTDTC", min_max = "min",
                    ref_date_config_df = ref_date_conf_df,
                    raw_source = list(ex_raw = ex_raw, ds_raw = ds_raw, dm_raw = dm_raw)) |>
  dplyr::mutate(DTHFL = dplyr::if_else(is.na(DTHDTC), NA_character_, "Y"),
                SITEID = substr(SUBJID, 1, 3)) |>
  derive_study_day(sdtm_in = ., dm_domain = ., tgdt = "DMDTC",
                   refdt = "RFXSTDTC", study_day_var = "DMDY") |>
  select("STUDYID", "DOMAIN", "USUBJID", "SUBJID", "RFSTDTC", "RFXSTDTC",
         "RFXENDTC", "SITEID", "AGE", "AGEU", "SEX", "RACE", "ETHNIC",
         "ARMCD", "ARM", "COUNTRY", "DMDTC", "DMDY")
```

Full working version: `slides/02-SDTM/scripts/create_dm_domain.R`.

## Common pitfalls

- **First call in a topic pipe must NOT pass `id_vars`** — it seeds the frame.
  Every later qualifier mapping must pass `id_vars = oak_id_vars()`.
- **Filter after seeding the topic**: `filter(!is.na(<topic>))` before qualifiers,
  or qualifiers land on rows that have no topic value.
- **Wrong `ct_clst`**: the code is the `codelist_code` column of the CT spec, not
  the term code. Confirm against `sdtm_ct.csv`.
- **`derive_blfl` needs `--DTC` as character** — coerce with `mutate(VSDTC = as.character(VSDTC))` first.
- **Standardized results**: fall back to original when no conversion applies —
  `VSSTRESC = ifelse(is.na(VSSTRESC), VSORRES, VSSTRESC)`.
- **Reference dates**: pass only the raw sources relevant to each `der_var`, and
  match `min`/`max` to the semantics (start = min, end = max).
