# `.agents/` — shared agent skills

This folder holds **agent skills** used across the workshop. Each workshop
section (SDTM, ADaM, ARD, tables, …) contributes its skills here so there is
one place to look and one convention to follow.

## Layout

```
.agents/
└─ skills/
   ├─ sdtm-oak-mapping/          # one folder per skill
   │  ├─ SKILL.md                #   entry point (required)
   │  └─ references/             #   optional supporting files
   │     ├─ algorithms.md
   │     └─ domain-patterns.md
   └─ <your-skill>/
      └─ SKILL.md
```

- One folder per skill, named in `kebab-case`.
- The folder name **must match** the `name` field in its `SKILL.md`.
- Put supporting material (worked examples, reference tables, catalogs) in
  subfolders next to `SKILL.md`; the agent loads them only when needed.

## `SKILL.md` requirements

Every `SKILL.md` **must start with YAML frontmatter** containing two required
fields:

```markdown
---
name: sdtm-oak-mapping
description: Create SDTM domains from raw clinical data using sdtm.oak. Use
  when building or extending an SDTM domain from a raw dataset plus an aCRF and
  CT spec. Triggers on "sdtm.oak", "SDTM domain", "map SDTM", "aCRF mapping".
---

# Human-readable title

Body: when to use, inputs to gather, the workflow, conventions, and how to
validate the result.
```

- **`name`** — the skill identifier; matches the folder name.
- **`description`** — *when to use it*. This is the trigger the agent matches
  against, so write it as concrete situations and phrases, not a summary.

## Guidelines

- **Keep skills short.** A skill is loaded into the prompt — longer skill =
  more tokens = higher cost and slower, and the signal gets diluted. Point to
  reference files instead of pasting them.
- **One responsibility per skill.** Split unrelated tasks into separate skills.
- **Reference real code.** Link to worked examples in the repo rather than
  duplicating them.
- **Retrieve, don't embed.** A skill is a map to the knowledge, not a copy.

## Adding a skill (for other sections)

1. Create `.agents/skills/<your-skill>/SKILL.md` with the required frontmatter.
2. Add any reference files beside it.
3. Confirm the folder name matches the `name` field.
4. Keep it lean; verify an agent can follow it end to end.
