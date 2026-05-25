-- File: EXAMPLE_TABLE.sql
-- Object: <PRIMARY_DB>.<PRIMARY_SCHEMA>.EXAMPLE_TABLE
-- Purpose: Example base table illustrating the file convention.
-- Notes:
--   * Use CREATE TABLE IF NOT EXISTS — this file is for initial creation.
--   * For ongoing schema changes, run ALTER ad-hoc via VSCode AND update
--     this file in the same PR so it reflects current shape.

CREATE TABLE IF NOT EXISTS <PRIMARY_DB>.<PRIMARY_SCHEMA>.EXAMPLE_TABLE (
    id          NUMBER       NOT NULL,
    name        VARCHAR(255) NOT NULL,
    created_at  TIMESTAMP_NTZ NOT NULL DEFAULT CURRENT_TIMESTAMP(),

    CONSTRAINT PK_EXAMPLE_TABLE PRIMARY KEY (id)
);
