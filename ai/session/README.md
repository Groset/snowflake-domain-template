# Session

Ad-hoc working files: one-off generation scripts, validation reports, exploratory queries, setup notes.

## What goes here

- **Generator scripts** that produce content for `ai/context/` (e.g. a script that pulls `INFORMATION_SCHEMA` into a table inventory markdown).
- **Validation reports** (e.g. DEV-vs-PRD comparison output, drift checks).
- **Setup notes** captured during onboarding or troubleshooting.
- **Exploratory SQL** that isn't yet a deployable artifact.

## What does not go here

- Anything that should be deployed → `sql/`.
- Anything that's a stable cross-domain contract → `contracts.yml`.
- Anything that's durable reference material → `ai/context/`.
- Anything that's part of a planned feature → `ai/features/NN-name/`.

## Convention

- Date-tag filenames where helpful: `2026-05-25-prd-drift-check.md`.
- Keep generator scripts re-runnable (no hardcoded passwords, no machine-specific paths).
- It's fine for files here to be ephemeral and deleted later — don't treat this folder as historical record. Use `ai/features/` for that.
