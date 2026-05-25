# CLAUDE.md — <DOMAIN_NAME>

## Project Overview

Per-domain Snowflake DDL repo for **<DOMAIN_NAME>**. Contains the procedures, functions, views, tables, and grants for one business domain. Part of a multi-repo Groset Snowflake architecture:

```
Snowflake-Administration   → databases, schemas, roles, warehouses, Domo integration
<this repo>                → this domain's procedures / views / tables / grants
<other domain repos>       → other domains, same shape
SF-Orchestration           → Dagster code location that calls SPs in this repo
```

This repo's scope ends at SQL DDL. There is **no automated deploy** — developers run scripts manually via the Snowflake VSCode extension. CI lints syntax only.

## Technology Stack

- Snowflake (procedures, functions, views, tables)
- Snowflake VSCode extension for execution
- sqlfluff (CI only) — SQL syntax/style lint
- Markdown for all documentation, including the AI-facing `ai/` folder

## Repo Layout

| Path | Purpose |
|------|---------|
| `snowflake.yml` | Contract with Snowflake-Administration — what must pre-exist |
| `contracts.yml` | Data contract — what this domain produces and consumes |
| `sql/<db>/<schema>/procedures/` | `CREATE OR REPLACE PROCEDURE` files |
| `sql/<db>/<schema>/functions/` | `CREATE OR REPLACE FUNCTION` files |
| `sql/<db>/<schema>/views/` | `CREATE OR REPLACE VIEW` files |
| `sql/<db>/<schema>/tables/` | `CREATE OR REPLACE TABLE` files (or `CREATE TABLE IF NOT EXISTS` for historical / non-rebuildable tables — see CONVENTIONS.md) |
| `grants/` | Grants on objects this repo owns |
| `ai/agents/` | Subagent role prompts (tune per-domain) |
| `ai/context/` | Long-lived reference material |
| `ai/features/` | Numbered feature directories |
| `ai/session/` | Ad-hoc scripts and reports |

## Naming Conventions

- Procedures: `SP_<VERB>_<NOUN>` — `SP_BUILD_CUSTOMER_360`
- Functions: `UDF_<PURPOSE>` — `UDF_NORMALIZE_PHONE`
- Views: `vw_<noun>` — `vw_customer_latest` (lowercase in source; Snowflake folds it to `VW_CUSTOMER_LATEST` in storage — do **not** use quoted identifiers)
- Tables: ALLCAPS_SNAKE — `CUSTOMER_TRANSACTION`
- File name matches object name: `SP_BUILD_CUSTOMER_360.sql`

See `CONVENTIONS.md` for the full set.

## Deployment Model

**No automated deploy.** Developers run `.sql` files from VSCode against a chosen Snowflake connection.

- **Stateless objects** (procedures, functions, views): `CREATE OR REPLACE` every run. The file is the canonical definition; git history *is* the version history.
- **Tables (default)**: `CREATE OR REPLACE TABLE`. Same model as procedures/views — the file is canonical shape. Safe because almost every table in this repo is rebuilt by a `CREATE OR REPLACE` / `INSERT OVERWRITE` bulk process.
- **Tables (historical exception)**: a small number of tables hold data that can't be reconstructed (long-lived history, manually-curated rows). These use `CREATE TABLE IF NOT EXISTS` and must be documented in `ai/context/` or an `ai/features/` entry. See CONVENTIONS.md *Historical / non-rebuildable tables* for the full rule.
- **Grants**: deployed last; this repo only grants on objects it owns.
- **Folder == connection**: each `sql/<db>/` folder corresponds to a VSCode Snowflake connection whose default database is `<db>`. Object definitions inside use `<schema>.NAME` (no DB prefix) — the session supplies the database. The same file deploys to DEV and PRD by switching connection. See CONVENTIONS.md *DB qualification in object bodies* for the full rule.

### Recommended manual run order

```
tables → functions → views → procedures → grants
```

## Working with this repo

### Day-to-day

