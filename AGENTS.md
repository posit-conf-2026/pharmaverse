# pharmaverse workshop

Quarto website + revealjs decks for the "AI-Powered Clinical Reporting in R
with the Pharmaverse" workshop at posit::conf(2026). Rendered output goes to
`docs/`, which is gitignored and published to `gh-pages` by CI — never
hand-edit or commit it.

Decks live in `slides/<NN-topic>/`. Each deck's `index.qmd` carries the
`format: revealjs` front matter and pulls content in via `{{< include >}}`;
included `.qmd` files have no front matter of their own. To live-preview with
reload-on-save, target the deck's `index.qmd`, not an included file.

## R style

- Tidyverse first — dplyr/tidyr/stringr/lubridate. No data.table.
- Native pipe `|>` for new code. Keep `%>%` where a file already uses it
  (`slides/03-ADaM/`, and the existing `slides/*/scripts/*.R`) — don't mix
  the two within one file.
- `<-` for assignment, never `=` or `->`.
- Two-space indent; keep code lines under ~80 characters.
- `snake_case` for R objects; UPPERCASE for CDISC variables (`SAFFL`,
  `AEDECOD`, `TRTSDTM`).
- Namespace explicitly (`dplyr::filter()`, `cards::ard_tabulate()`) even when
  the package is attached — this repo does so deliberately, so a participant
  reading one slide knows where a function came from.
- Multi-line calls: one named argument per line, trailing comma, closing
  paren on its own line.
- Spaces around operators: `SAFFL == "Y"`, not `SAFFL=="Y"`.

## Data and packages

- Data comes from the pharmaverse packages — `pharmaverseadam::adsl`,
  `pharmaverseadam::adae`, `pharmaversesdtm::`, `pharmaverseraw::` — not from
  local files.
- Dummy data in teaching examples uses the pilot-study `USUBJID` format
  `"01-701-10XX"` (e.g. `"01-701-1015"`), never `"P01"` or bare numbers.
- Packages are managed by `renv` (`renv.lock`, R 4.6.1). Adding a package
  means `renv::snapshot()` *and* adding it to `install.R`, which provisions
  the Posit Cloud workspace where `.Rprofile` skips renv activation.
- `{rtables}` is not used for building tables here; it appears only in the
  package-landscape slide (`slides/05-tables-gtsummary/01-background.qmd`).

## Exercises

Participant scripts are `exercises/<NN-topic>.R`, named to match the deck
directory exactly (`exercises/04-ARD.R` ↔ `slides/04-ARD/`). Solutions are
`exercises/answers/<NN-topic>-answer.R` and are identical to the exercise
except the blanks are filled in.

Blanks are empty named arguments so the skeleton still parses:

    ard_stack_hierarchical(
      data = ,
      variables = ,
    )

Tasks are lettered `# A.`, `# B. [*BONUS*]`, with `# HINT:` comments that
become "We used ..." in the answer. Adding or renaming an exercise means
editing **three** places: the exercise, the answer, and both the `# Exercises`
and `# Solutions` sections of `exercises/exercises.qmd`.

## Skills

Detailed, task-specific procedures live in `.agents/skills/` — one folder per
skill, folder name matching the `name:` frontmatter. Consult the relevant one
before writing pharmaverse code: `sdtm-oak-mapping`, `admiral-adam`,
`ard-creation`, `gtsummary-tables`, `tfrmt`, `cards-to-tfrmt`,
`tfrmt-ae-table`, `docorator`. See `.agents/README.md` for the conventions.

`slides/05-tables-gtsummary/08-coding-agents.qmd` reads
`.agents/skills/gtsummary-tables/SKILL.md` at render time — renaming or
deleting that file breaks the site build.
