# sdtm.oak algorithm reference

Argument names and order for each mapping algorithm, with a worked example taken
from the VS/DM programs in this repo. All examples assume `study_ct` is loaded and
the raw data has been through `generate_oak_id_vars()`.

## Table of contents

- [generate_oak_id_vars](#generate_oak_id_vars)
- [oak_id_vars](#oak_id_vars)
- [assign_no_ct](#assign_no_ct)
- [assign_ct](#assign_ct)
- [hardcode_ct](#hardcode_ct)
- [hardcode_no_ct](#hardcode_no_ct)
- [condition_add](#condition_add)
- [assign_datetime](#assign_datetime)
- [oak_cal_ref_dates](#oak_cal_ref_dates)
- [derive_seq](#derive_seq)
- [derive_study_day](#derive_study_day)
- [derive_blfl](#derive_blfl)

## generate_oak_id_vars

Adds `oak_id`, `raw_source`, `patient_number` to a raw dataset. Run once per raw
dataset before mapping.

```r
vs_raw <- pharmaverseraw::vs_raw |>
  generate_oak_id_vars(pat_var = "PATNUM", raw_src = "vitals")
```

## oak_id_vars

Helper returning the id-var names to join on. Pass `id_vars = oak_id_vars()` to
every qualifier mapping (i.e. every algorithm call **except** the first one in a
topic pipe).

## assign_no_ct

One-to-one copy of a collected value; no controlled terminology.

```r
assign_no_ct(
  raw_dat = vs_raw,
  raw_var = "SYS_BP",
  tgt_var = "VSORRES",
  id_vars = oak_id_vars()
)
```

## assign_ct

One-to-one map of a collected value that is subject to CT. `ct_clst` is the
`codelist_code` from the CT spec.

```r
assign_ct(
  raw_dat = vs_raw,
  raw_var = "SUBPOS",
  tgt_var = "VSPOS",
  ct_spec = study_ct,
  ct_clst = "C71148",
  id_vars = oak_id_vars()
)
```

## hardcode_ct

Assign a fixed `tgt_val` to a CT-restricted target. Commonly used to seed the
topic variable (`VSTESTCD`) and units.

```r
hardcode_ct(
  raw_dat = vs_raw,
  raw_var = "SYS_BP",
  tgt_var = "VSTESTCD",
  tgt_val = "SYSBP",
  ct_spec = study_ct,
  ct_clst = "C66741"
)   # first call in the pipe -> no id_vars
```

## hardcode_no_ct

Assign a fixed value to a target with no CT.

```r
hardcode_no_ct(
  raw_dat = cm_raw,
  raw_var = "IT.CMTRT",
  tgt_var = "CMCAT",
  tgt_val = "GENERAL",
  id_vars = oak_id_vars()
)
```

## condition_add

Wraps `raw_dat` so a mapping applies only to rows meeting a condition. Use inside
another algorithm's `raw_dat` argument.

```r
assign_ct(
  raw_dat = condition_add(vs_raw, !is.na(IT.TEMP)),
  raw_var = "IT.TEMP_LOC",
  tgt_var = "VSLOC",
  ct_spec = study_ct,
  ct_clst = "C74456",
  id_vars = oak_id_vars()
)
```

## assign_datetime

Maps raw date/time strings to ISO 8601, handling partial/unknown dates. `raw_fmt`
gives the collected format(s); for a single-variable date pass one format, for a
date built from multiple parts pass a list.

```r
# single variable, list of accepted formats
assign_datetime(
  raw_dat = vs_raw,
  raw_var = c("VTLD"),
  tgt_var = "VSDTC",
  raw_fmt = c(list(c("d-m-y", "dd-mmm-yyyy")))
)

# simple single format
assign_datetime(
  raw_dat = dm_raw,
  raw_var = "COL_DT",
  tgt_var = "DMDTC",
  raw_fmt = c("m/d/y"),
  id_vars = oak_id_vars()
)
```

## oak_cal_ref_dates

Derives DM reference dates (RFSTDTC, RFXSTDTC, RFENDTC, RFICDTC, RFPENDTC,
DTHDTC, …) from one or more raw sources, using a config tibble. `min_max`
selects the earliest ("min") or latest ("max") qualifying date.

Config tibble columns:
`raw_dataset_name, date_var, time_var, dformat, tformat, sdtm_var_name`.

```r
ref_date_conf_df <- tibble::tribble(
  ~raw_dataset_name, ~date_var,     ~time_var,      ~dformat,      ~tformat, ~sdtm_var_name,
  "ex_raw",       "IT.ECSTDAT", NA_character_, "dd-mmm-yyyy", NA_character_,     "RFXSTDTC",
  "ds_raw",       "IT.DSSTDAT", NA_character_,  "mm-dd-yyyy", NA_character_,      "RFSTDTC"
)

oak_cal_ref_dates(
  ds_in = .,
  der_var = "RFXSTDTC",
  min_max = "min",
  ref_date_config_df = ref_date_conf_df,
  raw_source = list(ex_raw = ex_raw, ds_raw = ds_raw, dm_raw = dm_raw)
)
```

Pass only the raw sources relevant to a given `der_var` in `raw_source`.

## derive_seq

Creates the `--SEQ` sequence number within record-identifying variables.

```r
derive_seq(tgt_var = "VSSEQ", rec_vars = c("USUBJID", "VSTESTCD"))
```

## derive_study_day

Study day relative to a reference date from DM.

```r
derive_study_day(
  sdtm_in = .,
  dm_domain = dm,
  tgdt = "VSDTC",
  refdt = "RFXSTDTC",
  study_day_var = "VSDY"
)
```

## derive_blfl

Baseline flag. Requires `--DTC` as character.

```r
derive_blfl(
  sdtm_in = .,
  dm_domain = dm,
  tgt_var = "VSBLFL",
  ref_var = "RFSTDTC",
  baseline_visits = "BASELINE",
  baseline_timepoints = c("AFTER LYING DOWN FOR 5 MINUTES", NA)
)
```
