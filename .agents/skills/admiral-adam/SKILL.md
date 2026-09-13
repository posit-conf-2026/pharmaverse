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

## Non-negotiable: wrap variables/expressions in `exprs()`

Almost every `{admiral}` argument that takes one or more variable names, a
computed expression, or a `new = old` assignment — `by_vars`, `order`,
`new_vars`, `filter_add`'s *variables* (though `filter_add`/`filter` itself
is a bare logical expression, not wrapped), `set_values_to`,
`constant_by_vars` — must be built with `rlang::exprs()`, not `c()`,
`list()`, `vars()`, or bare strings. This is the single most common stumble:

```r
by_vars = exprs(STUDYID, USUBJID)          # correct
new_vars = exprs(TRTSDTM = EXSTDTM)        # correct - exprs() takes `new = old`
by_vars = c("STUDYID", "USUBJID")          # wrong - errors: "must be class <list>"
by_vars = vars(STUDYID, USUBJID)           # wrong - errors on <quosure> object
```

Exceptions — these take a plain character vector, *not* `exprs()`:
- `constant_parameters` in `derive_param_computed()` (a set of `PARAMCD`
  values, e.g. `c("HEIGHT")`)
- `parameters` in `derive_param_computed()`
- `mode`, `true_value`, `new_var`, and other single scalar/string args

`restrict_derivation()` wraps the inner derivation's arguments in
`admiral::params()` (not `exprs()`) — but the individual `by_vars`/`order`
arguments *inside* that `params()` call still need `exprs()` themselves:
`args = params(by_vars = exprs(...), order = exprs(...), ...)`.

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
| Numeric variable from a codelist (e.g. `RACE` → `RACEN`) | `create_var_from_codelist()` |
| Analysis sequence number | `derive_var_obs_number()` |
| Read a P21-style spec | `spec_to_metacore()` + `select_dataset()` |
| Join parent + supplemental qualifier data | `combine_supp()` |
| Apply labels / write the submission xpt | `xportr_label()` / `xportr_write()` |

## Conventions (this repo)

- Dummy `USUBJID` values use the pilot-study `"01-701-10XX"` format (matches
  `adsl.R`/`advs.R`'s real subjects like `"01-701-1015"`).
- `derive_vars_dtm()`/`derive_vars_dt()` imputation args, and how they divide
  responsibilities:
  - `highest_imputation` is the *ceiling* — the highest date/time component
    `admiral` is allowed to impute (e.g. `"M"` = month/day may be imputed,
    but a missing **year** always forces the result to `NA` rather than
    guessing one).
  - `date_imputation`/`time_imputation` say *what value* to impute a missing
    component to below that ceiling — `"first"` (start of period/midnight),
    `"last"` (end of period/`23:59:59`), or a literal `"MM-DD"`/`"HH:MM:SS"`.
  - `flag_imputation` controls which flag columns get created. Leave it at
    the default `"auto"` unless told otherwise — it adds `*DTF` and/or
    `*TMF` only where something was actually imputed. Hardcoding `"date"` or
    `"time"` silently drops the other flag.
  - `ignore_seconds_flag` defaults to `TRUE`, which suppresses second-level
    granularity in `*TMF`. **If the source `--DTC` data contains any real
    seconds values, this raises `Seconds detected in data while
    'ignore_seconds_flag' is invoked` — set `ignore_seconds_flag = FALSE`**
    so seconds aren't silently dropped from the flag.
- `preserve = TRUE` keeps a known lower-level date part (e.g. a known day)
  instead of discarding it when a higher part had to be imputed.
- `min_dates`/`max_dates` clip an imputed value so it can't fall outside
  known reference dates (e.g. before `TRTSDTM` or after a cutoff). Order of
  operations: impute (honoring `preserve`) *then* clip — so a preserved
  lower-level part (e.g. a known day) can still end up invisible in the
  final value if the clip to `min_dates`/`max_dates` overrides it. That's
  expected, not a bug; call it out explicitly when explaining a result.
- `decode_to_code = TRUE` (the default) assumes the input variable holds the
  *decode* side of a codelist; set `FALSE` if it holds the *code* side.
- `constant_parameters`/`constant_by_vars` in `derive_param_computed()`
  broadcast a subject-level value (e.g. one `HEIGHT` reading) across all of
  that subject's visits, instead of requiring it at every visit.
- `create_var_from_codelist()` needs a real (subsetted) **metacore object**
  as its second argument, not a bare codelist data frame — you cannot hand
  it just a `code`/`decode` tibble on its own. For a demo, read the
  workshop spec (`spec_to_metacore()` + `select_dataset()`), then either use
  a `variable`/`out_var` pair that's already in that spec (e.g. `RACE` →
  `RACEN`), or pass an explicit override — `codelist =
  get_control_term(spec, "SEX")` — if `out_var` isn't itself a spec'd
  variable.
