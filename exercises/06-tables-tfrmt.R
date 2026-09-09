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
  dplyr::filter(SAFFL == "Y")

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


# A. Create the AE table shell - fill in the blanks

# Below is a skeleton for a mock AE table shell. The AE table is meant to have the following:
# - AEDECOD (Preferred Term) nested within AESOC (System Organ Class) 
# - 3 treatment arms in the columns (ARM)
# - the number and percentage of unique subjects with the AE presented in the 
#   cells (these are represented as 'n' and 'p' in the code)

# Part 1:
#
# (1) Replace the ??s in the snippet so that the n (%) is formatted as such:
#   - n and p together in the same cell, with parentheses and percentage sign like so: n (p%)
#   - n has two digits, no decimal places
#   - p also has two digits and no decimal places
# (2) Ask AI to print the mock display so you can check your results.

# Sample prompt for AI help:
# How would I format the n and p values in the cells of a {tfrmt} 
# table so that they appear as "n (p)" with n and p both having two 
# digits and no decimal places?  

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
  )
)

# Part 2:
#
# Add a big N to the column headers of the table via the big_n argument. 
# Make sure the big N appears as "N=xxx" on a separate line than the column headers.
# Add this to the mock from part 1 and ask AI to print the resulting mock display.
#
# Sample prompt for AI help:
# How would I add a big N to the column headers of a {tfrmt} table 
# so that it appears as "N=xxx" on a separate line than the column headers?

mock_tfrmt <- mock_tfrmt |> 
  tfrmt(
    big_n = big_n_structure(param_val = "n", n_frmt = frmt("??"))
  )

# B. Create a tidy, tfrmt-ready ARD from the `cards` object  ------------
#
# Ask the AI for assistance converting the `cards` ARD object from the top of 
# the script into a tfrmt-ready tidy data frame. 
# Tip: before doing so, inspect `ard_ae` (e.g. `dplyr::glimpse(ard_ae)` or 
# `dplyr::distinct(ard_ae, stat_name)`) so you can check your
# output against the actual columns and values in the data.

# Sample prompt:
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



# C. Print the table with real values -------------------------------------------------

# Part 1:
#
# Ask the AI to print a final AE table with real values, by supplying `ard_ae_tidy` from 
# part B. to the `mock_tfrmt` spec from part A. Ask it to add a title, subtitle, and footnote to the table.
#
# Sample prompt:
# Using tfrmt, how would I print a final AE table with real values using `ard_ae_tidy` and the `mock_tfrmt` spec, 
# and add a title, subtitle, and footnote to the table?


# Part 2:
#
# Notice that the percentage values are not right. Write a prompt asking
# the AI why the `p` values are showing as very low (e.g. "0%") in the
# table, and to propose a fix so `p` shows as a whole-number percent (e.g.
# "36%") in the table.



# D. Output the table to PDF -------------------------------------------------

# Ask the AI to output your final table (from part C) to PDF using {docorator}, 
# in the HTML flavor. Add a header and footer to the document. Save the PDF to 
# the same directory as the exercise.
#
# Sample prompt:
# How would I output my final AE table to PDF using {docorator} in the HTML flavor, 
# with a header and footer, and save the PDF to the same directory as this exercise
