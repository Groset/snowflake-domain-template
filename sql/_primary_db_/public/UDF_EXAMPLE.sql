-- File: UDF_EXAMPLE.sql
-- Object: DEV_<PRIMARY_DB>.<PRIMARY_SCHEMA>.UDF_EXAMPLE
-- Purpose: Example scalar UDF illustrating the file convention.
-- Returns: VARCHAR — lowercased, trimmed input.
-- Called by: vw_example, manual / inline in SQL

CREATE OR REPLACE FUNCTION DEV_<PRIMARY_DB>.<PRIMARY_SCHEMA>.UDF_EXAMPLE(input VARCHAR)
RETURNS VARCHAR
LANGUAGE SQL
AS
$$
    LOWER(TRIM(input))
$$;
