# Conventions

Naming, file-header, and review standards for this domain repo.

## Object naming

| Object type | Pattern | Example |
|-------------|---------|---------|
| Procedure | `SP_<VERB>_<NOUN>` | `SP_BUILD_CUSTOMER_360` |
| Function (UDF) | `UDF_<PURPOSE>` | `UDF_NORMALIZE_PHONE` |
| View | `vw_<noun>` | `vw_customer_latest` |
| Table | ALLCAPS_SNAKE | `CUSTOMER_TRANSACTION` |
| Stage | `STG_<PURPOSE>` | `STG_CUSTOMER_LANDING` |
| Stream | `STR_<NOUN>` | `STR_CUSTOMER_CHANGES` |
| Task | `TSK_<VERB>_<NOUN>` | `TSK_REFRESH_CUSTOMER_360` |

All object names UPPER_SNAKE **except views**, which are written `vw_<noun>` in lower-snake in source code. All schema names lower-snake (matching the existing Groset convention).

> **Note on views:** the lowercase form is a *source-code* convention only. Snowflake folds unquoted identifiers to uppercase at parse time, so `CREATE OR REPLACE VIEW vw_customer_latest …` is stored as `VW_CUSTOMER_LATEST` in the catalog and that's how it appears in `INFORMATION_SCHEMA`, `SHOW VIEWS`, Snowsight, and error messages. **Do not use quoted identifiers (`"vw_customer_latest"`) to force a lowercase stored name** — that makes every downstream reference case-sensitive. Write the view definition in lowercase in the file, let Snowflake uppercase it, and query it however you like.

## File names

The file name **must match the object name** with a `.sql` extension:

- `SP_BUILD_CUSTOMER_360.sql` defines `SP_BUILD_CUSTOMER_360`.
- One object per file.

## File header

Every `.sql` file starts with a header comment:

```sql
-- File: SP_BUILD_CUSTOMER_360.sql
-- Object: <PRIMARY_DB>.<SCHEMA>.SP_BUILD_CUSTOMER_360
-- Purpose: <one line — what this does, not how>
-- Returns: <shape, e.g. "VARIANT JSON with keys: status, rows, duration_s">
-- Called by: <orchestration asset name, downstream SP name, or "manual">
```

The header is the first thing a reviewer reads. Keep it accurate.

## Folder placement

Object goes in `sql/<schema>/<category>/`:

- `procedures/` — `CREATE OR REPLACE PROCEDURE`
- `functions/` — `CREATE OR REPLACE FUNCTION`
- `views/` — `CREATE OR REPLACE VIEW`
- `tables/` — `CREATE OR REPLACE TABLE` (default). See *Historical / non-rebuildable tables* below for the exception.

Grants go in `grants/`, one file per logical grant set.

## DDL patterns

- **Procedures / functions / views**: always `CREATE OR REPLACE`. The file is the canonical definition.
- **Tables (default)**: `CREATE OR REPLACE TABLE`. The file is the canonical shape — same model as procedures and views. Safe because almost every table in this repo is rebuilt by a `CREATE OR REPLACE` / `INSERT OVERWRITE` bulk process.
- **Tables (historical exception)**: `CREATE TABLE IF NOT EXISTS`. See below.
- **Grants**: idempotent (`GRANT` is naturally idempotent in Snowflake) — safe to re-run.

### Historical / non-rebuildable tables

A small number of tables hold data that **cannot be reconstructed from source** — long-lived historical records, snapshot accumulations, manually-curated rows, anything where re-running the file in PRD would lose data.

Rules for these tables:

1. Use `CREATE TABLE IF NOT EXISTS`, not `CREATE OR REPLACE TABLE`.
2. Document the table's population pattern in either `ai/context/` or the relevant `ai/features/NN-…/planning.md`. State explicitly that the table is not rebuildable and why.
3. Add a header line in the `.sql` file: `-- Population: historical — do not re-run in PRD`.
4. Column changes are still applied via ad-hoc `ALTER` in VSCode; the `.sql` file is updated in the same PR to reflect current shape.

The SQL reviewer agent (see `ai/agents/agent-definitions.md`) is responsible for catching tables that should be in this category but aren't — see the *safety-reviewer* role for the detection logic.

## PR review checklist

A reviewer should be able to answer YES to all of these before approving:

- [ ] File names match object names; one object per file.
- [ ] Every file has a complete header comment.
- [ ] Stateless objects (SPs, UDFs, views) use `CREATE OR REPLACE`.
- [ ] Tables use `CREATE OR REPLACE TABLE` unless the table is historical / non-rebuildable, in which case `CREATE TABLE IF NOT EXISTS` is used and the exception is documented in `ai/context/` or an `ai/features/` entry.
- [ ] No destructive operations slipped in (`DROP`, `TRUNCATE`, type narrowing) without explicit reviewer awareness.
- [ ] No `CREATE OR REPLACE TABLE` is being deployed to PRD against a table that's incrementally populated and has no rebuild process — that would drop production data.
- [ ] The matching `tables/<name>.sql` file reflects the current shape.
- [ ] If an SP's output shape changed, the producer flagged it and the corresponding `contracts.yml` entry is updated.
- [ ] If new external dependencies were introduced, `contracts.yml` `consumes:` is updated.
- [ ] If new outputs were exposed, `contracts.yml` `produces:` is updated.
- [ ] Grants only touch objects this repo owns.
- [ ] `sqlfluff lint sql/` passes (CI confirms).

## When the SP output changes

If a procedure's output JSON / text format changes, **even by adding a key**:

1. Flag it explicitly in the PR description.
2. Update the corresponding entry in `contracts.yml` `produces:`.
3. Notify maintainers of any consumer that parses this output (typically SF-Orchestration's asset metadata extractor).

The `contract_level` field in `contracts.yml` indicates how stable a consumer can assume the shape is:

- `stable` — column additions allowed; renames / removals / type changes require coordination.
- `evolving` — shape may change in any minor way; consumers should expect to update.
- `experimental` — anything can change; consumers depend at their own risk.
