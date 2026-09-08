# Table Exercise: AE summary table using {tfrmt}

# For this exercise, we will use the AE ARD from the last section to
# create a {tfrmt} table

# Setup: run this first! --------------------------------------------------

## Load necessary packages
library(cards)
library(dplyr)
library(tidyr)
library(tfrmt)
library(docorator)

## Import & subset data
adsl <- pharmaverseadam::adsl |>
  dplyr::filter(SAFFL == "Y") |>
  dplyr::mutate(ARM2 = ifelse(startsWith(ARM, "Xanomeline"), "Xanomeline", ARM))

adae <- pharmaverseadam::adae |>
  dplyr::filter(SAFFL == "Y") |>
  dplyr::filter(AESOC %in% unique(AESOC)[1:3]) |>
  dplyr::group_by(AESOC) |>
  dplyr::filter(AEDECOD %in% unique(AEDECOD)[1:3]) |>
  dplyr::ungroup()

## Create AE Summary using cards
ard_ae <- ard_stack_hierarchical(
  data = adae,
  variables = c(AESOC, AEDECOD),
  by = ARM,
  id = USUBJID,
  denominator = adsl,
  over_variables = TRUE,
  statistic = ~ c("n", "p")
)

# Exercise: AE summary table --------------------------------------------


# A. Fill in the blanks (with AI help) 

# Below is a skeleton for a mock AE table shell with the following specs:
# - AEDECOD (Preferred Term) nested within AESOC (System Organ Class) in rows
# - 3 treatment arms in the columns (ARM)
# - Big N (group-level population counts) in the column headers, in a new line as "N=xx"
# - n (number of subjects with the AE) and p (proportion of subjects with
#   the AE) in the body of the table, displayed as "n (%)" where n has 2 digits, 
#   and % is rounded to zero decimal places. 
#
# Replace each ?? below. Rather than asking the AI to fill in all ?? at once,
# ask it targeted questions about individual arguments, e.g.
# "How do I control the number of digits shown for n vs. p when each uses
#   its own frmt() inside frmt_combine()?"
# Use its answers to fill in the ?? yourself.
#
# Ask AI to print the mock display so you can check your results. 

mock_tfrmt <- tfrmt(
  group = "AESOC",
  label = "AEDECOD",
  column = "ARM",
  param = "stat_name",
  value = "stat",
  body_plan = body_plan(
    frmt_structure(group_val = ".default", label_val = ".default", 
      frmt_combine(
        "??",
        n = frmt("??"),
        p = frmt("??")
    ))
  ),
  big_n = big_n(param_val = "n", n_frmt = frmt("??"))
)


# B. Run the prompt -----------------------------------------------------

# Run the prompt below and paste the resulting code into your R script.
# Before running it, inspect `ard_ae` (e.g. `dplyr::glimpse(ard_ae)` or
# `dplyr::distinct(ard_ae, stat_name)`) so you can sanity-check the AI's
# output against the actual columns and values in the data.

# PROMPT:
# Convert the `cards` object `ard_ae` (created by `ard_stack_hierarchical()`
# with variables AESOC and AEDECOD, by = ARM, statistic = ~ c("n", "p")) into
# a tidy data frame ready for {tfrmt}. Requirements:
# - Keep one row per AESOC/AEDECOD/ARM/statistic combination.
# - Include only the columns needed for the table: the nested group
#   variables (AESOC, AEDECOD), the column variable (ARM), the statistic
#   name (e.g. "n" or "p"), and the statistic's numeric value.
# - Name the columns so they align with the `group`, `label`, `column`,
#   `param`, and `value` arguments I used in the `mock_tfrmt` spec from
#   part A.
# - Drop any overall/"Total" rows unless I ask for them, and drop rows for
#   AESOC or AEDECOD's own summary statistics that aren't "n" or "p".
# - Show me the result with `dplyr::glimpse()` so I can check it before
#   using it.



# C. Write your own prompt 

# Now write a prompt asking the AI to print a final AE table with real
# values, by supplying `ard_ae_tidy` from part B. to the `mock_tfrmt` spec from part A. 
# Ask it to add a title, subtitle, and footnote to the table.



# D. Write your own prompt 

# Write a prompt asking the AI to output your final table (from part C) to
# PDF (html engine) using {docorator}, in the HTML flavor. 
# Add a header and footer to the document. Save the PDF to the same directory as the exercise.
