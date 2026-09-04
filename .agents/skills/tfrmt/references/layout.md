# Column and row layout reference

Detail on selecting/arranging display columns, styling their alignment/width, and
controlling how row groups are displayed — plus footnotes and Big N.

## `col_plan()` — select, reorder, rename, span columns

```r
col_plan(..., .drop = FALSE)
```

- `...`: tidyselect expressions, unquoted column names (optionally `new_name =
  old_name` to rename), `-col` to deselect, and/or `span_structure()` calls to build
  spanning headers. If a column is selected more than once, its *last* mention
  determines its final position.
- `.drop`: if `TRUE`, drop any columns not explicitly listed; default `FALSE` keeps
  unlisted columns (appended after those explicitly placed).
- Renaming a `group`/`label` variable inside `col_plan()` renames the stub header;
  showing multiple stub headers as separate columns requires
  `row_grp_plan(label_loc = element_row_grp_loc(location = "column"))` (see below).

```r
col_plan(
  col_1, -col_last,
  span_structure(c1 = "Top Label Level 1", c2 = "Second Level 1.1", c3 = c(col_3, col_4)),
  span_structure(c2 = "Top Label Level 2", c3 = c(col_6, col_7))
)

col_plan(my_col_1, new_col_1 = col_2, everything())

col_plan(my_grp = group, label, starts_with("col"))   # rename stub header
```

### `span_structure()` — multi-level spanning headers

```r
span_structure(...)
```

Named arguments correspond to the `column` variable(s) declared in `tfrmt()`,
defining nested spanning header levels; column values can be renamed via
`New Name = old_value`.

## `col_style_plan()` — alignment and width

```r
col_style_plan(...)   # series of col_style_structure()
col_style_structure(col, align = NULL, type = c("char", "pos"), width = NULL, ...)
```

- `col`: which display column(s) to style — unquoted name, `vars()`, tidyselect
  helper, or a `span_structure()` (to target spanned columns specifically).
- `align`: for `type = "char"` — `"left"`, `"right"`, or a vector of characters to
  align on in priority order (e.g. `c(".", ",", " ")` aligns on decimal point, then
  comma, then space — first match in the string wins). For `type = "pos"` — a vector
  of template strings with `x` placeholders and `|` marking alignment bars, for
  positional/multi-decimal alignment.
- `width`: numeric (or numeric string) column width in characters.

```r
col_style_plan(
  col_style_structure(col = "my_var", align = "left", width = 100),
  col_style_structure(col = vars(four), align = "right"),
  col_style_structure(col = vars(two, three), align = c(".", ",", " ")),
  col_style_structure(col = span_structure(span = value, col = val2), width = 25)
)
```

## `row_grp_plan()` — row-group block styling

```r
row_grp_plan(..., label_loc = element_row_grp_loc(location = "indented"))
row_grp_structure(group_val = ".default", element_block)
```

- `...`: one or more `row_grp_structure()` objects, each pairing a `group_val` with
  an `element_block()` that controls spacing/border around that group's block (e.g.
  `post_space` to add blank space or a rule after the group).
- `label_loc`: `element_row_grp_loc(location = ...)` where `location` is one of
  `"indented"` (default; group label shown as an indented header row above its
  rows), `"column"` (group shown in its own stub column alongside the row label),
  or `"spanning"` (group label spans the full table width as a header row).

```r
row_grp_plan(
  row_grp_structure(group_val = c("A", "C"), element_block(post_space = "---")),
  row_grp_structure(group_val = c("B"), element_block(post_space = " ")),
  label_loc = element_row_grp_loc(location = "column")
)

# Multiple grouping variables
row_grp_structure(group_val = list(grp1 = "A", grp2 = "b"), element_block(post_space = " "))
```

## Footnotes: `footnote_plan()` / `footnote_structure()`

```r
footnote_plan(..., marks = c("numbers", "letters", "standard", "extended"),
              order = c("marks_first", "preserve_order", "marks_last"))
footnote_structure(footnote_text, column_val = NULL, group_val = NULL, label_val = NULL)
```

- `footnote_structure()` with no `column_val`/`group_val`/`label_val` produces a
  plain source note (no footnote mark). Supplying one or more of those targets the
  footnote mark to a specific column/group/label (a named list handles multiple
  grouping variables).
- `marks`: symbol style used for footnote reference marks.
- `order`: how footnotes are ordered in the footer (marks first, preserve authoring
  order, or marks last).

```r
footnote_plan(
  footnote_structure(footnote_text = "footnote", group_val = "Group 1"),
  marks = "letters"
)

footnote_structure(footnote_text = "Source Note")            # plain source note
footnote_structure("Text", column_val = "Placebo")            # marked footnote on a column
```

## Big N: `big_n()` / `big_n_structure()`

```r
big_n_structure(param_val, n_frmt = frmt("\nN = xx"), by_page = FALSE)
```

- `param_val`: which `param` value(s) in the data represent subject totals ("Big
  N"); matching rows are removed from the table body and their formatted value is
  inserted into the corresponding column header instead.
- `n_frmt`: a `frmt()` controlling how the Big N is displayed (default puts
  `"N = xx"` on its own line below the column label).
- `by_page`: if `TRUE` (used together with `page_plan`), computes a separate Big N
  per page rather than one overall N.

Passed to `tfrmt(big_n = ...)`.
