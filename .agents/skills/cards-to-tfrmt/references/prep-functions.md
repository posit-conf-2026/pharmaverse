# `cards` -> tfrmt Prep Functions

Full package help for the `tfrmt` functions that turn a `cards` ARD into a
tfrmt-ready frame, generated from the package's parsed help
(`tools::Rd_db("tfrmt")`, v0.4.0). Covers `shuffle_card`, `prep_combine_vars`,
`prep_label`, `prep_hierarchical_fill`, `prep_big_n`.

`shuffle_card()` output columns are `<by vars>`, `<variable columns>`,
`context`, `stat_variable`, `stat_name`, `stat_label`, `stat` — so a tfrmt over
shuffled cards data uses `param = stat_name`, `value = stat`.

For post-render debugging helpers (`display_row_frmts`, `display_val_frmts`,
`extract_data`, `make_mock_data`) see the `tfrmt` skill's
`references/debugging.md`.

If the installed `tfrmt` version differs from v0.4.0, prefer a live fetch:
`tools::Rd2txt(utils:::.getHelpFile(help(shuffle_card, package = "tfrmt")))`.

## `shuffle_card()` -- Shuffle `cards`

This function ingests an ARD object of class `card` and shuffles the information to prepare for analysis. Helpful for streamlining across multiple ARDs.

**Usage**

```r
shuffle_card(
  x,
  by = NULL,
  trim = TRUE,
  order_rows = TRUE,
  fill_overall = "Overall {colname}",
  fill_hierarchical_overall = "Any {colname}"
)
```

**Arguments**

- `x`: an ARD data frame of class 'card'
- `by`: Grouping variable(s) used in calculations. Defaults to `NULL`. If available (i.e. if `x` comes from a stacking function), `attributes(x)$by` will be used instead of `by`.
- `trim`: logical representing whether or not to trim away `fmt_fun`, `error`, and `warning` columns
- `order_rows`: logical representing whether or not to apply `cards::tidy_ard_row_order()` to sort the rows
- `fill_overall`: scalar to fill missing grouping or variable levels. If a character is passed, then it is processed with `glue::glue()` where the colname element is available to inject into the string, e.g. Overall {colname} may resolve to `"Overall AGE"` for an `AGE` column. Default is Overall {colname}. If `NA` then no fill will occur.
- `fill_hierarchical_overall`: scalar to fill variable levels for overall hierarchical calculations. If a character is passed, then it is processed with `glue::glue()` where the colname element is available to inject into the string, e.g. Any {colname} may resolve to `"Any AESOC"` for an `AESOC` column. Default is Any {colname}. If `NA` then no fill will occur.

**Value**

a tibble

**Examples**

```r
cards::bind_ard(
  cards::ard_categorical(cards::ADSL, by = "ARM", variables = "AGEGR1"),
  cards::ard_categorical(cards::ADSL, variables = "ARM")
) |>
  shuffle_card()
```

## `prep_combine_vars()` -- Combine variables

A wrapper around `tidyr::unite()` which pastes several columns into one. In addition it checks the output is identical to `dplyr::coalesce()`. If not identical, the input data.frame is returned unchanged. Useful for uniting sparsely populated columns, for example when processing an ard that was created with `cards::ard_stack()` then shuffled with [shuffle_card()].

If the data is the result of a hierarchical ard stack (with `cards::ard_stack_hierarchical()` or `cards::ard_stack_hierarchical_count()`), the input is returned unchanged. This is assessed from the information in the `context` column which needs to be present. If the input data does not have a `context` column, the input will be returned unmodified.

**Usage**

```r
prep_combine_vars(df, vars, remove = TRUE)
```

**Arguments**

- `df`: (data.frame)
- `vars`: (character) a vector of variables to unite. If a single variable is supplied, the input is returned unchanged.
- `remove`: If `TRUE`, remove input columns from output data frame.

**Value**

a data.frame with an additional column, called `variable_level` or the input unchanged.

**Examples**

