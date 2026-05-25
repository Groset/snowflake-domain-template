-- File: UDF_EXAMPLE.sql
-- Object: <PRIMARY_DB>.<PRIMARY_SCHEMA>.UDF_EXAMPLE
-- Purpose: Example scalar UDF illustrating the file convention.
-- Returns: VARCHAR — lowercased, trimmed input.
-- Called by: manual / inline in SQL

CREATE OR REPLACE FUNCTION <PRIMARY_DB>.<PRIMARY_SCHEMA>.UDF_EXAMPLE(input VARCHAR)
RETURNS VARCHAR
LANGUAGE SQL
AS
$$
    LOWER(TRIM(input))
$$;
