# Cell formatting reference

Detail on how tfrmt formats individual cell values and targets those rules to
specific rows/params via `body_plan()`.

## `frmt()` — base format

```r
frmt(expression, missing = NULL, scientific = NULL, transform = NULL)
```

- `expression`: pattern string where each `x` is a digit placeholder, e.g. `"xx.x"`,
  `"xxx %"`. Extra `x`s to the left of the decimal print as spaces (for
  right-alignment padding); non-`x` characters print literally.
- `missing`: value to display when the input is `NA` (default `""`).
- `scientific`: string appended for scientific-notation display, e.g. `"x10^xx"`.
- `transform`: a formula/function applied to the value before formatting, e.g.
  `~.*100` to convert a proportion to a percent before rounding.

```r
frmt("xxx %")
frmt("xx.xxx")
frmt("xx.xx", scientific = "x10^xx")
frmt("xx.x", transform = ~.*100)   # proportion -> percent
```

## `frmt_combine()` — merge multiple params into one cell

```r
frmt_combine(expression, ..., missing = NULL)
```

Use when two or more rows sharing the same group/label (distinguished by `param`)
should render together in a single displayed cell (e.g. `"n (%)"`).

- `expression`: a `glue::glue()`-style template referencing each `param` value as
  `"{param_name}"`.
- `...`: named arguments mapping each `param` name to its own `frmt()` (or
  `frmt_when()`); a single `frmt()` can also be reused for all params.
- `missing`: value used when *all* combined params are missing.

```r
frmt_combine(
  "{n} {pct}",
  n = frmt("xxx"),
  pct = frmt_when("==100" ~ "(100%)", "==0" ~ "", TRUE ~ frmt("(xx.x %)"))
)
```

## `frmt_when()` — conditional formatting by value

```r
frmt_when(..., missing = NULL)
```

`case_when()`-style: a series of two-sided formulas where the LHS is a boolean
condition string evaluated against the value (e.g. `">3"`, `"==100"`, or `"TRUE"` as
a catch-all), and the RHS is a `frmt()` (or literal string) applied when the
condition is the first to match, evaluated top to bottom.

```r
frmt_when(
  ">0.99" ~ ">0.99",
  "<0.001" ~ "<0.001",
  TRUE ~ frmt("x.xxx")
)

frmt_when(
  "==100" ~ frmt(""),
  "==0" ~ "",
  "TRUE" ~ frmt("(xxx.x%)")
)
```

## Targeting formats to rows: `body_plan()` / `frmt_structure()`

```r
body_plan(...)                                      # list of frmt_structure() objects
frmt_structure(group_val = ".default", label_val = ".default", ...)
```

- `body_plan()` takes a list of `frmt_structure()` rules; when multiple rules could
  match the same cell, more specific rules should be listed after more general ones
  (later matches win in a bottom-up sense).
- `group_val`: string, vector, or **named list** (one entry per grouping column when
  there are multiple `group` columns) identifying which group value(s) a rule
  applies to. `".default"` is the catch-all fallback.
- `label_val`: string(s) identifying which row label(s) a rule applies to;
  `".default"` for all labels.
- `...`: exactly one of `frmt()`, `frmt_combine()`, or `frmt_when()`. This argument
  can additionally be **named by a `param` value** to restrict the rule to just that
  parameter within a shared group/label — useful when most params in a block share
  one format but one (e.g. a p-value row) needs a different one.

```r
body_plan(
  frmt_structure(group_val = ".default", label_val = ".default",
                 frmt_combine("{n} {pct}", n = frmt("xxx"), pct = frmt("xx.x"))),
  frmt_structure(group_val = ".default", label_val = "n", frmt("xxx")),
  frmt_structure(group_val = ".default", label_val = c("Mean", "Median", "Min", "Max"),
                 frmt("xxx.x")),
  frmt_structure(group_val = ".default", label_val = ".default",
                 p = frmt_when(">0.99" ~ ">0.99", "<0.001" ~ "<0.001", TRUE ~ frmt("x.xxx")))
)

# Multiple group columns: target one specific combination
frmt_structure(
  group_val = list(grp_col1 = "group1", grp_col2 = "subgroup3"),
  label_val = ".default",
  frmt("xxx")
)
```
