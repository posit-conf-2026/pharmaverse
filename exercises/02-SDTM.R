#' Exercise: Create the CM (Concomitant Medications) domain with sdtm.oak
#'
#' The WALKTHROUGH steps we coded together in the slides are already filled in
#' (CMTRT, CMROUTE, CMSTDTC, CMENRTPT). Your job is to complete the EXERCISE
#' steps: each one gives you the aCRF annotation text and a suggested AI prompt.
#'
#' Two ways to solve each exercise step:
#'   (a) Code it by hand  - replace every ?? using the annotation text.
#'   (b) Use the AI agent - paste the suggested prompt (it uses the
#'       .agents/skills/sdtm-oak-mapping skill + the annotated CM aCRF).
#' Either way, review the result before moving on.
#'
#'   aCRF - slides/02-SDTM/metadata/CM_cdash_acrf.pdf

library(sdtm.oak)
library(dplyr)

# ---- Setup (provided) -------------------------------------------------------

# Read CT specification
study_ct <- read.csv("slides/02-SDTM/metadata/sdtm_ct.csv")

# Read in raw data
cm_raw <- read.csv("slides/02-SDTM/metadata/cm_raw.csv",
                   stringsAsFactors = FALSE)
cm_raw <- admiral::convert_blanks_to_na(cm_raw)

