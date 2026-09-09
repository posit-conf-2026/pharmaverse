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


# Exercise ----------------------------------------------------------------


# A. Fill in the blanks --------------------------------------------------

# Part 1:
#
# n (p) together in the same cell, n and p both with two digits and no
# decimal places.

mock_tfrmt <- tfrmt(
  group = "AESOC",
  label = "AEDECOD",
  column = "ARM",
  param = "stat_name",
  value = "stat",
  body_plan = body_plan(
    frmt_structure(group_val = ".default", label_val = ".default", 
      frmt_combine(
        "{n} ({p}%)",
        n = frmt("xx"),
        p = frmt("xx")
    ))
  )
)

print_mock_gt(mock_tfrmt)

# Part 2:
#
# Add a big N to the column headers, appearing as "N=xxx" on a separate
# line from the column headers.

mock_tfrmt <- mock_tfrmt |> 
  tfrmt(
    big_n = big_n_structure(param_val = "bigN", n_frmt = frmt("<br>N=xx"))
  )

# Preview the shell (no real data needed)
mock_tfrmt |> print_mock_gt()


# B. Convert `ard_ae` into a tidy data frame for {tfrmt} ------------------

# Inspect the card first
dplyr::glimpse(ard_ae)
dplyr::distinct(ard_ae, stat_name)

ard_ae_tidy <- ard_ae |>
  # Turn the card into a tidy frame; fill in an "Any Event" summary row 
  tfrmt::shuffle_card(fill_hierarchical_overall = "ANY EVENT") |>
  # Big Ns: recode `stat_name == "n"` to "bigN" for the ARM (column) variable,
  # dropping ARM's other stats (e.g. its own "N")
  tfrmt::prep_big_n(vars = "ARM") |>
  # Fill AESOC/AEDECOD at summary rows so every row has both group and label
  tfrmt::prep_hierarchical_fill(vars = c("AESOC", "AEDECOD"), fill_from_left = TRUE) |>
  # Keep only the columns needed for the tfrmt spec above: group (AESOC),
  # label (AEDECOD), column (ARM), param (stat_name), value (stat)
  dplyr::select(AESOC, AEDECOD, ARM, stat_name, stat) |>
  # Drop AESOC/AEDECOD-level statistics that aren't n or p (e.g. "N")
  dplyr::filter(stat_name %in% c("n", "p", "bigN"))

dplyr::glimpse(ard_ae_tidy)


# C. Final table with title, subtitle, and footnote -----------------------

# Part 1:
#
# PROMPT USED:
# Using the mock_tfrmt spec I built in part A and the tidy data frame
# ard_ae_tidy from part B, create and print a final {tfrmt} AE summary table with
# real values. Requirements:
# - Reuse mock_tfrmt as the base spec
# - Add a title, subtitle, and footnote explaining the values in the table

final_tfrmt <- tfrmt(
  tfrmt_obj = mock_tfrmt,
  title = "Summary of Adverse Events",
  subtitle = "Safety Population",
  footnote_plan = footnote_plan(
    footnote_structure(
      footnote_text = "n = number of participants with at least one event; % = n / Big N * 100",
      group_val = ".default",
      label_val = ".default"
    )
  )
)

final_tfrmt |> print_to_gt(ard_ae_tidy)

# Part 2:
#
# PROMPT USED:
# The p values in my table are all showing as "0%" instead of a sensible
# percentage. Why is that happening, and how can I fix it?


final_tfrmt <- tfrmt(
  tfrmt_obj = final_tfrmt,
    body_plan = body_plan(
    frmt_structure(group_val = ".default", label_val = ".default",
      frmt_combine(
        "{n} ({p}%)",
        n = frmt("xx"),
        p = frmt("xx", transform = ~ . * 100) # p was a proportion, we transform it to make it a percentage
    ))
  )
)

final_tfrmt |> print_to_gt(ard_ae_tidy)


# D. Output the final table to PDF via {docorator} (HTML flavor) ---------

# PROMPT USED:
# Add a header and footer to the document. Save the PDF to the same directory as the exercise.

final_tfrmt |>
  print_to_gt(ard_ae_tidy) |>
  as_docorator(
    display_name = "ae_summary_table",
    display_loc = "exercises",
    header = fancyhead(
      fancyrow(left = "Pharmaverse Training", center = NA, right = doc_pagenum()),
      fancyrow(left = NA, center = "Adverse Event Summary Table", right = NA)
    ),
    footer = fancyfoot(
      fancyrow(left = doc_path("06-tables-tfrmt.R", "exercises"), center = NA, right = doc_datetime())
  )
) |>
render_pdf(display_loc = "exercises")
