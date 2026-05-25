# Snowflake-Administration Contract

What this domain expects [Snowflake-Administration](https://github.com/Groset/Snowflake-Administration) to have provisioned before any script in this repo runs.

The canonical machine-readable list is in [`/snowflake.yml`](../../snowflake.yml). This file explains the *why*.

## Databases

| Environment | Database |
|-------------|----------|
| DEV | `DEV_<PRIMARY_DB>` |
| PRD | `PRD_<PRIMARY_DB>` |

Same name in either env apart from the prefix; the VSCode connection differs, the SQL files don't.

## Schemas

| Schema | Purpose |
|--------|---------|
| `<PRIMARY_SCHEMA>` | Primary schema for this domain's procedures, views, tables. |

<!-- Add additional schemas here if the domain uses more than one. -->

## Roles

These are **account-wide** roles owned by Snowflake-Administration. There are no per-domain roles to create. New databases need GRANTs to these existing roles.

| Role | Used by | Notes |
|------|---------|-------|
| `DAGSTER_DEV_ROLE` | Developers running scripts against DEV | Owns every DEV object. Devs run under this role so object ownership stays consistent across the team. |
| `DAGSTER_PRD_ROLE` | PRD deployments; production Dagster service account | **Deployment role.** Owns every PRD object. Used to roll changes out to production — both manual deployments and the production Dagster service account run under it. Ensures consistent ownership in PRD; avoids permission gaps when prod Dagster runs (everything is owned by this single role). |
| `BSL_DEFAULT_ROLE` | All developers | General read/dev role. Reads from PRD; reads and writes in DEV. Use for browsing and exploration. Switch to `DAGSTER_DEV_ROLE` when creating DEV objects you want the team to own. |
| `PC_DOMO_ROLE` | Domo integration service account | Reads from any database that publishes to Domo. Granted SELECT by the producing domain (see `grants/`). |

## Warehouse

`COMPUTE_WH` (or as configured in `snowflake.yml`).

## What's missing — open Snowflake-Administration PR

If the databases or schemas above don't exist (in either DEV or PRD), open a Snowflake-Administration PR with the per-domain SQL:

```sql
-- Add to Snowflake-Administration/Databases/<PRIMARY_DB>.sql

CREATE DATABASE IF NOT EXISTS DEV_<PRIMARY_DB>;
CREATE DATABASE IF NOT EXISTS PRD_<PRIMARY_DB>;

CREATE SCHEMA IF NOT EXISTS DEV_<PRIMARY_DB>.<PRIMARY_SCHEMA>;
CREATE SCHEMA IF NOT EXISTS PRD_<PRIMARY_DB>.<PRIMARY_SCHEMA>;

-- Ownership-line grants
GRANT ALL   ON DATABASE DEV_<PRIMARY_DB> TO ROLE DAGSTER_DEV_ROLE;
GRANT ALL   ON DATABASE DEV_<PRIMARY_DB> TO ROLE BSL_DEFAULT_ROLE;
GRANT ALL   ON DATABASE PRD_<PRIMARY_DB> TO ROLE DAGSTER_PRD_ROLE;

-- Read-from-PRD line
GRANT USAGE ON DATABASE PRD_<PRIMARY_DB> TO ROLE BSL_DEFAULT_ROLE;
GRANT USAGE ON SCHEMA   PRD_<PRIMARY_DB>.<PRIMARY_SCHEMA> TO ROLE BSL_DEFAULT_ROLE;

-- Per-schema grants follow the same pattern; see Snowflake-Administration/Databases/IL_Sales.sql for a worked example.
```
