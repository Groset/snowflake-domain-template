-- File: vw_example.sql
-- Object: <PRIMARY_DB>.<PRIMARY_SCHEMA>.vw_example
--   (written lowercase here; Snowflake stores it as VW_EXAMPLE)
-- Purpose: Example view illustrating the file convention.
-- Returns: rows from EXAMPLE_TABLE with derived columns.
-- Called by: downstream BI / other domains

CREATE OR REPLACE VIEW <PRIMARY_SCHEMA>.vw_example AS
SELECT
    id,
    name,
    <PRIMARY_SCHEMA>.UDF_EXAMPLE(name) AS name_normalized,
    created_at
FROM <PRIMARY_SCHEMA>.EXAMPLE_TABLE;