1. Open the `.sql` file you're editing.
2. **Confirm the connection in the VSCode status bar matches your target** (`DEV_<DOMAIN>` for development, `PRD_<DOMAIN>` for production).
3. Run the file: ▶ button or "Snowflake: Execute All Statements".
4. Verify result in the Snowsight output panel.

### Connections

Set up Snowflake VSCode extension connections like this:

| Connection | Role | Database | Who uses it |
|------------|------|----------|-------------|
| `DEV_<DOMAIN>` | `DAGSTER_DEV_ROLE` | `DEV_<PRIMARY_DB>` | Every developer running scripts in DEV |
| `PRD_<DOMAIN>` | `DAGSTER_PRD_ROLE` | `PRD_<PRIMARY_DB>` | **Deployment** — used to roll changes out to production |

Why `DAGSTER_DEV_ROLE` and not your personal role for DEV: objects you create are owned by the role you ran under. Using `DAGSTER_DEV_ROLE` means every DEV object is owned by the same role, so any developer on the team can modify any object without permission errors.

`BSL_DEFAULT_ROLE` is your general "browsing" role — it can read from PRD and read/write in DEV. Use it for exploring; switch to `DAGSTER_DEV_ROLE` when creating objects you want the team to own.

Switch the connection via the status bar **before** running anything.

### PR → DEV → PRD flow

1. Feature branch + PR → review → merge to main.
2. After merge: connect to DEV (`DAGSTER_DEV_ROLE`), run all changed files in the recommended order.
3. PRD deployment: changes are rolled out either by running the scripts under `DAGSTER_PRD_ROLE`, or by the production Dagster instance picking the change up on its next scheduled run (when applicable). PRD deployment is treated as a release step, distinct from day-to-day development.

CI only lints SQL syntax. It does not deploy.

## Working with Claude in this repo

This repo follows the Groset `ai/` convention.

- **Reference material**: read `ai/context/` first. Summary files (`*-summary.md`) are authoritative; raw files are for drill-down.
- **Significant changes**: copy `ai/features/_template/` to a new numbered directory (e.g. `ai/features/03-add-loyalty-segment/`) and fill in `planning.md` *before* touching SQL.
- **Reviewer perspectives**: invoke the `Plan` subagent with role prompts from `ai/agents/agent-definitions.md` for SQL review, safety checks, and contract validation.
- **Ad-hoc work**: drop one-off scripts and validation reports in `ai/session/`. Date-tag the filename.

## Contracts

### With Snowflake-Administration

These must pre-exist before any script in this repo runs. Request via a Snowflake-Administration PR if missing:

- Databases: `DEV_<PRIMARY_DB>` and `PRD_<PRIMARY_DB>`
- Schemas: as listed in `snowflake.yml`
- Grants on the new databases/schemas to `DAGSTER_DEV_ROLE`, `DAGSTER_PRD_ROLE`, and `BSL_DEFAULT_ROLE` (the account-wide roles already exist — no per-domain roles are created)
- Warehouse: as configured in `snowflake.yml`

### With consumers (data contract)

`contracts.yml` declares what this domain produces and consumes. **Update it in the same PR as any change that affects the contract** — column additions/removals, type changes, new tables, deprecated objects.

The aggregator in `Snowflake-Administration/contracts/` reads every domain's `contracts.yml` and produces a cross-repo index. Drift is detected by comparing claims against `INFORMATION_SCHEMA`.

## First Steps (new domain checklist)

Do these in order. Each step is small and verifiable.

### 1. Personalize the template
Ask Claude (or any AI coding agent) to **"follow `INIT.md`"**. It will propose smart defaults from the folder/git context, confirm three values with you (domain name, primary database, primary schema), substitute placeholders across every template file, and delete `INIT.md` when done.

If you don't have an agent available, `INIT.md` is human-readable — do the same substitutions by hand.

### 2. Confirm Snowflake-Administration has provisioned your domain
DB, schemas, and roles must exist in DEV **and** PRD. See `snowflake.yml` for the full list. Open a Snowflake-Administration PR if anything is missing.

