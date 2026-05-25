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

Object goes in `sql/<db>/<schema>/<category>/`:

- `procedures/` — `CREATE OR REPLACE PROCEDURE`
- `functions/` — `CREATE OR REPLACE FUNCTION`
- `views/` — `CREATE OR REPLACE VIEW`
- `tables/` — `CREATE OR REPLACE TABLE` (default). See *Historical / non-rebuildable tables* below for the exception.

The `<db>` folder is the **un-prefixed** database name (e.g. `il_customers`, not `DEV_IL_Customers`). Folder names lowercase. Each `<db>` folder corresponds to a VSCode Snowflake connection whose default database is that DB — for the primary DB you'll have one DEV and one PRD connection (`DEV_<DOMAIN>`, `PRD_<DOMAIN>`); for any secondary DBs (e.g. `pl_domo/`) you'll set up additional connections.

Grants go in `grants/`, one file per logical grant set.

## DB qualification in object bodies

Object definitions and grants in this repo are **environment-portable**: the same file deploys to both DEV and PRD unmodified. Environment is supplied by the VSCode connection (role + default DB), not by tokens in the file.

To preserve that property:

- **Inside a CREATE/GRANT statement that targets the session's default DB**: use `<schema>.NAME` only. No DB qualifier. Examples:
  ```sql
  CREATE OR REPLACE TABLE public.example_table (...);
  GRANT USAGE ON SCHEMA public TO ROLE BSL_DEFAULT_ROLE;
  ```
- **Inside a CREATE/GRANT statement that targets a different DB than the session default** (rare — would only happen if a procedure body writes cross-DB): fully qualify, `<OTHER_DB>.<schema>.NAME`. Treat this as a smell — usually the file should live in `sql/<other_db>/` instead, so the session naturally defaults to that DB.
- **Reads or references inside a procedure body**:
  - Same DB as the session → `<schema>.NAME` (or unqualified for the default schema).
  - Different DB (cross-DB consume, e.g. reading from `RL_FINANCE`) → fully qualified `<OTHER_DB>.<schema>.NAME`. This is the one place env-awareness leaks into file bodies — env-prefixed source DBs need a substitution mechanism. For now, write the name as it should appear at runtime in the target environment and flag the file as env-specific. We'll formalize a pattern when the first cross-DB consume lands.
- **`-- Object:` header**: keep the fully-qualified `<PRIMARY_DB>.<PRIMARY_SCHEMA>.NAME` form. The header is documentation — a reviewer wants the canonical address at a glance, not the implicit form that depends on session state.

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