```r
df <- data.frame(
  a = 1:6,
  context = rep("categorical", 6),
  b = c("a", rep(NA, 5)),
  c = c(NA, "b", rep(NA, 4)),
  d = c(NA, NA, "c", rep(NA, 3)),
  e = c(NA, NA, NA, "d", rep(NA, 2)),
  f = c(NA, NA, NA, NA, "e", NA),
  g = c(rep(NA, 5), "f")
)

prep_combine_vars(
  df,
  vars = c("b", "c", "d", "e", "f", "g")
)
```

## `prep_label()` -- Prepare label

Adds a `label` column which is a combination of `stat_label` (for continuous variables) and `variable_level` (for categorical ones) if these 2 columns are present in the input data frame.

**Usage**

```r
prep_label(df)
```

**Arguments**

- `df`: (data.frame)

**Value**

a data.frame with a `label` column (if the input has the required columns) or the input unchanged.

**Examples**

```r
df <- data.frame(
  variable_level = c("d", "e", "f"),
  stat_label = c("a", "b", "c"),
  stat_name = c("n", "N", "n"),
  context = c("categorical", "continuous", "hierarchical")
)

prep_label(df)
```

## `prep_hierarchical_fill()` -- Fill missing values in hierarchical variables

Replace `NA` values in one column conditional on the same row having a non-NA value in a different column.

The user supplies a vector of columns from which the pairs will be extracted with a rolling window. For example `vars <- c("A", "B", "C")` will generate 2 pairs ("A", "B") and ("B", "C"). Therefore the order of the variables matters.

In each pair the second column `B` will be filled if `A` is not missing. One can choose the value to fill with:

- `"Any {colname}"`, in this case evaluating to `"Any B"` is the default.
- Any other value. For example `"Any event"` for an adverse effects table.
- the value of pair's first column. In this case, the value of `A`.

**Usage**

```r
prep_hierarchical_fill(
  df,
  vars,
  fill = "Any {colname}",
  fill_from_left = FALSE
)
```

**Arguments**

- `df`: (data.frame)
- `vars`: (character) a vector of variables to generate pairs from.
- `fill`: (character) value to replace with. Defaults to `"Any {colname}"`, in which case `colname` will be replaced with the name of the column.
- `fill_from_left`: (logical) indicating whether to fill from the left (first) column in the pair. Defaults to `FALSE`. If `TRUE` it takes precedence over `fill`.

**Value**

a data.frame with the same columns as the input, but in which some the desired columns have been filled pairwise.

**Examples**

```r
df <- data.frame(
  x = c(1, 2, NA),
  y = c("a", NA, "b"),
  z = rep(NA, 3)
)

prep_hierarchical_fill(
  df,
  vars = c("x", "y")
)

prep_hierarchical_fill(
  df,
  vars = c("x", "y"),
  fill = "foo"
)

prep_hierarchical_fill(
  df,
  vars = c("x", "y", "z"),
  fill_from_left = TRUE
)
```

## `prep_big_n()` -- Prepare `bigN` stat variables

`prep_big_n()`:

- recodes the `"n"` `stat_name` into `bigN` for the desired variables, and
- drops all other `stat_names` for the same variables.

If your `tfrmt` contains a `big_n_structure()` you pass the tfrmt `column` to `prep_big_n()` via `vars`.

**Usage**

```r
prep_big_n(df, vars)
```

**Arguments**

- `df`: (data.frame)
- `vars`: (character) a vector of variables to prepare `bigN` for.

**Value**

a data.frame with the same columns as the input. The `stat_name` column is modified.

**Examples**

```r
df <- data.frame(
  stat_name = c("n", "max", "min", rep(c("n", "N", "p"), times = 2)),
  context = rep(c("continuous", "hierarchical", "categorical"), each = 3),
  stat_variable = rep(c("a", "b", "c"), each = 3)
) |>
  dplyr::bind_rows(
    data.frame(
      stat_name = "n",
      context = "total_n",
      stat_variable = "d"
    )
  )

prep_big_n(
  df,
  vars = c("b", "c")
)
```
