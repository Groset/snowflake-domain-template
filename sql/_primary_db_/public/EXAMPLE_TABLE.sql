-- File: EXAMPLE_TABLE.sql
-- Object: DEV_<PRIMARY_DB>.<PRIMARY_SCHEMA>.EXAMPLE_TABLE
-- Purpose: Example base table illustrating the file convention.
-- Notes:
--   * Default DDL is CREATE OR REPLACE TABLE — the file is the canonical shape.
--     Safe because rebuildable tables are repopulated by an SP each run.
--   * For historical / non-rebuildable tables, switch to CREATE TABLE IF NOT EXISTS
--     and add: -- Population: historical — do not re-run in PRD
--     See CONVENTIONS.md *Historical / non-rebuildable tables*.
--   * Database name is hardcoded to DEV. PRD deploys go through assembly
--     (see ai/context/deployment.md), which substitutes DEV_ → PRD_.

CREATE OR REPLACE TABLE DEV_<PRIMARY_DB>.<PRIMARY_SCHEMA>.EXAMPLE_TABLE (
    id          NUMBER       NOT NULL,
    name        VARCHAR(255) NOT NULL,
    created_at  TIMESTAMP_NTZ NOT NULL DEFAULT CURRENT_TIMESTAMP(),

    CONSTRAINT PK_EXAMPLE_TABLE PRIMARY KEY (id)
);
