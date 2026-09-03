---
name: sdtm-oak-mapping
description: Create SDTM domains from raw clinical data using sdtm.oak. Use when building or extending an SDTM domain (VS, DM, AE, CM, etc.) from a raw dataset plus an aCRF and controlled-terminology spec, or when asked to "map SDTM", "create the VS/DM domain", "write sdtm.oak code", or "automate SDTM mapping". Triggers on "sdtm.oak", "SDTM domain", "map SDTM", "aCRF mapping", "create VS domain", "create DM domain".
---

# SDTM mapping with sdtm.oak

Generate SDTM domain programs in R using `sdtm.oak`'s reusable mapping algorithms.
The domain is built by mapping one **topic** variable at a time, attaching its
**qualifiers**, then binding topics together and adding common qualifiers and
derived variables.

## When to use

Building an SDTM domain (Findings like VS/LB/EG, Interventions like CM/EX, Events
like AE/MH, or Special-purpose like DM) from:
- a **raw dataset** (e.g. `pharmaverseraw::vs_raw`),
- an **aCRF** (annotated CRF PDF) that names the target variables, and
- a **controlled-terminology spec** (`study_ct`, here `metadata/sdtm_ct.csv`).

## Inputs to gather first

1. **Raw dataset(s)** and their column names (`names(raw)`).
2. **aCRF** for the domain — lists target variables and their CT codelists.
   pharmaverse aCRFs: `https://github.com/pharmaverse/pharmaverseraw/tree/main/vignettes/articles/aCRFs`
3. **CT spec** — `read.csv("slides/02-SDTM/metadata/sdtm_ct.csv")`. Columns:
   `codelist_code, term_code, term_value, collected_value, term_preferred_term, term_synonyms`.
   The `codelist_code` (e.g. `C66741`) is what you pass as `ct_clst`.

## Workflow

1. **Read** the raw data and generate id vars:
   ```r
   raw <- pharmaverseraw::vs_raw |>
     generate_oak_id_vars(pat_var = "PATNUM", raw_src = "vitals")
   ```
2. **Read** the CT spec into `study_ct`.
3. For **each topic variable** (each test in Findings; the key collected item in
   Interventions/Events), start a pipe that hardcodes/assigns the topic, then
   `dplyr::filter(!is.na(<topic>))`, then map its qualifiers. Pick the algorithm
   per variable — see the decision table below.
4. **Bind** all topic frames with `dplyr::bind_rows()`.
5. Map **common qualifiers** (dates, visits, timepoints) on the bound frame.
6. Add **hardcoded attributes** (`STUDYID`, `DOMAIN`, `USUBJID`, category vars)
   and **derived** variables (`derive_seq`, `derive_study_day`, `derive_blfl`,
   unit conversions) with `mutate()`.
7. **Select** the final variable order.
8. **Run** the program and preview (`head()`, check a known subject).

## Choosing the algorithm

| Situation | Algorithm |
|---|---|
| Collected value, **no** CT | `assign_no_ct(raw_dat, raw_var, tgt_var, id_vars = oak_id_vars())` |
| Collected value, **with** CT | `assign_ct(raw_dat, raw_var, tgt_var, ct_spec = study_ct, ct_clst, id_vars = oak_id_vars())` |
| Hardcoded value, **with** CT | `hardcode_ct(raw_dat, raw_var, tgt_var, tgt_val, ct_spec = study_ct, ct_clst, id_vars = oak_id_vars())` |
| Hardcoded value, **no** CT | `hardcode_no_ct(raw_dat, raw_var, tgt_var, tgt_val, id_vars = oak_id_vars())` |
| Map **only when** a condition holds | wrap `raw_dat` in `condition_add(raw, <cond>)` |
| Date / time / datetime | `assign_datetime(raw_dat, raw_var, tgt_var, raw_fmt)` |
| DM reference dates (RFSTDTC …) | `oak_cal_ref_dates()` with a ref-date config tibble |

**The first algorithm in a topic pipe takes no `id_vars`** (it seeds the frame);
every subsequent qualifier mapping passes `id_vars = oak_id_vars()`.

## Conventions (this repo)

- Raw variable names often use the `IT.<NAME>` prefix (item-level); some are bare
  (`SYS_BP`, `PULSE`, `SUBPOS`). Use the exact raw column names.
- CT lives in `study_ct`; pass the codelist code as `ct_clst`.
- `USUBJID` here is `paste0("01-", PATNUM)`; `STUDYID` is `"CDISCPILOT01"` (VS) or
  `dm_raw$STUDY` (DM).
- Findings domains derive `VSSTRESC/VSSTRESN` (often via unit conversion),
  `VSSEQ` (`derive_seq`), `VSDY` (`derive_study_day`), `VSBLFL` (`derive_blfl`).

## Reference material

- `references/domain-patterns.md` — full annotated skeletons for a **Findings**
  domain (VS) and the **DM** special-purpose domain, including ref-date config and
  all common derivations. Read this when writing a new domain program.
- `references/algorithms.md` — every `sdtm.oak` algorithm with arguments and a
  worked example. Read this to confirm argument names/order for an algorithm.
- Working end-to-end examples in this repo:
  `slides/02-SDTM/scripts/create_vs_domain.R` (Findings) and
  `slides/02-SDTM/scripts/create_dm_domain.R` (special-purpose + reference dates).
  Copy the closest one as a starting point.

## Validate before finishing

- Program runs without error; print `head(domain)` and check subject `01-701-1015`.
- Every CT-restricted variable used a `*_ct` algorithm with the right `ct_clst`.
- Topic pipes filter `!is.na(<topic>)` before qualifier mapping.
- Final `select()` matches the domain's expected variable order.
- Generated code is a **starting point** — a human must verify CT correctness,
  edge cases, and traceability before it is submission-ready.
