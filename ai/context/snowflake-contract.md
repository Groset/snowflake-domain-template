# Snowflake-Administration Contract

What this domain expects [Snowflake-Administration](https://github.com/Groset/Snowflake-Administration) to have provisioned before any script in this repo can run.

This is prose; the canonical machine-readable list is in [`/snowflake.yml`](../../snowflake.yml).

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

| Role | Used by | Required privileges |
|------|---------|---------------------|
| `<PRIMARY_DB>_WRITER` | Developers running scripts via VSCode | USAGE on database/schemas; CREATE TABLE/VIEW/PROCEDURE/FUNCTION; full DML on owned objects |
| `<PRIMARY_DB>_READER` | Downstream consumers | USAGE on database/schemas; SELECT on tables/views |

Roles are created and granted in Snowflake-Administration. This repo only
grants on objects it creates (see `grants/`).

## Warehouse

`WH_INTEGRATION` (or as configured in `snowflake.yml`).

## What's missing — open Snowflake-Administration PR

If any of the above is missing in DEV or PRD, open a Snowflake-Administration PR with:

```
Title: Provision <DOMAIN_NAME> domain
Body:
  Per snowflake-domain-template contract for <DOMAIN_NAME>:
  - CREATE DATABASE DEV_<PRIMARY_DB>, PRD_<PRIMARY_DB>
  - CREATE SCHEMA <PRIMARY_SCHEMA> in both
  - CREATE ROLE <PRIMARY_DB>_WRITER, <PRIMARY_DB>_READER
  - Grant USAGE on warehouse WH_INTEGRATION to both roles
  - Grant role hierarchy as per Snowflake-Administration conventions
```
