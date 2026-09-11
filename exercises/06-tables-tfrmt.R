# Table Exercise: AE summary table using {tfrmt}

# For this exercise, we will use an AE ARD (from the {cards} section) to
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


# A. Create the AE table shell - fill in the blanks ------------------------

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
#
# (2) Print the mock display so you can check your results.

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
        p = frmt("??", transform = ~ .*100) # transform proportion (cards default) to percentage
    ))
  )
)

# Part 2:
#
# (1) Update the mock: Add a big N to the column headers of the table via the big_n argument. 
#     Make sure the big N appears as "N=xxx" on a separate line than the column headers.
#
# (2) Print the mock display so you can check your results.

# Sample prompt for AI help:
# How would I add a big N to the column headers of a {tfrmt} table 
# so that it appears as "N=xxx" on a separate line than the column headers?

mock_tfrmt <- mock_tfrmt |> 
  tfrmt(
    big_n = big_n_structure(param_val = "n", n_frmt = frmt("??"))
  )



# B. Create a tidy, tfrmt-ready ARD from the `cards` object  --------------------------

# Run the below code to transform the data and get it ready for tfrmt. 
# Hint: ask Posit assistant to explain the steps to you


ard_ae_tidy <- ard_ae |> 
  shuffle_card(fill_hierarchical_overall = "ANY EVENT") |> 
  prep_big_n(vars = "ARM") |> 
  prep_hierarchical_fill(vars = c("AESOC","AEDECOD"), fill_from_left = TRUE)|> 
  dplyr::select(-c(context, stat_label, stat_variable)) |> 
  dplyr::mutate(
    ord1 = dplyr::case_when(
      AESOC == "ANY EVENT" ~ 1,
      TRUE ~ as.integer(
        factor(AESOC, levels = unique(AESOC[AESOC != "ANY EVENT"]))
      ) + 1
    ),
    ord2 = dplyr::if_else(AESOC == AEDECOD, 1, 2)
  )


# C. Print the table with real values -------------------------------------------------

# Print the final AE table with real values using:
#  - `ard_ae_tidy` from part B
#  - `mock_tfrmt` spec from part A
# Make sure the table is sorted by ord1, ord2
# Also add a title, subtitle, and footnote to the table.
#
# Sample prompt:
# Using tfrmt, print a final AE table with real values using `ard_ae_tidy` and the `mock_tfrmt` spec, sorted by ord1 and ord2. 
# Also add a title, subtitle, and footnote to the table




# D. Output the table to PDF -------------------------------------------------

# Output your final table (from part C) to PDF using {docorator} with HTML flavor. 
# Add a header and footer to the document. 
#
# Sample prompt:
# Output my final AE table to PDF using {docorator} in the HTML flavor, 
# with a header and footer.