- `combine_supp()` has an edge case: if the `supp` dataset has only **one**
  distinct `QNAM` *and* includes a `USUBJID` not present in the parent
  dataset, it fails with an unrelated-looking error
  (`object 'IDVARVAL' not found`). Build example `SUPP--` data with **two or
  more** `QNAM` values to sidestep it, and remember `IDVAR`/`IDVARVAL` are
  `NA` (not `""`) for subject-level (non-repeating) qualifiers. Required
  `SUPP--` columns: `STUDYID`, `RDOMAIN`, `USUBJID`, `IDVAR`, `IDVARVAL`,
  `QNAM`, `QLABEL`, `QVAL`, `QORIG` (and usually `QEVAL`) — a minimal example
  missing `QORIG` fails validation before the merge even runs.
- `spec_to_metacore()`'s `quiet` argument is **superseded** by `verbose`
  (`"message"`/`"warn"`/`"collapse"`/`"silent"`) as of metacore 0.3.0 — reach
  for `verbose = "silent"` to suppress everything, not `quiet = TRUE`.
- `derive_vars_duration()` defaults (`add_one = TRUE`, `trunc_out = FALSE`)
  suit inclusive day-counts (e.g. days on treatment), not age. For "whole
  years, don't round up before the next birthday," set
  `trunc_out = TRUE` (drives the actual truncation) — `add_one` rarely
  changes a year-level result but leave it `FALSE` for age to avoid an
  inclusive off-by-one day creeping in.
- `xportr_label()`/`xportr_type()`/`xportr_format()` take **variable-level**
  metadata (columns `dataset`, `variable`, `label`, ...), while
  `xportr_df_label()` takes separate **dataset-level** metadata (just
  `dataset`, `label`) — two different table shapes for two different calls.
  `xportr_write()` also enforces the real SAS transport (v5) rule that the
  file's base name is 8 characters or fewer (e.g. `"adsl.xpt"` is fine;
  a longer domain name isn't).

## Reference material

- Working end-to-end scripts: `slides/03-ADaM/scripts/adsl.R` and
  `slides/03-ADaM/scripts/advs.R`. Copy the closest one as a starting point.
- Key Functions Cheat Sheet slides in `slides/03-ADaM/admiral.qmd` link every
  function above straight to its pkgdown reference page.

## Validate before finishing

- Program runs without error; check a known subject (e.g. `"01-701-1015"`).
- Variable/expression arguments (`by_vars`, `order`, `new_vars`,
  `set_values_to`, ...) use `exprs()`, not `c()`/`list()`/`vars()`/strings.
- Imputation flags (`*DTF`/`*TMF`) are set whenever a component was actually
  imputed, and `NA` when nothing was.
- A computed parameter's `PARAMCD`/`PARAM`/`AVALU` are all set, not just `AVAL`.
- Generated code is a **starting point** — a human/participant must verify
  assumptions (e.g. `where_sep_sheet`, `decode_to_code` direction) before
  it's submission-ready.
