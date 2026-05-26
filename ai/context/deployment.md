# Deployment Process

> **For Claude (or any coding agent)**: this file is an instruction script.
> When a user asks to "prepare a PRD deploy," "assemble the deployment,"
> "bundle the scripts for PRD," or similar — execute the steps in
> *PRD deploy assembly* below.

This file describes how source `.sql` files become deployable scripts in DEV and PRD. It's readable by humans (so a person can follow it manually if AI is unavailable), but its primary audience is an AI agent.

## Source-state assumption

All `.sql` files in `sql/` and `grants/` use **DEV-prefixed** Snowflake database names (`DEV_*`). This is enforced by CONVENTIONS.md and verified by the assembler. The source is the canonical state for DEV; the assembled `deploy-prd/` is the canonical state for PRD.

## DEV deploy (no assembly)

DEV deploys are run directly from source. No assembly needed:

1. Open the changed `.sql` file in VSCode.
2. Confirm the connection in the VSCode status bar is `DEV_<DOMAIN>` (role = `DAGSTER_DEV_ROLE`).
3. Click ▶ to execute.

Recommended manual run order when deploying multiple files: tables → functions → views → procedures → grants. The same order an assembled bundle uses.

## PRD deploy assembly

Triggered when a developer asks to prepare a PRD deploy. The agent produces a `deploy-prd/` tree of bundled scripts, one bundle per `(deploy_role, process_step)`, with `DEV_` substituted to `PRD_`.

### 1. Walk the source

Read every `.sql` file under `sql/` and `grants/`. Skip `.sqlfluffignore`d files (those are template placeholders, not real DDL).

### 2. Classify each file

Determine *kind* and *process_step* by content (override filename heuristic if they conflict):

| File contains | Kind | Process step |
|---|---|---|
| `CREATE OR REPLACE PROCEDURE` | procedure | definitions |
| `CREATE OR REPLACE FUNCTION` | function | definitions |
| `CREATE OR REPLACE VIEW` | view | definitions |
| `CREATE OR REPLACE TABLE` or `CREATE TABLE IF NOT EXISTS` | table | definitions |
| `INSERT INTO`, `MERGE INTO` (no CREATE) | seed | seed |
| `GRANT` statements | grant | grants |

Filename prefix (`SP_`, `UDF_`, `vw_`, `SEED_`) is a secondary hint — content wins.

### 3. Determine deploy role

Look for `-- Deploy role: <ROLE>` in the file header. If absent, default to `DAGSTER_PRD_ROLE` for `definitions` and `seed` steps; default to `DAGSTER_PRD_ROLE` for `grants` too unless the grants file declares a different role (some grants might need `SECURITYADMIN` or similar).

### 4. Validate

Before assembling, refuse to proceed if any of the following are true. Report all violations at once and stop.

- A source file contains `\bPRD_` in an identifier context (catches accidental hardcoded PRD references).
- A file is missing the required header (File / Object / Purpose).
- A filename doesn't match the object name declared in its `-- Object:` line.
- Two files declare the same object name (one-object-per-file violation).
- A `CREATE OR REPLACE TABLE` file matches a known historical table per `ai/context/` or `ai/features/` documentation (would drop production data — flag for explicit human confirmation).

### 5. Substitute `DEV_` → `PRD_`

Apply `\bDEV_` → `PRD_` only in identifier contexts. Skip:
- Comments (`-- ...` and `/* ... */`).
- String literals (`'...'`).
- Identifiers that happen to contain `DEV` but aren't database prefixes (defensive — should be rare).

A naive `s/\bDEV_/PRD_/g` over identifier tokens is the right level of cleverness. Don't try to be smart about it.

### 6. Order definitions

Within the `definitions` bundle for each role, files must be ordered so that referenced objects are created before their referrers. Algorithm:

1. Parse each file's CREATE statement to identify the object it creates.
2. Parse the body for references: `FROM <name>`, `JOIN <name>`, `CALL <name>(...)`, `<name>(...)` (function calls), `IDENTIFIER(...)` (treat unresolvable identifiers as soft dependencies — skip).
3. Build a dependency graph: edge from referrer → referenced.
4. Topologically sort.
5. If cycles exist (rare — usually self-references which are allowed), break by category in canonical order: tables → functions → views → procedures.

Cross-DB references (`DEV_<OTHER_DB>.x.y` in this domain referring to another domain's object) are out-of-graph — assume those exist already.

Seed and grants bundles have no dependency ordering — concatenate in filename-sort order for stability.

### 7. Bundle and write

For each `(role, process_step)` combination, write:

```
deploy-prd/<role>/01_definitions.sql
deploy-prd/<role>/02_seed.sql
deploy-prd/<role>/03_grants.sql
```

Skip a numbered file if that step is empty for that role.

Format of each bundle:

```sql
-- =====================================================================
-- DEFINITIONS bundle | role: DAGSTER_PRD_ROLE | generated: YYYY-MM-DD HH:MM
-- Source commit: <git rev-parse HEAD>
-- =====================================================================

-- --- sql/dev_il_finance/public/EXAMPLE_TABLE.sql ---
CREATE OR REPLACE TABLE PRD_IL_Finance.public.EXAMPLE_TABLE ( ... );

-- --- sql/dev_il_finance/public/UDF_EXAMPLE.sql ---
CREATE OR REPLACE FUNCTION PRD_IL_Finance.public.UDF_EXAMPLE(...) ...;

-- ... etc, in topologically-sorted order
```

Source-file provenance comments stay in the bundle so a deployer reading it can trace each chunk back to its source.

### 8. Write README per role

`deploy-prd/<role>/README.md` contents:

```markdown
# PRD deploy bundle — <role>

Generated: <timestamp>
Source commit: <hash>

## Steps

1. In VSCode, switch the Snowflake connection role to `<role>`.
2. Confirm the connection's default database is the env-correct one for this role.
3. Run the files in numerical order:
   - `01_definitions.sql`
   - `02_seed.sql` (if present)
   - `03_grants.sql` (if present)
4. Verify each step completes without errors before running the next.

## Contents

- N tables, N functions, N views, N procedures (definitions)
- N seed scripts
- N grants

## Anything unusual

<Notes from the assembler: ambiguous classifications, manual review needed,
files that had to be reordered for cycles, etc. Empty if everything was clean.>
```

### 9. Report to the developer

After writing the bundle, tell the developer:

- Path to the assembled output.
- File counts per (role, step).
- Any warnings: ambiguous classifications, files reordered, anything that needs review.
- Reminder to review the diff before running in PRD.

## Notes for the agent

- The output goes in `deploy-prd/` which is `.gitignore`d — it's a transient artifact, regenerated each deploy.
- Don't try to be "smart" about the substitution. Pure mechanical `DEV_` → `PRD_` is the contract. The assembler's job is bundling and substitution, not transformation.
- If something is ambiguous or wrong in the source, fail loudly and report — don't paper over it. The deployer needs to know.
- For DEV deploys, there's nothing to assemble. Tell the user to run source files directly.
