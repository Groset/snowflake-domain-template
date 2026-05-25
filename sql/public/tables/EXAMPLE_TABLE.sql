-- File: EXAMPLE_TABLE.sql
-- Object: <PRIMARY_DB>.<PRIMARY_SCHEMA>.EXAMPLE_TABLE
-- Purpose: Example base table illustrating the file convention.
-- Notes:
--   * Default DDL is CREATE OR REPLACE TABLE — the file is the canonical shape.
--   * This is safe because rebuildable tables are repopulated by an SP each run.
--   * For historical / non-rebuildable tables, switch to CREATE TABLE IF NOT EXISTS
--     and add: -- Population: historical — do not re-run in PRD
--     See CONVENTIONS.md *Historical / non-rebuildable tables*.

CREATE OR REPLACE TABLE <PRIMARY_DB>.<PRIMARY_SCHEMA>.EXAMPLE_TABLE (
    id          NUMBER       NOT NULL,
    name        VARCHAR(255) NOT NULL,
    created_at  TIMESTAMP_NTZ NOT NULL DEFAULT CURRENT_TIMESTAMP(),

    CONSTRAINT PK_EXAMPLE_TABLE PRIMARY KEY (id)
);
