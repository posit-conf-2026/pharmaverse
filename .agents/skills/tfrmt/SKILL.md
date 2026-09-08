---
name: tfrmt
description: Build ARD-first clinical/statistical tables with the tfrmt R package. Use when the user wants to format an Analysis Results Dataset (ARD) into a display table, mentions tfrmt, frmt(), frmt_combine(), frmt_when(), body_plan(), col_plan(), row_grp_plan(), col_style_plan(), footnote_plan(), big_n(), page_plan(), or wants to separate table formatting metadata from data (mock tables, gt output for clinical trial reporting).
---

# tfrmt

`tfrmt` applies display/formatting metadata to Analysis Results Datasets (ARDs) to
produce `gt`-based display tables, commonly used for clinical trial reporting
(demographics tables, AE tables, etc.). The key idea: the format spec (a `tfrmt`
object) is defined independently of the data, so mock tables can be designed before
real results exist, and the same spec can be reapplied as data updates.

## Input data requirements (ARD / tidy long format)

tfrmt expects one row per computed value, with these logical roles (mapped via
arguments to `tfrmt()`, using unquoted column names or character strings):

| Role | Required | Description |
|---|---|---|
| `group` | optional, 1+ cols | Row grouping variable(s) (e.g. treatment arm subgroup, AE category) |
| `label` | required, 1 col | Row label text |
| `column` | required, 1+ cols | Column(s) whose values become display table columns (multiple = spanning headers) |
| `param` | required, 1 col | Distinguishes value type per row (e.g. `"n"`, `"pct"`, `"mean"`, `"sd"`, `"pval"`) |
| `value` | required, 1 col | The raw numeric/character value to format |
| `sorting_cols` | optional, 1+ cols | Numeric column(s) controlling row order |

If the input is a raw `card` object (`group1`/`stat_name`-style columns), it
needs `shuffle_card()` and the `prep_*()` helpers first — see the sibling
**`cards-to-tfrmt`** skill.

## Workflow

1. Produce/QC an ARD (long, one record per computed value).
2. Define a `tfrmt()` spec describing structure and formatting — independent of the
   actual data values.
3. Preview the table shell with `print_mock_gt(tfrmt)` (works even with no real data,
   using placeholder values) to design/QC the mock before results are final.
4. Apply the spec to real data with `print_to_gt(tfrmt, .data)` to get the final `gt`
   table.
5. Further customize the returned `gt` object with standard `gt::` functions if needed, or output the data using `docorator` or `gt::gtsave()`.

```r
library(tfrmt)
library(dplyr)

tfrmt_spec <- tfrmt(
  group = group,
  label = label,
  column = column,
  param = param,
  value = value,
  sorting_cols = c(ord1, ord2),
  body_plan = body_plan(
    frmt_structure(group_val = ".default", label_val = ".default",
      frmt_combine("{n} {pct}",
        n = frmt("xxx"),
        pct = frmt_when("==100" ~ "(100%)", "==0" ~ "", TRUE ~ frmt("(xx.x %)"))))
  ),
  col_plan = col_plan(-group, -starts_with("ord")),
  col_style_plan = col_style_plan(
    col_style_structure(col = vars(everything()), align = c(".", ",", " "))
  ),
  row_grp_plan = row_grp_plan(
    row_grp_structure(group_val = ".default", element_block(post_space = " ")),
    label_loc = element_row_grp_loc(location = "column")
  )
)

# Preview shell before data is finalized
tfrmt_spec |> print_mock_gt()

# Apply to real ARD
tfrmt_spec |> print_to_gt(data_demog)
```

## `tfrmt()` arguments

```r
tfrmt(
  tfrmt_obj,        # existing tfrmt to layer/extend (new args take precedence)
  group = vars(),   # grouping column(s)
  label = quo(),    # row label column
  param = quo(),    # column identifying statistic type per row
  value = quo(),    # column holding the value to format
  column = vars(),  # column(s) that become display columns
  title, subtitle,  # table title/subtitle
  row_grp_plan,     # row_grp_plan(): row-group block styling/indentation
  body_plan,        # body_plan(): formatting rules for cell values
  col_style_plan,   # col_style_plan(): column alignment & width
  col_plan,         # col_plan(): select/reorder/rename/span display columns
  sorting_cols,     # column(s) controlling row order
  big_n,            # big_n_structure(): pull "Big N" rows into column headers
  footnote_plan,    # footnote_plan(): footnotes/source notes
  page_plan,        # page_plan(): split output across multiple tables/pages
  ...               # must be empty
)
```

NSE args (`group`, `label`, `param`, `value`, `column`, `sorting_cols`) accept
unquoted names, `vars()`, `quo()`, or strings. Passing `tfrmt_obj` layers a new spec
on top of an existing one (later args win).

## Key formatting features (see references/ for full detail)

- **Cell-level formatting** — `frmt()`, `frmt_combine()`, `frmt_when()`, and
  targeting rules to specific groups/labels/params via `body_plan()` /
  `frmt_structure()`. See **`references/formatting.md`**.
- **Column and row layout** — selecting/reordering/renaming/spanning columns with
  `col_plan()` / `span_structure()`, alignment and width via `col_style_plan()`,
  row-group block styling and label placement via `row_grp_plan()`, plus footnotes
  (`footnote_plan()`) and Big N handling (`big_n()`). See **`references/layout.md`**.
- **Pagination** — splitting a table row-wise across multiple `gt` tables/pages via
  `page_plan()` / `page_structure()`, either by group/label value or by
  `max_rows`. See **`references/pagination.md`**.

## Rendering

- `print_to_gt(tfrmt, .data)` — apply spec to real ARD data, returns a `gt` (or
  `gt::gt_group` if `page_plan` splits output).
- `print_mock_gt(tfrmt, .data = NULL)` — preview/design the mock table shell without full
  data (auto-fills placeholders); pass a skeleton `.data` (without `value`) to shape
  the mock more precisely. 
- tfrmt does **not** save tables to a document itself -- use `gt::gtsave()` (or
  the `docorator` skill) on the returned object.


## Mock shells

If a user explicitly requests a 'mock' display or a 'shell', use `print_mock_gt()` to preview the table structure, columns, and formatting without needing or using the final data. This is useful for designing the table before real results are available.

**Default to calling `print_mock_gt(tfrmt)` with no `.data` argument at all.** Do not
build a `.data` skeleton (e.g. via `tidyr::expand_grid()`) unless the user explicitly
asks to see real column/param values in the mock, or an existing ARD-shaped object is
what they asked to preview. 

- `print_mock_gt(tfrmt)` with no `.data` auto-generates placeholder group/label
  values (e.g. `"group_val_1"`) and generic column values (e.g. `ARM1`, `ARM2`)
  from the `tfrmt` spec's declared `column` variable(s). This is fine for a
  quick structural check, but if the user gave real column values (e.g. named
  treatment arms), it will **not** show those names — the header text will
  still read `ARM1`, `ARM2`, etc.
- To show real column/param values in the mock (without any outcome data),
  build a tiny skeleton with `tidyr::expand_grid()` covering every NSE role
  *except* `value`, and pass it as `.data`. Include one row per combination of
  `group` x `label` x `column` x `param` you want represented (a few dummy
  group/label values are enough):

  ```r
  mock_skel <- tidyr::expand_grid(
    <group_col> = "group_val",
    <label_col> = "label_val",
    <column_col> = c("Xanomeline High Dose", "Xanomeline Low Dose", "Placebo"),
    <param_col> = c("n", "p", "bigN")   # match param values used in body_plan/big_n
  )
  tfrmt_spec |> print_mock_gt(.data = mock_skel)
  ```
