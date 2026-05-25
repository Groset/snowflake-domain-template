# Conventions

Naming, file-header, and review standards for this domain repo.

## Object naming

| Object type | Pattern | Example |
|-------------|---------|---------|
| Procedure | `SP_<VERB>_<NOUN>` | `SP_BUILD_CUSTOMER_360` |
| Function (UDF) | `UDF_<PURPOSE>` | `UDF_NORMALIZE_PHONE` |
| View | `V_<NOUN>` | `V_CUSTOMER_LATEST` |
| Table | ALLCAPS_SNAKE | `CUSTOMER_TRANSACTION` |
| Stage | `STG_<PURPOSE>` | `STG_CUSTOMER_LANDING` |
| Stream | `STR_<NOUN>` | `STR_CUSTOMER_CHANGES` |
| Task | `TSK_<VERB>_<NOUN>` | `TSK_REFRESH_CUSTOMER_360` |

All object names UPPER_SNAKE; all schema names lower-snake (matching the existing Groset convention).

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
- `tables/` — `CREATE TABLE IF NOT EXISTS`

Grants go in `grants/`, one file per logical grant set.

## DDL patterns

- **Procedures / functions / views**: always `CREATE OR REPLACE`. The file is the canonical definition.
- **Tables**: always `CREATE TABLE IF NOT EXISTS`. Never `CREATE OR REPLACE TABLE` in a production-bound file — it's destructive. Use `ALTER` ad-hoc for ongoing changes, then update the file to match.
- **Grants**: idempotent (`GRANT` is naturally idempotent in Snowflake) — safe to re-run.

## PR review checklist

A reviewer should be able to answer YES to all of these before approving:

- [ ] File names match object names; one object per file.
- [ ] Every file has a complete header comment.
- [ ] Stateless objects use `CREATE OR REPLACE`; tables use `CREATE TABLE IF NOT EXISTS`.
- [ ] No destructive operations slipped in (`DROP`, `TRUNCATE`, type narrowing) without explicit reviewer awareness.
- [ ] If a table's shape changed, the matching `tables/<name>.sql` file reflects the new shape.
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
