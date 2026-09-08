#' Answer: Create the CM (Concomitant Medications) domain with sdtm.oak
#'
#' Complete solution for exercises/02-SDTM.R. WALKTHROUGH steps are the ones
#' coded together in the slides; EXERCISE steps are the ones learners fill in.
#'
#'   aCRF - slides/02-SDTM/metadata/CM_cdash_acrf.pdf

library(sdtm.oak)
library(dplyr)

# ---- Setup ------------------------------------------------------------------

# Read CT specification
study_ct <- read.csv("slides/02-SDTM/metadata/sdtm_ct.csv")

# Read in raw data
cm_raw <- read.csv("slides/02-SDTM/metadata/cm_raw.csv",
                   stringsAsFactors = FALSE)
cm_raw <- admiral::convert_blanks_to_na(cm_raw)

# Derive oak_id_vars
cm_raw <- cm_raw |>
  generate_oak_id_vars(
    pat_var = "PATNUM",
    raw_src = "cm_raw"
  )

# Read in DM domain (needed later to derive study day)
dm <- pharmaversesdtm::dm
dm <- admiral::convert_blanks_to_na(dm)

# ---- Build the CM domain ----------------------------------------------------

cm <-
  # === WALKTHROUGH: topic variable (assign_no_ct) =========================
  assign_no_ct(
    raw_dat = cm_raw,
    raw_var = "IT.CMTRT",
    tgt_var = "CMTRT"
  ) |>

  # --- EXERCISE 1: CMDOS (numeric dose) ----------------------------------
  assign_no_ct(
    raw_dat = condition_add(cm_raw, grepl("^-?\\d*(\\.\\d+)?(e[+-]?\\d+)?$", cm_raw$IT.CMDSTXT)),
    raw_var = "IT.CMDSTXT",
    tgt_var = "CMDOS",
    id_vars = oak_id_vars()
  ) |>

  # --- EXERCISE 2: CMDOSTXT (non-numeric dose) ---------------------------
  assign_no_ct(
    raw_dat = condition_add(cm_raw, grepl("[^0-9eE.-]", cm_raw$IT.CMDSTXT)),
    raw_var = "IT.CMDSTXT",
    tgt_var = "CMDOSTXT",
    id_vars = oak_id_vars()
  ) |>

  # --- EXERCISE 3: CMDOSU (dose unit, codelist C71620) -------------------
  assign_ct(
    raw_dat = cm_raw,
    raw_var = "IT.CMDOSU",
    tgt_var = "CMDOSU",
    ct_spec = study_ct,
    ct_clst = "C71620",
    id_vars = oak_id_vars()
  ) |>

  # --- EXERCISE 4: CMDOSFRM (dose form, codelist C66726) -----------------
  assign_ct(
    raw_dat = cm_raw,
    raw_var = "IT.CMDOSFRM",
    tgt_var = "CMDOSFRM",
    ct_spec = study_ct,
    ct_clst = "C66726",
    id_vars = oak_id_vars()
  ) |>

  # --- EXERCISE 5: CMDOSFRQ (dose frequency, codelist C71113) ------------
  assign_ct(
    raw_dat = cm_raw,
    raw_var = "IT.CMDOSFRQ",
    tgt_var = "CMDOSFRQ",
    ct_spec = study_ct,
    ct_clst = "C71113",
    id_vars = oak_id_vars()
  ) |>

  # === WALKTHROUGH: variable qualifier with CT (assign_ct) ================
  assign_ct(
    raw_dat = cm_raw,
    raw_var = "IT.CMROUTE",
    tgt_var = "CMROUTE",
    ct_spec = study_ct,
    ct_clst = "C66729",
    id_vars = oak_id_vars()
  ) |>

  # === WALKTHROUGH: a collected date (assign_datetime) ====================
  assign_datetime(
    raw_dat = cm_raw,
    raw_var = "IT.CMSTDAT",
    tgt_var = "CMSTDTC",
    raw_fmt = c("d-m-y"),
    raw_unk = c("UN", "UNK")
  ) |>

  # === WALKTHROUGH: conditional constant (hardcode_ct + condition_add) ====
  hardcode_ct(
    raw_dat = condition_add(cm_raw, IT.CMONGO == "Yes"),
    raw_var = "IT.CMONGO",
    tgt_var = "CMENRTPT",
    ct_spec = study_ct,
    ct_clst = "C66728",
    tgt_val = "Ongoing",
    id_vars = oak_id_vars()
  ) |>

  # === WALKTHROUGH (with AI): CMINDC — the last one we do together ========
  # Filled in by the AI agent from the prompt in the exercise file, then
  # reviewed against the aCRF.
  assign_no_ct(
    raw_dat = cm_raw,
    raw_var = "IT.CMINDC",
    tgt_var = "CMINDC",
    id_vars = oak_id_vars()
  ) |>

  # --- EXERCISE 6: CMENTPT (hardcoded, no codelist) ----------------------
  hardcode_no_ct(
    raw_dat = condition_add(cm_raw, IT.CMONGO == "Yes"),
    raw_var = "IT.CMONGO",
    tgt_var = "CMENTPT",
    tgt_val = "DATE OF LAST ASSESSMENT",
    id_vars = oak_id_vars()
  ) |>

  # --- EXERCISE 7: CMENDTC (end date) ------------------------------------
  assign_datetime(
    raw_dat = cm_raw,
    raw_var = "IT.CMENDAT",
    tgt_var = "CMENDTC",
    raw_fmt = c("d-m-y"),
    raw_unk = c("UN", "UNK")
  ) |>

  # === WALKTHROUGH: identifiers, derived vars & final ordering ============
  dplyr::mutate(
    STUDYID = "test_study",
    DOMAIN = "CM",
    CMCAT = "GENERAL CONMED",
    USUBJID = paste0("test_study", "-", cm_raw$PATNUM)
  ) |>
  derive_seq(tgt_var = "CMSEQ",
             rec_vars = c("USUBJID", "CMTRT")) |>
  derive_study_day(
    dm_domain = dm,
    tgdt = "CMENDTC",
    refdt = "RFXSTDTC",
    study_day_var = "CMENDY"
  ) |>
  derive_study_day(
    dm_domain = dm,
    tgdt = "CMSTDTC",
    refdt = "RFXSTDTC",
    study_day_var = "CMSTDY"
  ) |>
  dplyr::select("STUDYID", "DOMAIN", "USUBJID", "CMSEQ", "CMTRT", "CMCAT", "CMINDC",
                "CMDOS", "CMDOSTXT", "CMDOSU", "CMDOSFRM", "CMDOSFRQ", "CMROUTE",
                "CMSTDTC", "CMENDTC", "CMSTDY", "CMENDY", "CMENRTPT", "CMENTPT")
