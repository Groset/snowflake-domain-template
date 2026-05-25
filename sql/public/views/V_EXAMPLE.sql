-- File: V_EXAMPLE.sql
-- Object: <PRIMARY_DB>.<PRIMARY_SCHEMA>.V_EXAMPLE
-- Purpose: Example view illustrating the file convention.
-- Returns: rows from EXAMPLE_TABLE with derived columns.
-- Called by: downstream BI / other domains

CREATE OR REPLACE VIEW <PRIMARY_DB>.<PRIMARY_SCHEMA>.V_EXAMPLE AS
SELECT
    id,
    name,
    <PRIMARY_DB>.<PRIMARY_SCHEMA>.UDF_EXAMPLE(name) AS name_normalized,
    created_at
FROM <PRIMARY_DB>.<PRIMARY_SCHEMA>.EXAMPLE_TABLE;
