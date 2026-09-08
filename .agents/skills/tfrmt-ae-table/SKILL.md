---
name: tfrmt-ae-table
description: Recipe for building an adverse event (AE) summary table in R with tfrmt. Triggers on requests for an AE / adverse-event / SOC-PT summary table, including a "mock" AE table (design the shell with print_mock_gt() before real data exists). Assumes a tfrmt-ready ARD already exists; for tfrmt mechanics see the tfrmt skill.
---

# tfrmt AE Table

Pattern for AE summary tables: hierarchical rows (system organ class
containing preferred terms), n (%) of subjects with the event per treatment
arm, and subject-count Ns in the column headers. The templates below are
generic -- swap in real column and label names from your own ARD.

For general tfrmt concepts (plans, structures, layering, ARD shape) not
specific to AE tables, see the sibling `tfrmt` skill and its topical
`references/` files. For demog-style tables, see `tfrmt-demog-table`.

This skill assumes the ARD already exists in a tfrmt-ready tidy shape. It
does not cover *producing* that ARD from ADaM data.

## Expected ARD shape

A typical AE table contains one row per `group` x `label` x `column`
x `param`:

| column | role |
|---|---|
| `AESOC` (or similar) | group -- system organ class |
| `AEDECOD` (or similar) | label -- preferred term |
| `ARM` (or similar) | column -- treatment arm |
| `stat_name` / `param` | param -- which statistic (`"n"`, `"p"`, `"bigN"`) |
| `stat` / `value` | numeric value |

SOC-only summary rows need their label column filled in (e.g. `AEDECOD`
equal to the SOC name) so they render as group-level rows rather than rows
with a missing label. Subject-count denominators belong in their own
`param == "bigN"` rows (see `tfrmt`'s Big Ns section), not as `N`/`p` rows
in the table body. `p`/`pct` values are commonly proportions (0-1) rather
than percents -- check before formatting.


## Basic pattern (n (%) by arm + Big Ns)

```r
ae_tfrmt <- tfrmt(
  group = <soc_col>,
  label = <pt_col>,
  param = <param_col>,   # e.g. "n", "p", "bigN"
  value = <value_col>,
  column = <arm_col>,
  body_plan = body_plan(
    frmt_structure(
      group_val = ".default", label_val = ".default",
      frmt_combine(
        "{n} ({p}%)",
        n = frmt("xx"),
        # if p is a proportion (0-1) rather than a percent, transform before rounding
        p = frmt("xx", transform = ~ . * 100)
      )
    )
  ),
  big_n = big_n_structure(param_val = "bigN")
)

ae_tfrmt |> print_to_gt(<ard>)
```

`transform = ~ . * 100` inside `frmt()` matters whenever the ARD's `p`/`pct`
values are proportions (e.g. `0.36`) rather than percents -- common when the
ARD was derived from `cards`/ADaM data -- since without the transform the
table would round to `"0%"`.

If your param values happen to be named `n` and `pct` and already hold
percents, `tfrmt_n_pct()` supplies this whole `body_plan` ready-made, including
sensible edge-case handling (`(<1%)`, `(>99%)`, blank at 0% and 100%):

```r
ae_tfrmt <- tfrmt_n_pct() |>
  tfrmt(group = <soc_col>, label = <pt_col>, param = <param_col>,
        value = <value_col>, column = <arm_col>,
        big_n = big_n_structure(param_val = "bigN"))
```
