---
name: gtsummary-tables
description: Build clinical summary tables in R with crane, gtsummary,
  and cards. Use whenever the user asks for a summary / demographics /
  AE / lab table or a "Table 1".
---

# Clinical summary tables

Setup: load tidyverse, crane, gtsummary, cards; then
crane::theme_gtsummary_roche().

## Decision order
1. {crane} wrapper (tbl_roche_summary(), tbl_baseline_chg()) if one fits
2. else {gtsummary} tbl_*() (tbl_summary(), tbl_hierarchical())
3. complex/custom -> ARD-first: cards::ard_stack() / cardx::ard_*()
   -> tbl_ard_*()
4. last resort -> build the ARD, then as_gtsummary()

Never use gtsummary::tbl_custom_summary(): it is not ARD-based.

Always gather_ard() the result for QC.