### 3. Set up VSCode Snowflake connections
Two named connections (`DEV_<DOMAIN>`, `PRD_<DOMAIN>`) — see **Connections** above.

### 4. Bring in existing objects (one schema at a time)
For each existing SP / view / function / table this domain owns:
1. Capture current DDL from Snowflake:
   ```sql
   SELECT GET_DDL('PROCEDURE', '<PRIMARY_DB>.<SCHEMA>.SP_NAME(<args>)');
   SELECT GET_DDL('TABLE',     '<PRIMARY_DB>.<SCHEMA>.<TABLE>');
   ```
2. Save into the correct `sql/<schema>/<category>/` folder.
3. Delete the example `*_EXAMPLE.sql` placeholder files once your own files are in place.
4. Run each file against DEV via VSCode. Verify in Snowsight.

### 5. Populate `contracts.yml`
List every object this domain **produces** that's consumed externally, and every object it **consumes** from upstream sources. Column-level. See the file's inline comments.

### 6. Populate `ai/context/`
- `upstream.md` — prose commentary on upstream dependencies (the structured list lives in `contracts.yml`)
- `downstream.md` — prose commentary on downstream consumers
- `snowflake-contract.md` — what this repo expects Snowflake-Administration to provision
- `target-layout.md` — schemas, naming, run order for this domain

### 7. Open the first real PR
A small change end-to-end: PR → review → merge → DEV deploy → PRD deploy. Confirms the human workflow before any larger work.

## Adding a New Object

- **Procedure / function / view**: drop the `.sql` file in the right folder, run it via VSCode.
- **New table (default)**: drop a `CREATE OR REPLACE TABLE` file in `tables/`, run it.
- **New table (historical / non-rebuildable)**: use `CREATE TABLE IF NOT EXISTS`, add `-- Population: historical — do not re-run in PRD` to the header, and document the table in `ai/context/` or an `ai/features/` entry. See CONVENTIONS.md.
- **Existing table needs a column**:
  - *Rebuildable table*: edit the `.sql` file and re-run it (the `CREATE OR REPLACE` is non-destructive in this case because the table is rebuilt anyway).
  - *Historical table*: run the `ALTER` directly via VSCode, then update the table's `.sql` file to match in the same PR.

## When to Ask Before Acting

- **Any PRD deploy** — always coordinate with the other dev.
- **Always confirm the VSCode Snowflake connection before clicking ▶.** A misclicked PRD connection is the biggest risk in this repo.
- **Destructive migrations**: `DROP COLUMN`, `DROP TABLE`, type narrowing, anything that loses data.
- **`CREATE OR REPLACE TABLE` against a historical table** — this drops all data. The SQL reviewer agent should already flag this; double-check before clicking ▶ on PRD.
- **Backfills**: run them in a controlled session, not as part of a multi-file batch.
- **Contract-breaking changes**: removing a produced column, renaming an object — these affect downstream consumers. Surface the impact via `contracts.yml` before merging.

## Definition of Done (for any task in this repo)

- [ ] All changed SQL files run cleanly against DEV.
- [ ] `sqlfluff lint sql/` passes (CI will check).
- [ ] If `contracts.yml` changed, the change is reviewed.
- [ ] The matching `tables/<name>.sql` file reflects the current shape (canonical for rebuildable tables; updated alongside ad-hoc `ALTER` for historical tables).
- [ ] If upstream/downstream relationships changed, `ai/context/upstream.md` or `downstream.md` is updated.
- [ ] PR description links any cross-repo PRs (Snowflake-Administration grants, SF-Orchestration parsers).

## Environment Variables

```
ENVIRONMENT              # DEV or PRD (informational only — VSCode connection drives execution)
SNOWFLAKE_INSTANCE
SNOWFLAKE_USER
SNOWFLAKE_PASSWORD
SNOWFLAKE_ROLE
SNOWFLAKE_WAREHOUSE
SNOWFLAKE_DATABASE_DEFAULT
{USER}_CERT              # optional — takes precedence over password if set
```
