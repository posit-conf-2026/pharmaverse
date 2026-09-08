---
name: cards-to-tfrmt
description: Use when turning a `cards` ARD (cards::ard_stack(), ard_stack_hierarchical(), ard_categorical(), ard_summary()) into a tfrmt-ready tidy data frame. Triggers on "cards to tfrmt", `card` objects, requests for a display-ready ARD or tfrmt-ready ARD, or errors/blank tables from feeding cards output straight to tfrmt. For the table format itself (plans, frmts, rendering) see the tfrmt skill.
---

# cards to tfrmt

`cards` output is **not** directly tfrmt-ready: a `card` object is long and
generic, with `group1`/`group1_level`/`variable`/`variable_level` columns rather
than the named group/label/column variables a tfrmt refers to. The prep
functions live in `tfrmt` itself (`tfrmt::shuffle_card()`, `tfrmt::prep_*()`)
and reshape a card into that tidy shape.

## Target shape

A tfrmt-ready ARD is long-format -- one row per computed value -- with:

- one or more **group** columns (optional), a single **label** column,
- one or more **column** columns (>1 enables spanning headers),
- a single **param** column (which statistic: `n` vs `pct` vs `bigN`),
- a single numeric **value** column,
- optional **sorting** columns for row order.

After `shuffle_card()` the columns are `<by vars>`, `<variable columns>`,
`context`, `stat_variable`, `stat_name`, `stat_label`, `stat` -- so the tfrmt
maps **`param = stat_name`** and **`value = stat`**, with the `by` variable(s)
as `column` and `stat_variable`/`label` as group/label.

## Workflow

1. **`shuffle_card()` first, always.** Pivots the card wide on its
   grouping/variable columns and fills overall / any-event levels.
2. **Collapse row variables into one label column.** `prep_combine_vars()` then
   `prep_label()` for a categorical/continuous mix; `prep_hierarchical_fill()`
   for SOC/PT-style stacks.
3. **`prep_big_n(vars = <the tfrmt's column variable>)`** if the tfrmt has a
   `big_n_structure()`.
4. **Additional data manipulation**: rename `stat_variable`/`label` values, add sort columns,
   and drop the columns tfrmt has no role for (`context`, `stat_label`,
   `variable_level`, ...). 

### Categorical + continuous example (demog-style)

```r
ard <- cards::ard_stack(
  data = adsl,
  .by = ARM,
  cards::ard_summary(variables = AGE,
                     statistic = ~ cards::continuous_summary_fns(c("median", "p25", "p75"))),
  cards::ard_categorical(variables = c(AGEGR1, SEX), statistic = ~ c("n", "p"))
)

tidy_ard <- ard |>
  tfrmt::shuffle_card(fill_overall = "Overall") |>
  tfrmt::prep_combine_vars(c("AGE", "AGEGR1", "SEX")) |>  # sparse var cols -> variable_level
  tfrmt::prep_label() |>                                  # stat_label + variable_level -> label
  tfrmt::prep_big_n(vars = "ARM") |>
  dplyr::mutate(
    label = dplyr::case_when(stat_name %in% c("p25", "p75") ~ "[Q1, Q3]", TRUE ~ label),
    stat_variable = dplyr::case_match(stat_variable,
      "AGE" ~ "Age (years)", "AGEGR1" ~ "Age Group", "SEX" ~ "Sex")
  ) 
```

### Hierarchical example (AE / SOC-PT)

```r
tidy_ard <- cards_ard |>                                   # ard_stack_hierarchical()
  tfrmt::shuffle_card(fill_hierarchical_overall = "ANY EVENT") |>
  tfrmt::prep_big_n(vars = "ARM") |>
  tfrmt::prep_hierarchical_fill(vars = c("AESOC", "AEDECOD"), fill_from_left = TRUE) |>
  dplyr::select(-c(context, stat_label, stat_variable))
```

`prep_combine_vars()` deliberately no-ops on hierarchical stacks (it detects
this from `context`), so use `prep_hierarchical_fill()` there instead.

## Helper reference

| Helper | Use when |
|---|---|
| `shuffle_card(x, by, trim, order_rows, fill_overall, fill_hierarchical_overall)` | Always, first -- turns a `card` into a tidy frame and fills overall/any-event levels |
| `prep_combine_vars(df, vars, remove)` | Sparse, mutually-exclusive variable columns to unite into one `variable_level`. No-ops (returns input unchanged) on hierarchical stacks or if the result wouldn't match `coalesce()` |
| `prep_label(df)` | Need a single `label` column combining `stat_label` (continuous) and `variable_level` (categorical) |
| `prep_hierarchical_fill(df, vars, fill, fill_from_left)` | Hierarchical (SOC/PT) data with `NA` at summary levels; fills pairwise left-to-right. `fill_from_left = TRUE` copies the parent's value (overrides `fill`) |
| `prep_big_n(df, vars)` | The tfrmt has a `big_n_structure()`; recodes `stat_name == "n"` to `"bigN"` for `vars` and drops that variable's other stats. Pass the tfrmt's `column` variable(s) |

Full argument lists, defaults, and worked examples:
`references/prep-functions.md`.

### Fill arguments

`fill_overall` (default `"Overall {colname}"`) and
`fill_hierarchical_overall` (default `"Any {colname}"`) are `glue` strings with
`colname` available, so `"Overall {colname}"` becomes `"Overall AGE"`. Pass a
plain string (`"Overall"`, `"ANY EVENT"`) for a fixed label, or `NA` to skip
filling.

## Downstream consequences for the tfrmt

- `param = stat_name`, `value = stat`.
- **Percentages arrive as proportions.** `cards`' `p` is `0.36`, not `36`, so
  the `frmt()` needs `transform = ~ . * 100` or the cell renders `0%`.
- `stat_name` values are `cards`' names (`n`, `p`, `N`, `median`, `p25`, ...),
  not `n`/`pct`, so `tfrmt_n_pct()`'s defaults won't match without renaming.
- Big N rows must carry the *original* `column` values, before any `col_plan()`
  renaming.
