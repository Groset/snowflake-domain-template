# Conventions

Naming, file-header, and review standards for this domain repo.

This document is also the **AI authoring guide**: an AI agent writing or reviewing SQL in this repo should follow these rules without exception. The same conventions that make AI-generated deploy bundles correct (clean headers, consistent naming, one object per file) make AI-authored code correct.

## Source files are DEV-hardcoded

Every database reference in a `.sql` file in this repo points at DEV. Files run as-is against DEV via VSCode; for PRD, AI assembles a separate deploy bundle (see `ai/context/deployment.md`) that substitutes `DEV_` → `PRD_` and reorganizes by deploy role.

In practice:

```sql
-- ✓ Correct
CREATE OR REPLACE TABLE DEV_IL_Finance.public.EXAMPLE_TABLE ( ... );
SELECT * FROM DEV_RL_Sage.public.transactions;

-- ✗ Wrong — implicit DB
CREATE OR REPLACE TABLE public.EXAMPLE_TABLE ( ... );

-- ✗ Wrong — hardcoded PRD (will fail the deploy assembler's safety check)
CREATE OR REPLACE TABLE PRD_IL_Finance.public.EXAMPLE_TABLE ( ... );
```

The file is the source of truth for DEV. The assembled `deploy-prd/` bundle is the source of truth for PRD.

## Object naming

| Object type | Pattern | Example |
|-------------|---------|---------|
| Procedure | `SP_<VERB>_<NOUN>` | `SP_BUILD_CUSTOMER_360` |
| Function (UDF) | `UDF_<PURPOSE>` | `UDF_NORMALIZE_PHONE` |
| View | `vw_<noun>` | `vw_customer_latest` |
| Table | ALLCAPS_SNAKE | `CUSTOMER_TRANSACTION` |
| Seed-data script | `SEED_<NOUN>` | `SEED_REGIONS` |
| Stage | `STG_<PURPOSE>` | `STG_CUSTOMER_LANDING` |
| Stream | `STR_<NOUN>` | `STR_CUSTOMER_CHANGES` |
| Task | `TSK_<VERB>_<NOUN>` | `TSK_REFRESH_CUSTOMER_360` |

All object names UPPER_SNAKE **except views**, which are written `vw_<noun>` in lower-snake in source code. All schema names lower-snake (matching the existing Groset convention).

> **Note on views:** the lowercase form is a *source-code* convention only. Snowflake folds unquoted identifiers to uppercase at parse time, so `CREATE OR REPLACE VIEW vw_customer_latest …` is stored as `VW_CUSTOMER_LATEST` in the catalog and that's how it appears in `INFORMATION_SCHEMA`, `SHOW VIEWS`, Snowsight, and error messages. **Do not use quoted identifiers (`"vw_customer_latest"`) to force a lowercase stored name** — that makes every downstream reference case-sensitive. Write the view definition in lowercase in the file, let Snowflake uppercase it, and query it however you like.

## File names

The file name **must match the object name** with a `.sql` extension:

- `SP_BUILD_CUSTOMER_360.sql` defines `SP_BUILD_CUSTOMER_360`.
- One object per file. This matters more than ever — the deploy assembler classifies and orders files individually, so combining objects in one file breaks dependency detection.

## File header

Every `.sql` file starts with a header comment. The assembler relies on this header — keep it accurate:

```sql
-- File: SP_BUILD_CUSTOMER_360.sql
-- Object: DEV_<PRIMARY_DB>.<schema>.SP_BUILD_CUSTOMER_360
-- Purpose: <one line — what this does, not how>
-- Returns: <shape, e.g. "VARIANT JSON with keys: status, rows, duration_s">
-- Called by: <orchestration asset name, downstream SP name, or "manual">
-- Deploy role: DAGSTER_PRD_ROLE     (optional — this is the default)
```

The `-- Object:` line uses the fully-qualified DEV form (matches the CREATE statement below). The optional `-- Deploy role:` line lets a file declare a non-default deploy role.

## Folder placement

Required structure: `sql/<db>/<schema>/...`

- `<db>` — the env-prefixed Snowflake database name, lowercase folder (e.g. `dev_il_finance/`).
- `<schema>` — the schema name, lowercase (e.g. `public/`).
- Below schema: **organize however suits the domain.** Flat, by feature, by purpose, by category — the template doesn't prescribe. The deploy assembler infers object kind from the filename prefix (`SP_`, `UDF_`, `vw_`, `SEED_`, otherwise table) and from the CREATE statement, not from folder name.

