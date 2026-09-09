---
name: ard-creation
description: Build ARDs (Analysis Results Datasets) in R with cards and
  cardx. Use whenever the user asks for an ARD, or for the numbers
  behind a table -- counts, descriptive statistics, or test results.
---

# Analysis Results Datasets

Setup: load cards; add cardx and broom as needed.

## Decision order
1. {cards} ard_*() first -- counting and tabulating, univariate
   summaries, some multivariable summaries, and more:
   ard_tabulate(), ard_summary(), ard_mvsummary(),
   ard_hierarchical(), ard_missing(); stack with ard_stack*()
2. statistical methods and tests -> {cardx}, e.g.
   ard_stats_t_test(), ard_regression()
3. method not in {cardx} -> wrap broom::tidy() and convert to ARD,
   e.g. \(x) t.test(x) |> broom::tidy() inside ard_summary()
4. no tidy method -> build the ARD brute force with tidy_as_ard(),
   nest_for_ard(), bind_ard()

Always check_ard_structure() the result.
