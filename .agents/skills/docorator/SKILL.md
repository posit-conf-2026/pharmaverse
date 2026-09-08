---
name: docorator
description: Use when turning a finished display (a `gt` table -- including `tfrmt::print_to_gt()` output -- a `gt_group`, a `ggplot`, or a PNG) into a production PDF/RTF/DOCX with document headers, footers, and page numbers. Triggers on "docorator", "decorate the table", page numbers or headers in a PDF, or a display that renders in R but needs to become a deliverable file. For building the table itself see the tfrmt skill.
---


## Workflow

1. Build a display: a `gt_tbl`/`gt_group`, a `ggplot`, a PNG path (via `png_path()`), or a list of these.
2. Wrap it with `as_docorator()`, supplying headers/footers.
3. Render with `render_pdf()`, `render_rtf()`, and/or `render_docx()` — these return the
 docorator object invisibly, so they can be piped and chained.

```r
library(docorator)
library(gt)

exibble |>
  gt() |>
  as_docorator(
    display_name = "mytbl",
    header = fancyhead(
      fancyrow(left = "My Study", center = NA, right = doc_pagenum()),
      fancyrow(left = "My Population", center = NA, right = NA),
      fancyrow(left = NA, center = "My Table", right = NA)
    ),
    footer = fancyfoot(
      fancyrow(left = "mypath/mytbl.R", center = NA, right = doc_datetime())
    )
  ) |>
  render_pdf() |>
  render_rtf()
```

If `header`/`footer` are omitted, `as_docorator()` defaults to a page number in the upper right.
The docorator object is saved as an `.RDS` file (at `display_loc`) for reproducible re-rendering.

## What `x` can be

`gt`; `gt_group` (list of `gt`s); `ggplot`; list of `ggplot`s; `png_path("f.png")`;
list of PNG paths. A **list** of any mix of these becomes a **multi-page**
document, one element per page.

## Headers and footers

`header` takes a `fancyhead()`, `footer` takes a `fancyfoot()`; both take one
`fancyrow()` per line of text. `fancyrow(left = NA, center = NA, right = NA)` --
each position is optional, `NA` means blank, and the first positional argument is
`left`.

Automated content helpers:

| Helper | Puts in |
|---|---|
| `doc_pagenum()` | "Page X of Y" style numbering -- **PDF LaTeX only** |
| `doc_datetime()` | Render timestamp |
| `doc_path(filename, path)` | Program/output path string |

Header/footer height is computed from the number of lines, so every extra
`fancyrow()` eats vertical space available to the display.

## Sizing

**Tables.** `tbl_scale = TRUE` (default) resizes all columns to fill the
allotted width: stub column(s) get `tbl_stub_pct` (default `0.3`) of the total,
remaining columns split the rest equally. To control widths yourself, use
`gt::cols_width()` with **percent** widths and set `tbl_scale = FALSE` --
otherwise dynamic scaling overrides them (px widths warn and fall back to
scaling).

**Figures.** `fig_dim = c(height, width)` in inches, default `c(5, 8)`. For DPI
or finer control, `ggplot2::ggsave()` first and pass `png_path("myplot.png")`.

**Document.** `geometry = geom_set(...)` -- LaTeX `geometry` options, overridden
selectively (e.g. `geom_set(top = "0.5in", bottom = "0.5in")`). Defaults are
landscape letter, 1in left/right and 1.25in top/bottom margins. `fontsize`
accepts only `10`, `11`, `12`.

## Render specifics

- **`render_pdf()`** -- LaTeX via R Markdown. Escape hatches for LaTeX-literate
  users: `transform`, `header_latex`, `escape_latex`, `keep_tex`.
- **`render_rtf()`** -- RTF drops much of the styling and the document header
  entirely; only `center` text survives as a title.
- **`render_docx()`** -- Word output; same call shape.

All render functions take `display_loc`.