Grants go in `grants/` at the repo root — one file per logical grant set. They're a separate deploy-role concern (often deployed under a different role than the DDL).

If this domain also owns objects in a secondary database (e.g. a schema inside `PL_DOMO`), add `sql/dev_pl_domo/<schema>/...` as a parallel tree.

## DDL patterns

- **Procedures / functions / views**: always `CREATE OR REPLACE`. The file is the canonical definition.
- **Tables (default)**: `CREATE OR REPLACE TABLE`. The file is the canonical shape. Safe because almost every table in this repo is rebuilt by a `CREATE OR REPLACE` / `INSERT OVERWRITE` bulk process.
- **Tables (historical exception)**: `CREATE TABLE IF NOT EXISTS`. See below.
- **Seed data**: prefer idempotent `MERGE INTO` over blind `INSERT`. Seed scripts re-run on every deploy.
- **Grants**: idempotent (`GRANT` is naturally idempotent in Snowflake) — safe to re-run.

### Historical / non-rebuildable tables

A small number of tables hold data that **cannot be reconstructed from source** — long-lived historical records, snapshot accumulations, manually-curated rows, anything where re-running the file would lose data.

Rules for these tables:

1. Use `CREATE TABLE IF NOT EXISTS`, not `CREATE OR REPLACE TABLE`.
2. Document the table's population pattern in either `ai/context/` or the relevant `ai/features/NN-…/planning.md`. State explicitly that the table is not rebuildable and why.
3. Add a header line in the `.sql` file: `-- Population: historical — do not re-run in PRD`.
4. Column changes are still applied via ad-hoc `ALTER` in VSCode; the `.sql` file is updated in the same PR to reflect current shape.

The SQL reviewer agent (see `ai/agents/agent-definitions.md`) is responsible for catching tables that should be in this category but aren't.

## Deployment

- **DEV**: developer runs source files directly via VSCode connected to `DEV_<DOMAIN>`. No assembly. Recommended manual run order: tables → functions → views → procedures → grants.
- **PRD**: AI agent assembles `deploy-prd/<role>/...` from source, substituting `DEV_` → `PRD_` and bundling by `(role, process_step)`. Deployer then runs the bundled files in PRD. Full process in [`ai/context/deployment.md`](ai/context/deployment.md).

## PR review checklist

A reviewer (human or AI) should be able to answer YES to all of these before approving:

- [ ] Every database reference in source files is `DEV_*`. No `PRD_*`, no implicit-DB forms.
- [ ] File names match object names; one object per file.
- [ ] Every file has a complete header comment (File / Object / Purpose / Returns / Called by).
- [ ] Stateless objects (SPs, UDFs, views) use `CREATE OR REPLACE`.
- [ ] Tables use `CREATE OR REPLACE TABLE` unless the table is historical / non-rebuildable, in which case `CREATE TABLE IF NOT EXISTS` is used and the exception is documented in `ai/context/` or an `ai/features/` entry.
- [ ] No destructive operations slipped in (`DROP`, `TRUNCATE`, type narrowing) without explicit reviewer awareness.
- [ ] Seed-data scripts use idempotent `MERGE` or guarded inserts, not bare `INSERT`.
- [ ] If an SP's output shape changed, the producer flagged it and the corresponding `contracts.yml` entry is updated.
- [ ] If new external dependencies were introduced, `contracts.yml` `consumes:` is updated.
- [ ] If new outputs were exposed, `contracts.yml` `produces:` is updated.
- [ ] Grants only touch objects this repo owns.
- [ ] `sqlfluff lint sql/ grants/` passes (CI confirms).

## When the SP output changes

If a procedure's output JSON / text format changes, **even by adding a key**:

1. Flag it explicitly in the PR description.
2. Update the corresponding entry in `contracts.yml` `produces:`.
3. Notify maintainers of any consumer that parses this output (typically SF-Orchestration's asset metadata extractor).

The `contract_level` field in `contracts.yml` indicates how stable a consumer can assume the shape is:

- `stable` — column additions allowed; renames / removals / type changes require coordination.
- `evolving` — shape may change in any minor way; consumers should expect to update.
- `experimental` — anything can change; consumers depend at their own risk.