# Derive oak_id_vars
cm_raw <- cm_raw %>%
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
  # Medication name is collected as free text -> assign_no_ct.
  assign_no_ct(
    raw_dat = cm_raw,
    raw_var = "IT.CMTRT",
    tgt_var = "CMTRT"
  ) %>%

  # --- EXERCISE 1: CMINDC ------------------------------------------------
  # aCRF annotation: "CM.CMINDC" (Indication - free text, no codelist).
  # AI prompt:
  #   "Using the sdtm-oak-mapping skill and the CM aCRF, map CMINDC from
  #    IT.CMINDC. It is collected free text with no controlled terminology."
  assign_no_ct(
    raw_dat = cm_raw,
    raw_var = ??,
    tgt_var = ??,
    id_vars = oak_id_vars()
  ) %>%

  # --- EXERCISE 2: CMDOS (numeric dose) ----------------------------------
  # aCRF annotation: "If numeric then CM.CMDOS" (dose collected in IT.CMDSTXT).
  # Only map rows where the collected dose is numeric -> condition_add.
  # AI prompt:
  #   "Map CMDOS from IT.CMDSTXT, but only when the collected value is
  #    numeric. Use condition_add() with a regex around assign_no_ct."
  assign_no_ct(
    raw_dat = condition_add(cm_raw, grepl("^-?\\d*(\\.\\d+)?(e[+-]?\\d+)?$", cm_raw$IT.CMDSTXT)),
    raw_var = "IT.CMDSTXT",
    tgt_var = ??,
    id_vars = oak_id_vars()
  ) %>%

  # --- EXERCISE 3: CMDOSTXT (non-numeric dose) ---------------------------
  # aCRF annotation: "Else CM.CMDOSTXT" (dose text when not numeric).
  # Map rows where the collected dose is NOT numeric -> condition_add.
  # AI prompt:
  #   "Map CMDOSTXT from IT.CMDSTXT for the rows where the dose is not
  #    numeric (character), using condition_add() around assign_no_ct."
  assign_no_ct(
    raw_dat = condition_add(cm_raw, ??),
    raw_var = "IT.CMDSTXT",
    tgt_var = ??,
    id_vars = oak_id_vars()
  ) %>%

  # --- EXERCISE 4: CMDOSU (dose unit) ------------------------------------
  # aCRF annotation: "CM.CMDOSU" with codelist (UNIT) C71620.
  # Coded field -> assign_ct.
  # AI prompt:
  #   "Map CMDOSU from IT.CMDOSU applying controlled terminology codelist
  #    C71620 (UNIT) with assign_ct."
  assign_ct(
    raw_dat = cm_raw,
    raw_var = ??,
    tgt_var = ??,
    ct_spec = study_ct,
    ct_clst = ??,
    id_vars = oak_id_vars()
  ) %>%

  # --- EXERCISE 5: CMDOSFRM (dose form) ----------------------------------
  # aCRF annotation: "CM.CMDOSFRM" with codelist (FRM) C66726.
  # AI prompt:
  #   "Map CMDOSFRM from IT.CMDOSFRM applying codelist C66726 (FRM) with
  #    assign_ct."
  assign_ct(
    raw_dat = cm_raw,
    raw_var = ??,
    tgt_var = ??,
    ct_spec = study_ct,
    ct_clst = ??,
    id_vars = oak_id_vars()
  ) %>%

  # --- EXERCISE 6: CMDOSFRQ (dose frequency) -----------------------------
  # aCRF annotation: "CM.CMDOSFRQ" with codelist (FREQ) C71113.
  # AI prompt:
  #   "Map CMDOSFRQ from IT.CMDOSFRQ applying codelist C71113 (FREQ) with
  #    assign_ct."
  assign_ct(
    raw_dat = cm_raw,
    raw_var = ??,
    tgt_var = ??,
    ct_spec = study_ct,
    ct_clst = ??,
    id_vars = oak_id_vars()
  ) %>%

  # === WALKTHROUGH: variable qualifier with CT (assign_ct) ================
  # Route is a coded dropdown -> assign_ct with codelist (ROUTE) C66729.
  assign_ct(
    raw_dat = cm_raw,
    raw_var = "IT.CMROUTE",
    tgt_var = "CMROUTE",
    ct_spec = study_ct,
    ct_clst = "C66729",
    id_vars = oak_id_vars()
  ) %>%

  # === WALKTHROUGH: a collected date (assign_datetime) ====================
  # Start date collected as dd-MMM-yyyy -> ISO 8601 via assign_datetime.
  assign_datetime(
    raw_dat = cm_raw,
    raw_var = "IT.CMSTDAT",
    tgt_var = "CMSTDTC",
    raw_fmt = c("d-m-y"),
    raw_unk = c("UN", "UNK")
  ) %>%

  # === WALKTHROUGH: conditional constant (hardcode_ct + condition_add) ====
  # aCRF: "If Yes then CM.CMENRTPT = 'ONGOING'" (codelist C66728).
  hardcode_ct(
    raw_dat = condition_add(cm_raw, IT.CMONGO == "Yes"),
    raw_var = "IT.CMONGO",
    tgt_var = "CMENRTPT",
    ct_spec = study_ct,
    ct_clst = "C66728",
    tgt_val = "Ongoing",
    id_vars = oak_id_vars()
  ) %>%

  # --- EXERCISE 7: CMENTPT ------------------------------------------------
  # aCRF annotation: "CM.CMENTPT = 'DATE OF LAST ASSESSMENT'" when ongoing.
  # A hardcoded value with NO codelist -> hardcode_no_ct, guarded by the
  # same condition (IT.CMONGO == "Yes").
  # AI prompt:
  #   "When IT.CMONGO is 'Yes', hardcode CMENTPT to 'DATE OF LAST
  #    ASSESSMENT' using hardcode_no_ct wrapped in condition_add."
  hardcode_no_ct(
    raw_dat = condition_add(cm_raw, ??),
    raw_var = "IT.CMONGO",
    tgt_var = ??,
    tgt_val = ??,
    id_vars = oak_id_vars()
  ) %>%

  # --- EXERCISE 8: CMENDTC (end date) ------------------------------------
  # aCRF annotation: "CM.CMENDTC" - end date collected as dd-MMM-yyyy.
  # AI prompt:
  #   "Map CMENDTC from IT.CMENDAT using assign_datetime with raw_fmt
  #    'd-m-y', handling unknown tokens UN/UNK."
  assign_datetime(
    raw_dat = cm_raw,
    raw_var = ??,
    tgt_var = ??,
    raw_fmt = c("d-m-y"),
    raw_unk = c("UN", "UNK")
  ) %>%

  # === WALKTHROUGH: identifiers, derived vars & final ordering (provided) =
  dplyr::mutate(
    STUDYID = "test_study",
    DOMAIN = "CM",
    CMCAT = "GENERAL CONMED",
    USUBJID = paste0("test_study", "-", cm_raw$PATNUM)
  ) %>%
  derive_seq(tgt_var = "CMSEQ",
             rec_vars = c("USUBJID", "CMTRT")) %>%
  derive_study_day(
    sdtm_in = .,
    dm_domain = dm,
    tgdt = "CMENDTC",
    refdt = "RFXSTDTC",
    study_day_var = "CMENDY"
  ) %>%
  derive_study_day(
    sdtm_in = .,
    dm_domain = dm,
    tgdt = "CMSTDTC",
    refdt = "RFXSTDTC",
    study_day_var = "CMSTDY"
  ) %>%
  dplyr::select("STUDYID", "DOMAIN", "USUBJID", "CMSEQ", "CMTRT", "CMCAT", "CMINDC",
                "CMDOS", "CMDOSTXT", "CMDOSU", "CMDOSFRM", "CMDOSFRQ", "CMROUTE",
                "CMSTDTC", "CMENDTC", "CMSTDY", "CMENDY", "CMENRTPT", "CMENTPT")
