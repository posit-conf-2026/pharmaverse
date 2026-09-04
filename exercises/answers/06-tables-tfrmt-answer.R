# Table Exercise: AE summary table using {tfrmt}

# For this exercise, we will use an AE ARD (from the {cards} section) to
# create a {tfrmt} table


# Setup: run this first! --------------------------------------------------

## Load necessary packages
library(cards)
library(dplyr)
library(tidyr)
library(tfrmt)

## Import & subset data
adsl <- pharmaverseadam::adsl |> 
  dplyr::filter(SAFFL=="Y") 

adae <- pharmaverseadam::adae |> 
  dplyr::filter(SAFFL=="Y") |> 
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
