# `cards` -> tfrmt prep functions reference

Detail on the `tfrmt` functions that reshape a `cards` ARD into a tfrmt-ready
frame.

## `shuffle_card()` — pivot a `card` into a tidy frame

```r
shuffle_card(
  x, by = NULL, trim = TRUE, order_rows = TRUE,
  fill_overall = "Overall {colname}",
  fill_hierarchical_overall = "Any {colname}"
)
```

- `x`: an ARD data frame of class `card`.
- `by`: grouping variable(s). Defaults to `attributes(x)$by` if present (i.e. if
  `x` came from a stacking function), else `NULL`.
- `trim`: drop `fmt_fun`/`error`/`warning` columns (default `TRUE`).
- `order_rows`: apply `cards::tidy_ard_row_order()` (default `TRUE`).
- `fill_overall` / `fill_hierarchical_overall`: `glue()` string (with `colname`
  available) used to fill missing grouping/variable levels for overall /
  any-event rows. Pass a plain string for a fixed label, or `NA` to skip filling.

Output columns: `<by vars>`, `<variable columns>`, `context`, `stat_variable`,
`stat_name`, `stat_label`, `stat` — so the downstream tfrmt uses
`param = stat_name`, `value = stat`.

```r
cards::bind_ard(
  cards::ard_categorical(cards::ADSL, by = "ARM", variables = "AGEGR1"),
  cards::ard_categorical(cards::ADSL, variables = "ARM")
) |>
  shuffle_card()
```

## `prep_combine_vars()` — unite sparse variable columns

```r
prep_combine_vars(df, vars, remove = TRUE)
```

Pastes several mutually-exclusive columns into one `variable_level` column
(wraps `tidyr::unite()`, checked against `dplyr::coalesce()`). Use for a
categorical/continuous mix produced by `cards::ard_stack()`.

- `vars`: columns to unite. A single variable returns input unchanged.
- `remove`: drop the input columns from the output (default `TRUE`).
- No-ops (returns input unchanged) on hierarchical stacks (`ard_stack_hierarchical()`),
  detected via the `context` column — use `prep_hierarchical_fill()` there instead.

```r
df <- data.frame(
  context = rep("categorical", 3),
  b = c("a", NA, NA), c = c(NA, "b", NA), d = c(NA, NA, "c")
)
prep_combine_vars(df, vars = c("b", "c", "d"))
```

## `prep_label()` — build a single row-label column

```r
prep_label(df)
```

Combines `stat_label` (continuous rows) and `variable_level` (categorical rows)
into one `label` column, when both are present. No-ops otherwise.

## `prep_hierarchical_fill()` — fill `NA`s in hierarchical (SOC/PT) data

```r
prep_hierarchical_fill(df, vars, fill = "Any {colname}", fill_from_left = FALSE)
```

- `vars`: ordered columns to pair up with a rolling window, e.g. `c("A", "B",
  "C")` -> pairs `(A, B)` and `(B, C)`. In each pair, `B` is filled where `A` is
  non-missing.
- `fill`: value to fill with; `"Any {colname}"` (default) resolves `colname` to
  the column name, e.g. `"Any B"`. Any other string is used literally.
- `fill_from_left`: if `TRUE`, fill with the pair's first-column value instead
  of `fill` (takes precedence over `fill`).

```r
prep_hierarchical_fill(df, vars = c("AESOC", "AEDECOD"), fill_from_left = TRUE)
```

## `prep_big_n()` — prepare `bigN` stat rows

```r
prep_big_n(df, vars)
```

Recodes `stat_name == "n"` to `"bigN"` for the given variables, and drops that
variable's other `stat_name`s. Use when the tfrmt spec has a
`big_n_structure()`; pass the tfrmt's `column` variable(s) as `vars`.

```r
prep_big_n(df, vars = "ARM")
```
