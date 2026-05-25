-- File: example_grant_to_reader.sql
-- Purpose: Grant read access on this domain's objects to the reader role.
-- Notes:
--   * This repo ONLY grants on objects it owns. Cross-database grants
--     (e.g. granting access to a PL schema) live in Snowflake-Administration.
--   * Grants are idempotent — safe to re-run.

GRANT USAGE ON SCHEMA <PRIMARY_DB>.<PRIMARY_SCHEMA>
    TO ROLE <PRIMARY_DB>_READER;

GRANT SELECT ON ALL TABLES IN SCHEMA <PRIMARY_DB>.<PRIMARY_SCHEMA>
    TO ROLE <PRIMARY_DB>_READER;

GRANT SELECT ON FUTURE TABLES IN SCHEMA <PRIMARY_DB>.<PRIMARY_SCHEMA>
    TO ROLE <PRIMARY_DB>_READER;

GRANT SELECT ON ALL VIEWS IN SCHEMA <PRIMARY_DB>.<PRIMARY_SCHEMA>
    TO ROLE <PRIMARY_DB>_READER;

GRANT SELECT ON FUTURE VIEWS IN SCHEMA <PRIMARY_DB>.<PRIMARY_SCHEMA>
    TO ROLE <PRIMARY_DB>_READER;
