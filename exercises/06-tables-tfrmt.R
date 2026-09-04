# Table Exercise: AE summary table using {tfrmt}

# For this exercise, we will use the AE ARD from the last section to
# create a {tfrmt} table

# Setup: run this first! --------------------------------------------------

## Load necessary packages
library(cards)
library(dplyr)
library(tidyr)
library(tfrmt)

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

# Run the below prompts and paste the resulting code into your R script

# A. 

# Create and print a mock AE table using the {tfrmt} package. The shell should have the following specs:
# - AEDECOD (Preferred Term) nested within AESOC (System Organ Class) in the rows.
# - 3 treatment arms in the columns (ARM)
# - Big N (Group-level population counts in the column headers
# - n (number of subjects with the AE) and p (proportion of subjects with the AE) in the body of the table as "n (%)"



# B.

# Convert the `cards` object `ard_ae` into a tidy` data frame ready for {tfrmt}. 
# Keep only the required columns for the table. Ensure the names align to the spec above.



# C. 

# Print a final AE table with real values by supplying the tfrmt-ready data.
# Add a title, subtitle, and footnote to the table. 





# D.

# Output the final table to PDF (HTML flavor) using {docorator}.