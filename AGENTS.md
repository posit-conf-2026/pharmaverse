# Project Memory: pharmaverse posit::conf workshop

## Project context

This is a Quarto website + slide deck project for the "End-to-End Submissions
in R with the Pharmaverse" posit::conf workshop (`_quarto.yml`, output to
`docs/`). Uses `renv` for package management (`renv.lock`, `.Rprofile`
sourcing `renv/activate.R`).

Slide decks live under `slides/<NN-topic>/`. Each deck's `index.qmd` carries
the `format: revealjs` YAML front matter and pulls in content files via
`{{< include >}}` (e.g. `slides/03-ADaM/index.qmd` includes
`slides/03-ADaM/admiral.qmd`). Content `.qmd` files included this way have no
YAML front matter of their own; a directory-scoped `_metadata.yml` (e.g.
`slides/03-ADaM/_metadata.yml`) applies the same revealjs settings so those
files also render correctly as standalone slides if opened/rendered directly.
To live-preview a deck with reload-on-save, target the `index.qmd` (or any
file in a directory with a `_metadata.yml`), not a bare included content file.

## `03-ADaM` deck: "Try It" exercises

`slides/03-ADaM/admiral.qmd` teaches `{admiral}`, `{metatools}`/`{metacore}`,
and `{xportr}` with Posit Assistant as a pair-programmer. Throughout the ADSL
and ADVS sections, a series of "Try It: Ask Your AI for Assistance on ..."
slides are hands-on exercises: participants prompt Posit Assistant in plain,
human-readable language (not literal function arguments/values) to build a
small example dataset and write a function call, usually with one argument
left for the AI (or participant) to reason out. Each is a single round except
the dates exercise, which has a Round 2 extension. The sections below record
a reference worked example for each, all verified to actually run.

