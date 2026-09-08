# Pagination reference

`page_plan()` / `page_structure()` split a formatted table row-wise into multiple
`gt` tables — e.g. for RTF/PDF page breaks or tables too long to render sensibly as
one block. When a `page_plan` is set, `print_to_gt()`/`print_mock_gt()` return a
`gt::gt_group` (a collection of `gt` tables) instead of a single `gt` object.

## `page_plan()`

```r
page_plan(
  ...,                                   # one or more page_structure() objects
  note_loc = c("noprint", "preheader", "subtitle", "source_note"),
  max_rows = NULL,                       # numeric row limit per page
  transform = NULL                       # reformat page/note label text
)
```

- `...`: one or more `page_structure()` objects defining value-driven splits.
- `note_loc`: where to print a note describing each page's subset value(s) — useful
  when a split is on a group that's otherwise dropped from `col_plan()`, so the
  reader still knows which subset a page covers. Options: `"noprint"` (default),
  `"preheader"` (RTF output only), `"subtitle"`, `"source_note"`.
- `max_rows`: maximum rows per page (row count includes group-label-only rows). If
  both `page_structure()` splits and `max_rows` are given, structure-based splitting
  is applied first, then any resulting page exceeding `max_rows` is further split.
- `transform`: experimental; a function or one-sided formula (e.g. `~
  stringr::str_replace(.x, "grp", "Group")`) applied to the page/note label text to
  reword it.

## `page_structure()`

```r
page_structure(group_val = NULL, label_val = NULL)
```

- `group_val`: a string, `".default"`, or a **named list** of strings (one entry per
  grouping variable) indicating where to split. `".default"` splits after every
  unique value of that group variable; a specific value splits only after that
  value's block of rows.
- `label_val`: string or `".default"`, analogous behavior but keyed on the `label`
  variable — consecutive rows sharing the same label are treated as one block, and
  the split occurs after the last row of that block.
- Only one `page_structure()` in a given `page_plan()` may specify a non-default
  (specific) `label_val`.

## Behavior notes

- Value-driven splits (`page_structure`) and row-count-driven splits (`max_rows`)
  can be combined; structure splits happen first.
- If a `max_rows` split breaks a group's rows across two pages, the group's header
  label is repeated at the top of the continuation page.
- The optional per-page note (`note_loc`) states which group/label subset that page
  represents; `transform` can reword its text.
- Applying a `page_plan` changes the return type of `print_to_gt()` /
  `print_mock_gt()` from a single `gt` object to a `gt::gt_group`, which can be
  saved as a multi-page document with `gt::gtsave()`.

## Examples

```r
tfrmt(
  ...,
  page_plan = page_plan(
    page_structure(group_val = list(rowlbl1 = ".default")),
    note_loc = "source_note"
  )
) |> print_to_gt(data_demog2)

# Split on a specific value of one group column
page_plan(
  page_structure(group_val = list(rowlbl1 = "Age (y)")),
  note_loc = "source_note"
)

# Reword the per-page note
page_plan(
  page_structure(group_val = ".default"),
  note_loc = "source_note",
  transform = ~ stringr::str_replace(.x, "grp", "Group")
)

# Pure row-count-based pagination, no value-driven splits
page_plan(max_rows = 20)
```

See the package's dedicated `vignette("page_plan", package = "tfrmt")` for worked
examples built on the bundled `data_demog` dataset.
