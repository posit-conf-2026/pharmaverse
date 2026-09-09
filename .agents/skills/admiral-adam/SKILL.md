---
name: admiral-adam
description: Derive ADaM variables and records (ADSL, ADVS) using {admiral}, {metatools}/{metacore}, and {xportr}. Use when building or extending an ADaM dataset, imputing a --DTC date/datetime, merging in a reference date or lookup value, deriving a computed parameter (BMI, MAP, Pulse Pressure), restricting a derivation to a subset of records, applying a codelist, or preparing an xpt file for submission. Triggers on "admiral", "ADaM", "ADSL", "ADVS", "derive_vars_dtm", "derive_vars_merged", "derive_param_computed", "restrict_derivation", "metacore", "metatools", "xportr".
---

# ADaM derivations with {admiral}, {metatools}/{metacore}, and {xportr}

Generate ADaM programs in R by deriving one variable or record type at a time
on top of SDTM data: read the spec, impute dates, merge in reference values,
derive computed parameters, then finalize the dataset for submission.

## When to use

Building or extending:
- **ADSL** (subject-level, one record per subject, focus on adding variables), or
- **ADVS** (a Basic Data Structure, focus on adding records, some variables)

from SDTM data plus a spec, or performing any of: `--DTC` imputation, a
merge/lookup, a computed parameter, a duration/age calculation, a restricted
derivation, a codelist lookup, or xpt export.

## Inputs to gather first

1. **Spec file** (P21-like Excel) — read with `metacore::spec_to_metacore()`;
   this workshop's spec is `slides/03-ADaM/metadata/posit_specs.xlsx`.
2. **Source SDTM data** — `{pharmaversesdtm}` (`dm`, `suppdm`, `ex`, `ae`, `vs`)
   for building, or the finished `{pharmaverseadam}` datasets for reference.
3. **Reference scripts** — `slides/03-ADaM/scripts/adsl.R` and `advs.R`.

## Workflow

1. **Read the spec** and scope it to one dataset:
   `spec_to_metacore(path, where_sep_sheet, verbose = "silent") |> select_dataset("ADSL")`.
2. **Combine parent + supplemental** data with `metatools::combine_supp()`.
3. **Impute `--DTC` variables** into `*DTM`/`*DT` with `derive_vars_dtm()` /
   `derive_vars_dt()` — see the imputation conventions below.
4. **Pull in reference values** — `derive_vars_merged()` for a value from
   another dataset/timepoint (e.g. first qualifying dose date), or
   `derive_vars_merged_lookup()` for a lookup table join (e.g.
   `VSTESTCD` → `PARAMCD`).
5. **Derive computed parameters or durations** — `derive_param_computed()`
   (BMI, MAP, Pulse Pressure), `derive_vars_duration()` (age, days on
   treatment), or `derive_summary_records()` (e.g. an `AVERAGE` record).
6. **Apply codelists** with `metatools::create_var_from_codelist()`.
7. **Restrict a derivation** to a subset of records without dropping the rest
   with `restrict_derivation()` (a higher-order function wrapping another
   derivation, e.g. `derive_var_extreme_flag()`).
8. **Finalize for submission**: `drop_unspec_vars()` → `check_variables()` →
   `order_cols()` → `sort_by_key()` (all `{metatools}`), then
   `xportr_type()` → `xportr_length()` → `xportr_label()` → `xportr_format()`
   → `xportr_df_label()` → `xportr_write()` (all `{xportr}`).

## Choosing the function

| Situation | Function |
|---|---|
| Impute a `--DTC` into a `*DTM`/`*DT` | `derive_vars_dtm()` / `derive_vars_dt()` |
| Pull a value from another dataset/timepoint (e.g. first non-placebo dose date) | `derive_vars_merged()` |
| Merge in a lookup table (e.g. `VSTESTCD` → `PARAMCD`) | `derive_vars_merged_lookup()` |
| Compute a new parameter from other parameters (BMI, MAP, Pulse Pressure) | `derive_param_computed()` |
| Duration or age between two dates | `derive_vars_duration()` |
| Average/summary record across replicate readings | `derive_summary_records()` |
| Flag a record but only within a subset (e.g. baseline on/before `TRTSDT`) | `restrict_derivation()` |
| Numeric variable from a codelist (e.g. `SEX` → `SEXN`) | `create_var_from_codelist()` |
| Analysis sequence number | `derive_var_obs_number()` |
| Read a P21-style spec | `spec_to_metacore()` + `select_dataset()` |
| Join parent + supplemental qualifier data | `combine_supp()` |
| Apply labels / write the submission xpt | `xportr_label()` / `xportr_write()` |

## Conventions (this repo)

- Dummy `USUBJID` values use the pilot-study `"01-701-10XX"` format (matches
  `adsl.R`/`advs.R`'s real subjects like `"01-701-1015"`).
- `highest_imputation` caps how far up the date hierarchy `admiral` may
  impute (e.g. `"M"` = impute month/day but never a missing year).
- `preserve = TRUE` keeps a known lower-level date part (e.g. a known day)
  instead of discarding it when a higher part had to be imputed.
- `min_dates`/`max_dates` clip an imputed value so it can't fall outside
  known reference dates (e.g. before `TRTSDTM` or after a cutoff).
- `decode_to_code = TRUE` (the default) assumes the input variable holds the
  *decode* side of a codelist; set `FALSE` if it holds the *code* side.
- `constant_parameters`/`constant_by_vars` in `derive_param_computed()`
  broadcast a subject-level value (e.g. one `HEIGHT` reading) across all of
  that subject's visits, instead of requiring it at every visit.

## Reference material

- Working end-to-end scripts: `slides/03-ADaM/scripts/adsl.R` and
  `slides/03-ADaM/scripts/advs.R`. Copy the closest one as a starting point.
- Key Functions Cheat Sheet slides in `slides/03-ADaM/admiral.qmd` link every
  function above straight to its pkgdown reference page.

## Validate before finishing

- Program runs without error; check a known subject (e.g. `"01-701-1015"`).
- Imputation flags (`*DTF`/`*TMF`) are set whenever a component was actually
  imputed, and `NA` when nothing was.
- A computed parameter's `PARAMCD`/`PARAM`/`AVALU` are all set, not just `AVAL`.
- Generated code is a **starting point** — a human/participant must verify
  assumptions (e.g. `where_sep_sheet`, `decode_to_code` direction) before
  it's submission-ready.