Given the section only has ~90 minutes total, only 5 Try Its run live in the
main flow (Dates, Dates Round 2, Merging, Restricting a Derivation,
Computed Parameters). The other 8 (Reading a Spec, Supplemental
Qualifiers, Durations, Codelists, Lookup Tables, Summary Records, Sequence
Numbers, Preparing an XPT File) were moved to a "# Explore on Your Own"
appendix section at the very end of the deck (after "Closing Thoughts",
before "Packages and Session Information") as optional self-study material -
they're unchanged in content, just relocated out of the live time budget.
Codelists was demoted from the live flow specifically to relieve a timing
crunch in the ADSL block (see the timing notes below).
The six pure function-signature/"there's more!!" reference slides (which
just enumerated full argument lists already covered by the Key Functions
Cheat Sheet's doc links) were removed entirely rather than relocated.

Dummy datasets across these exercises use the pilot-study `"01-701-10XX"`
`USUBJID` format (matching `adsl.R`/`advs.R`'s real subjects like
`"01-701-1015"`) rather than mixed simple IDs like `"P01"` or bare numbers -
keep this consistent when reproducing or extending these examples.

### "Try It: Ask Your AI for Assistance on Dates"

One slide, in the `ADSL` section right after the `--DTC` teaching slides, is a
hands-on beginner exercise: participants prompt Posit Assistant in plain,
human-readable language (not literal function arguments) to build a dummy
dataset and derive a datetime variable with `admiral::derive_vars_dtm()`.

The prompt on that slide asks for:
- A dummy `--DTC`-style character date variable with a realistic mix of
  partial values: a full date-time, a date missing time, a date missing the
  day, a year-only date, and a completely blank value.
- `derive_vars_dtm()` called with imputation preferences described in plain
  language that map to:
  - "impute up through the month if missing, but never impute a missing year"
    -> `highest_imputation = "M"`
  - "missing month/day imputed to the end of the period" -> `date_imputation
    = "last"`
  - "missing time imputed to the end of the day" -> `time_imputation =
    "last"`
  - "don't suppress the seconds imputation flag" -> `ignore_seconds_flag =
    FALSE`

### Reference worked example

When asked to run/demo this exercise, reproduce something close to:

```r
library(admiral)
library(tibble)

dummy_dtc <- tibble(
  USUBJID = c("01-701-1011", "01-701-1015", "01-701-1019", "01-701-1023", "01-701-1028"),
  ASTDTC  = c(
    "2019-07-18T15:25:40",  # full date-time
    "2019-07-18",           # date with no time
    "2019-07",               # date missing the day
    "2019",                  # date with only a year
    ""                       # completely missing value
  )
)

derive_vars_dtm(
  dummy_dtc,
  new_vars_prefix = "AST",
  dtc = ASTDTC,
  highest_imputation = "M",
  date_imputation = "last",
  time_imputation = "last",
  ignore_seconds_flag = FALSE
)
```

Walk through the result row by row rather than just printing the table:
- Row 1 (full date-time): parsed as-is, no imputation flags.
- Row 2 (date, no time): time imputed to `23:59:59`; `ASTTMF = "H"`.
- Row 3 (missing day): day imputed to the last day of the month, time to end
  of day; `ASTDTF = "D"`, `ASTTMF = "H"`.
- Row 4 (year only): month+day imputed to Dec 31 (`highest_imputation` caps
  at month); `ASTDTF = "M"`, `ASTTMF = "H"`.
- Row 5 (blank): year itself is missing, which exceeds `highest_imputation`,
  so the result is `NA` with no flags set.
- Caveat worth mentioning: `ignore_seconds_flag = FALSE` has no visible
  effect on this particular dataset since no row has partial seconds
  specifically - a good stretch-goal follow-up is adding a row that
  demonstrates it.

Keep variable naming consistent with the deck (`ASTDTC`/`ASTDTM`/`ASTDTF`/
`ASTTMF`) and prefer explaining the *reasoning* behind each row's flags over
just dumping the output table.

### "Try It: Ask Your AI for Assistance on Dates, Round 2"

Right after the Round 1 slide, a second hands-on slide extends the Round 1
exercise to cover `min_dates`, `max_dates`, and `preserve` - again phrased in
plain language rather than literal arguments.

The prompt asks participants to:
- Add per-subject `TRTSDTM` (treatment start) and `CUTOFFDTM` (data cutoff)
  reference datetime columns to the Round 1 dataset.
- Add one more `--DTC` record where the day is known but the month isn't,
  e.g. `"2019---07"` (7th of an unspecified month).
- Impute such that:
  - "don't throw away a date part just because a part above it was missing -
    keep the day if we know it" -> `preserve = TRUE`
  - "don't let the imputed datetime fall before treatment start" ->
    `min_dates = exprs(TRTSDTM)`
  - "don't let it fall after the data cutoff" -> `max_dates =
    exprs(CUTOFFDTM)`

### Reference worked example

Extend the Round 1 `dummy_dtc` dataset with a 6th subject and the two
reference date columns:

```r
library(admiral)
library(dplyr)
library(lubridate)

dummy_dtc2 <- tibble::tibble(
  USUBJID = c("01-701-1011", "01-701-1015", "01-701-1019", "01-701-1023", "01-701-1028", "01-701-1034"),
  ASTDTC  = c(
    "2019-07-18T15:25:40",  # full date-time
    "2019-07-18",           # date with no time
    "2019-07",               # date missing the day
    "2019",                  # date with only a year
    "",                      # completely missing value
    "2019---07"              # month unknown, day known (7th)
  ),
  TRTSDTM = ymd_hms(c(
    "2019-07-01 00:00:00",
    "2019-07-01 00:00:00",
    "2019-07-01 00:00:00",
    "2019-11-15 00:00:00",  # deliberately close to end of year to clip row 4
    "2019-07-01 00:00:00",
    "2019-03-10 00:00:00"   # before the mid-month guess, to isolate preserve
  )),
  CUTOFFDTM = ymd_hms(rep("2019-12-31 23:59:59", 6))
)

# Baseline: no preserve / min_dates / max_dates.
# Note date_imputation = "mid" here (not Round 1's "last") - that's the
# setting `preserve` is documented to pair with.
without_bounds <- derive_vars_dtm(
  dummy_dtc2,
  new_vars_prefix = "AST",
  dtc = ASTDTC,
  highest_imputation = "M",
  date_imputation = "mid",
  time_imputation = "last",
  ignore_seconds_flag = FALSE
)

# With preserve, min_dates, and max_dates applied
with_bounds <- derive_vars_dtm(
  dummy_dtc2,
  new_vars_prefix = "AST",
  dtc = ASTDTC,
  highest_imputation = "M",
  date_imputation = "mid",
  time_imputation = "last",
  ignore_seconds_flag = FALSE,
  preserve = TRUE,
  min_dates = exprs(TRTSDTM),
  max_dates = exprs(CUTOFFDTM)
)
```

Compare the two results rather than just showing one table - only two of
the six rows change:
- **Row 4 (year only)**: without bounds, imputed to the naive mid-year guess
  `2019-06-30 23:59:59`. That's before the subject's `TRTSDTM` of
  `2019-11-15`, which is impossible (can't have an event before treatment
  started). With `min_dates = exprs(TRTSDTM)`, the result is shifted forward
  to exactly the boundary, `2019-11-15 00:00:00` - demonstrating `min_dates`
  clipping an otherwise out-of-bounds imputed date.
- **Row 6 (`"2019---07"`, day known/month unknown)**: without `preserve`,
  the known day is discarded entirely and the whole date is overwritten to
  the mid-year guess `2019-06-30`. With `preserve = TRUE`, the known day
  (`07`) is kept and only the missing month is imputed to the middle of the
  year, giving `2019-06-07 23:59:59` instead - demonstrating `preserve`.
  This row's `TRTSDTM` (`2019-03-10`) is deliberately earlier than the
  imputed date so the `preserve` effect can be shown in isolation from any
  `min_dates` clipping.
- Rows 1-3 and 5 are unaffected: rows 1-3 had no ambiguity relative to the
  reference bounds, and row 5 has no year at all, so nothing is imputed
  regardless of bounds/`preserve`.

As with Round 1, prefer explaining *why* each changed row moved the way it
did (relative to the reference dates or the preserved day) over just
printing the before/after table.

### "Try It: Ask Your AI for Assistance on Reading a Spec" (Explore on Your Own)

In the "Explore on Your Own" appendix (originally right after "Reading in
our spec for `ADSL`", moved out of the live flow to keep the section within
90 minutes). The prompt describes a hypothetical spec file and asks for a
`spec_to_metacore()`
call, phrased so the AI has to reason about two settings:
- "don't want it printing extra messages while I iterate" -> `verbose =
  "silent"` (or `"none"`)
- "don't know if 'where' conditions are on a separate sheet" -> a reasonable
  assumption for `where_sep_sheet` (either `TRUE` or `FALSE`), explained

Since there's no real spec file matching the hypothetical path in the
prompt, demo this instead against the example spec bundled with metacore:

```r
library(metacore)

demo_spec <- spec_to_metacore(
  path = metacore_example("p21_mock.xlsx"),
  where_sep_sheet = TRUE,
  verbose = "silent"
) %>%
  select_dataset("DM", verbose = "silent")

class(demo_spec)
#> [1] "DatasetMeta" "Metacore"    "R6"
```

Explain that `select_dataset()` scopes the metacore object down to one
dataset (here `DM`, in the exercise `ADSL`), and that `where_sep_sheet`
depends on whether the source P21 spec keeps "where" conditions in their own
tab or inline with the variable-level metadata - newer specs tend to use a
single sheet (`FALSE`); when unsure, note the assumption made and that
picking wrong typically surfaces as missing/incorrect `WHERE` conditions
rather than a hard error.

### "Try It: Ask Your AI for Assistance on Supplemental Qualifiers" (Explore on Your Own)

In the "Explore on Your Own" appendix (originally right after "Combine
Parent and Supplementary Data", moved out of the live flow). Asks for a
small parent (`DM`) and supplemental (`SUPPDM`) dataset and a
`metatools::combine_supp()` call.

```r
library(metatools)
library(tibble)

dm <- tribble(
  ~STUDYID,  ~DOMAIN, ~USUBJID,       ~SEX, ~AGE,
  "PILOT01", "DM",    "01-701-1015", "F",  63,
  "PILOT01", "DM",    "01-701-1028", "M",  55,
  "PILOT01", "DM",    "01-701-1034", "F",  71
)

suppdm <- tribble(
  ~STUDYID,  ~RDOMAIN, ~USUBJID,       ~IDVAR,        ~IDVARVAL,     ~QNAM,      ~QLABEL,                      ~QVAL, ~QORIG,
  "PILOT01", "DM",     "01-701-1015",  NA_character_, NA_character_, "COMPLT16", "Completers Population Flag", "Y",   "DERIVED",
  "PILOT01", "DM",     "01-701-1028",  NA_character_, NA_character_, "COMPLT16", "Completers Population Flag", "N",   "DERIVED"
)

combine_supp(dm, suppdm)
```

Result: `COMPLT16` joins onto subjects 1015/1028 (`"Y"`/`"N"`); subject 1034,
who has no `SUPPDM` record, gets `NA`. Two gotchas worth flagging if the AI
(or participant) skips them: `combine_supp()` requires a `DOMAIN` column on
the parent dataset, and `IDVAR`/`IDVARVAL` must be `NA` (not `""`) for
subject-level (non-repeating) supplemental variables, or the join silently
fails to attach the `QVAL`.

### "Try It: Ask Your AI for Assistance on Merging"

In the `ADSL` section, right after "Let's get a more complicated merge"
(one of the 6 Try Its kept in the live flow). Asks for a subject-level
dataset and an exposure dataset with multiple dosing records (including a
placebo/zero-dose record), then a `derive_vars_merged()` call that pulls
each subject's first qualifying (non-placebo) dose date into `TRTSDTM`.

```r
library(admiral)
library(dplyr)
library(lubridate)

adsl_mini <- tribble(
  ~STUDYID,  ~USUBJID,
  "PILOT01", "01-701-1015",
  "PILOT01", "01-701-1028"
)

ex_mini <- tribble(
  ~STUDYID,  ~USUBJID,       ~EXSTDTM,                       ~EXSEQ, ~EXDOSE, ~EXTRT,
  "PILOT01", "01-701-1015",  ymd_hms("2019-07-01 08:00:00"), 1,      0,       "PLACEBO",
  "PILOT01", "01-701-1015",  ymd_hms("2019-07-15 08:00:00"), 2,      54,      "XANOMELINE",
  "PILOT01", "01-701-1015",  ymd_hms("2019-07-29 08:00:00"), 3,      54,      "XANOMELINE",
  "PILOT01", "01-701-1028",  ymd_hms("2019-08-01 08:00:00"), 1,      54,      "XANOMELINE",
  "PILOT01", "01-701-1028",  ymd_hms("2019-08-15 08:00:00"), 2,      54,      "XANOMELINE"
)

adsl_mini %>%
  derive_vars_merged(
    dataset_add = ex_mini,
    by_vars = exprs(STUDYID, USUBJID),
    order = exprs(EXSTDTM, EXSEQ),
    new_vars = exprs(TRTSDTM = EXSTDTM),
    filter_add = EXDOSE > 0 & !is.na(EXSTDTM),
    mode = "first"
  )
```

Result: subject 1015's `TRTSDTM` is `2019-07-15` (skipping the earlier
placebo dose on 07-01), subject 1028's is `2019-08-01`. Key teaching point:
`filter_add` excludes placebo *before* `mode = "first"` picks the earliest
remaining record by `order` - if `filter_add` were dropped, the placebo
record would incorrectly win as "first."

### "Try It: Ask Your AI for Assistance on Durations" (Explore on Your Own)

In the "Explore on Your Own" appendix (originally right after "Let's derive
a Duration Variable", moved out of the live flow). Asks for
birth/randomization dates (including one missing) and a
`derive_vars_duration()` call for whole-number age in years, without
rounding up.

```r
age_data <- tribble(
  ~USUBJID,       ~BRTHDT,           ~RANDDT,
  "01-701-1011",  ymd("1984-09-06"), ymd("2020-02-24"),  # birthday not yet reached this year
  "01-701-1015",  ymd("1985-01-01"), ymd("2020-03-10"),  # birthday already passed
  "01-701-1019",  NA,                ymd("2021-03-10")   # missing birth date
) %>%
  derive_vars_duration(
    new_var = AAGE,
    new_var_unit = AAGEU,
    start_date = BRTHDT,
    end_date = RANDDT,
    out_unit = "years",
    add_one = FALSE,
    trunc_out = TRUE
  )
```

Result: subject 1011 = 35 years (birthday Sep 6 hasn't occurred by Feb 24,
so age is truncated down rather than rounded to 36), subject 1015 = 35
years, subject 1019 = `NA` (no birth date to compute from). The two
arguments that matter here:
`add_one = FALSE` (don't add a day when counting, which would round partial
periods up) and `trunc_out = TRUE` (truncate rather than round the output) -
together they produce "age as of last birthday" rather than "age rounded to
nearest year."

### "Try It: Ask Your AI for Assistance on Codelists" (Explore on Your Own)

In the "Explore on Your Own" appendix (originally right after "Let's apply
Control Terms / Code Lists" in the live flow, moved to relieve a timing
crunch in the ADSL block). Asks for a character `SEX`
variable and a code/decode codelist, then a `create_var_from_codelist()`
call producing a numeric `SEXN`, reasoning about `decode_to_code`'s
direction.

```r
library(metacore)
library(metatools)

sex_data <- tribble(
  ~USUBJID,      ~SEX,
  "01-701-1011", "M",
  "01-701-1015", "F",
  "01-701-1019", "M"
)

sex_codelist <- tribble(
  ~code, ~decode,
  1,     "M",
  2,     "F"
)

# create_var_from_codelist() requires a real (subsetted) metacore object even
# when an explicit codelist is supplied - any valid DatasetMeta object works,
# e.g. from the bundled example spec:
spec <- spec_to_metacore(metacore_example("p21_mock.xlsx"), verbose = "silent")
dm_spec <- select_dataset(spec, "DM", verbose = "silent")

create_var_from_codelist(
  sex_data,
  dm_spec,
  input_var = SEX,
  out_var = SEXN,
  codelist = sex_codelist,
  decode_to_code = TRUE
)
```

Result: `M` -> `1`, `F` -> `2`. `decode_to_code = TRUE` means the function
assumes `input_var` (`SEX`, values `"M"`/`"F"`) holds the *decode* side of
the codelist and looks up the matching *code*. If that were backwards
(i.e., `SEX` actually held `1`/`2` already), the correct call would need
`decode_to_code = FALSE` - getting this backwards with `strict = TRUE`
(the default) surfaces as a warning about unmatched values and `NA` results,
not a hard error, which is the "silently wrong" trap the exercise is
designed to illustrate. Also worth noting: `metacore`/`metatools` must both
be loaded, and the `metacore` argument cannot be `NULL` - it must be a real
`DatasetMeta` object even though the codelist itself is supplied separately.

### "Try It: Ask Your AI for Assistance on Summary Records" (Explore on Your Own)

In the "Explore on Your Own" appendix (originally right after "Let's derive
DTYPE summary records", moved out of the live flow). Asks for a vital signs
dataset with triplicate readings (one missing) and a
`derive_summary_records()` call that averages them into a new
`DTYPE = "AVERAGE"` record, reasoning about excluding the missing value
before averaging rather than using `na.rm`.

```r
vs_triplicate <- tribble(
  ~USUBJID,      ~PARAMCD, ~AVISIT,    ~ADT,               ~AVAL,
  "01-701-1015", "DIABP",  "BASELINE", ymd("2019-07-01"),  78,
  "01-701-1015", "DIABP",  "BASELINE", ymd("2019-07-01"),  80,
  "01-701-1015", "DIABP",  "BASELINE", ymd("2019-07-01"),  NA,
  "01-701-1028", "DIABP",  "BASELINE", ymd("2019-07-01"),  74,
  "01-701-1028", "DIABP",  "BASELINE", ymd("2019-07-01"),  76,
  "01-701-1028", "DIABP",  "BASELINE", ymd("2019-07-01"),  75
)

derive_summary_records(
  vs_triplicate,
  dataset_add = vs_triplicate,
  by_vars = exprs(USUBJID, PARAMCD, AVISIT),
  filter_add = !is.na(AVAL),
  set_values_to = exprs(
    AVAL = mean(AVAL),
    DTYPE = "AVERAGE"
  )
)
```

Result: subject 1015's average is `79` (mean of `78`/`80`, the `NA` reading
excluded), subject 1028's is `75`. Key teaching point: `filter_add` restricts
which rows feed the aggregation *before* `mean()` runs, so the formula
itself never has to deal with `NA` - that's a cleaner mental model than
reaching for `na.rm = TRUE`, and it generalizes to any aggregation function
used in `set_values_to`.

### "Try It: Ask Your AI for Assistance on Sequence Numbers" (Explore on Your Own)

In the "Explore on Your Own" appendix (originally right after "Let's add an
Analysis Sequence Variable", moved out of the live flow). Asks for a
dataset with a deliberate ordering tie and a `derive_var_obs_number()`
call, reasoning about `check_type`.

```r
advs_seq_demo <- tribble(
  ~USUBJID,      ~PARAMCD, ~AVISITN, ~VISITNUM, ~ADT,
  "01-701-1015", "SYSBP",  1,        1,         ymd("2019-07-01"),
  "01-701-1015", "SYSBP",  1,        1,         ymd("2019-07-01"),  # accidental duplicate - ties on all order vars
  "01-701-1015", "DIABP",  1,        1,         ymd("2019-07-01")
)

derive_var_obs_number(
  advs_seq_demo,
  new_var = ASEQ,
  by_vars = exprs(USUBJID),
  order = exprs(PARAMCD, ADT, AVISITN, VISITNUM),
  check_type = "error"
)
```

Result: this actually errors - `"Dataset contains duplicate records with
respect to USUBJID, PARAMCD, ADT, AVISITN, and VISITNUM"` - because the two
`SYSBP` rows are identical on every ordering variable, so admiral can't
determine which is "first." Key teaching point: `check_type = "error"` turns
what would otherwise be a silent duplicate-`ASEQ` bug (the default is a
message) into something you're forced to notice and fix before the pipeline
continues - worth contrasting with leaving `check_type` unset to show the
milder message-only behavior.

### "Try It: Ask Your AI for Assistance on Restricting a Derivation"

In the `ADVS` section, right after "Let's restrict!" (one of the 6 Try Its
kept in the live flow). Asks for a vital signs dataset with multiple visits
and a treatment start date, then a `restrict_derivation()` call flagging
the last on-or-before-treatment record as baseline, without permanently
filtering the rest of the dataset.

```r
vs_mini <- tribble(
  ~USUBJID,      ~PARAMCD, ~ADT,               ~VISITNUM, ~VSSEQ, ~AVAL, ~BASETYPE,
  "01-701-1015", "SYSBP",  ymd("2019-07-01"),  1,         1,      120,  "BASETYPE1",
  "01-701-1015", "SYSBP",  ymd("2019-06-25"),  0,         2,      118,  "BASETYPE1",  # pre-baseline screening
  "01-701-1015", "SYSBP",  ymd("2019-07-15"),  2,         3,      130,  "BASETYPE1"
) %>%
  mutate(TRTSDT = ymd("2019-07-01"), DTYPE = NA_character_)

restrict_derivation(
  vs_mini,
  derivation = derive_var_extreme_flag,
  args = params(
    by_vars = exprs(USUBJID, BASETYPE, PARAMCD),
    order = exprs(ADT, VISITNUM, VSSEQ),
    new_var = ABLFL,
    mode = "last",
    true_value = "Y"
  ),
  filter = (!is.na(AVAL) & ADT <= TRTSDT & !is.na(BASETYPE) & is.na(DTYPE))
)
```

Result: all three rows are retained in the output, but only the 2019-07-01
record (the last one on-or-before `TRTSDT`) gets `ABLFL = "Y"` - the later
07-15 visit is correctly excluded from baseline consideration, and the
earlier screening record (07-01 is "last" among those <= TRTSDT, beating the
06-25 one) doesn't win either. Key teaching point: `restrict_derivation()`'s
`filter` argument scopes which records `derive_var_extreme_flag()` considers
when picking "last," but doesn't drop any records from the returned dataset,
unlike pre-filtering the whole dataset before calling the derivation
directly.

### "Try It: Ask Your AI for Assistance on Lookup Tables" (Explore on Your Own)

In the "Explore on Your Own" appendix (originally right after "Let's talk
about lookup tables", moved out of the live flow). Asks for a vital signs
dataset with one test code missing from the lookup table, then a
`derive_vars_merged_lookup()` call that surfaces unmapped codes instead of
silently returning `NA`.

```r
vs_lookup_demo <- tribble(
  ~USUBJID,      ~VSTESTCD, ~AVAL,
  "01-701-1015", "SYSBP",   120,
  "01-701-1015", "DIABP",   80,
  "01-701-1015", "TEMP",    37.0   # no matching lookup row on purpose
)

param_lookup <- tribble(
  ~VSTESTCD, ~PARAMCD, ~PARAM,
  "SYSBP",   "SYSBP",  "Systolic Blood Pressure (mmHg)",
  "DIABP",   "DIABP",  "Diastolic Blood Pressure (mmHg)"
)

derive_vars_merged_lookup(
  vs_lookup_demo,
  dataset_add = param_lookup,
  new_vars = exprs(PARAMCD, PARAM),
  by_vars = exprs(VSTESTCD),
  print_not_mapped = TRUE
)
```

Result: a message lists `TEMP` as not mapped (and notes
`admiral::get_not_mapped()` for the full list), while the returned dataset
still includes the `TEMP` row with `PARAMCD`/`PARAM` as `NA`. The argument
that matters here is `print_not_mapped = TRUE` - without it, the same `NA`s
would appear with no warning that a code was missing entirely from the
lookup table, which is a real risk for silently dropping/mis-mapping data.

### "Try It: Ask Your AI for Assistance on Computed Parameters"

In the `ADVS` section, right after "Let's add more records for each
subject" (BMI) - one of the 6 Try Its kept in the live flow. Asks for a
vital signs dataset with `WEIGHT` at multiple visits but `HEIGHT` collected
only once per subject, then a `derive_param_computed()` call for BMI that
reuses the single `HEIGHT` value across all of that subject's visits.

```r
advs_bmi_demo <- tribble(
  ~USUBJID,      ~PARAMCD,  ~VISIT,      ~AVAL,
  "01-701-1015", "WEIGHT",  "BASELINE",  70,
  "01-701-1015", "WEIGHT",  "WEEK 2",    69,
  "01-701-1015", "HEIGHT",  "BASELINE",  170,
  "01-701-1028", "WEIGHT",  "BASELINE",  85,
  "01-701-1028", "WEIGHT",  "WEEK 2",    84,
  "01-701-1028", "HEIGHT",  "BASELINE",  180
)

advs_bmi_demo %>%
  derive_param_computed(
    by_vars = exprs(USUBJID, VISIT),
    parameters = "WEIGHT",
    set_values_to = exprs(
      AVAL = AVAL.WEIGHT / (AVAL.HEIGHT / 100)^2,
      PARAMCD = "BMI"
    ),
    constant_parameters = c("HEIGHT"),
    constant_by_vars = exprs(USUBJID)
  )
```

Result: BMI is computed for both `BASELINE` and `WEEK 2` for each subject
(e.g. subject 1015: 24.2 at baseline, 23.9 at week 2), even though `HEIGHT`
only has one record per subject. The two arguments doing the work:
`constant_parameters = c("HEIGHT")` marks `HEIGHT` as a parameter that
should be broadcast rather than requiring a same-visit match, and
`constant_by_vars = exprs(USUBJID)` says to broadcast it per-subject. Without
these, `derive_param_computed()` would only compute BMI for visits where
*both* `WEIGHT` and `HEIGHT` exist for that exact `by_vars` combination -
here, only `BASELINE` would get a BMI and `WEEK 2` would be silently
dropped.

### "Try It: Ask Your AI for Assistance on Preparing an XPT File" (Explore on Your Own)

In the "Explore on Your Own" appendix (originally right after "Let's get
that data read for regulatory agencies", moved out of the live flow). Asks
for a small ADaM-like dataset with unlabeled variables plus label metadata,
then `xportr_label()` and `xportr_write()` calls to produce a
submission-ready xpt file.

```r
library(xportr)

xpt_demo <- tibble(
  USUBJID = c("01-701-1015", "01-701-1028"),
  AGE     = c(63, 55),
  SEX     = c("F", "M")
)

xpt_meta <- tribble(
  ~dataset, ~variable, ~label,
  "adsl",   "USUBJID", "Unique Subject Identifier",
  "adsl",   "AGE",     "Age",
  "adsl",   "SEX",     "Sex"
)

xpt_demo_labeled <- xportr_label(xpt_demo, metadata = xpt_meta, domain = "adsl")

xportr_write(xpt_demo_labeled, path = file.path(tempdir(), "adsl.xpt"))
```

Result: each column picks up its `label` attribute from `xpt_meta`
(confirm with `sapply(xpt_demo_labeled, attr, "label")`), and
`xportr_write()` produces a valid `.xpt` file at the given `path`. Key
teaching point: `xportr_label()`'s `metadata` argument can be a plain data
frame with `dataset`/`variable`/`label` columns (it doesn't have to be a
full metacore object), and `domain` scopes which rows of that metadata frame
apply when the metadata covers multiple datasets - in the real `advs.R`
script, the same pattern chains `xportr_type()`/`xportr_length()`/
`xportr_format()`/`xportr_df_label()` in before `xportr_write()`, but
`xportr_label()` + `xportr_write()` alone are enough to demonstrate the core
"apply labels, then export" pattern.
