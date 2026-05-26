-- File: example_grant_to_reader.sql
-- Purpose: Grant read access on this domain's objects to BSL_DEFAULT_ROLE.
-- Notes:
--   * BSL_DEFAULT_ROLE is the general developer role — needs SELECT on
--     this domain's tables and views so devs can read from PRD and
--     develop against DEV.
--   * DAGSTER_DEV_ROLE / DAGSTER_PRD_ROLE own the objects in their
--     respective environments; they do not need additional grants here.
--   * This repo only grants on objects it owns. Account-wide role
--     definitions and database-level USAGE grants live in
--     Snowflake-Administration.
--   * Grants are idempotent — safe to re-run.
--   * Database name is hardcoded to DEV. PRD deploys go through assembly
--     (see ai/context/deployment.md), which substitutes DEV_ → PRD_.

GRANT USAGE ON SCHEMA DEV_<PRIMARY_DB>.<PRIMARY_SCHEMA>
    TO ROLE BSL_DEFAULT_ROLE;

GRANT SELECT ON ALL TABLES IN SCHEMA DEV_<PRIMARY_DB>.<PRIMARY_SCHEMA>
    TO ROLE BSL_DEFAULT_ROLE;

GRANT SELECT ON FUTURE TABLES IN SCHEMA DEV_<PRIMARY_DB>.<PRIMARY_SCHEMA>
    TO ROLE BSL_DEFAULT_ROLE;

GRANT SELECT ON ALL VIEWS IN SCHEMA DEV_<PRIMARY_DB>.<PRIMARY_SCHEMA>
    TO ROLE BSL_DEFAULT_ROLE;

GRANT SELECT ON FUTURE VIEWS IN SCHEMA DEV_<PRIMARY_DB>.<PRIMARY_SCHEMA>
    TO ROLE BSL_DEFAULT_ROLE;

-- If this domain publishes to Domo (any object that the PC_DOMO integration
-- needs to read), also grant USAGE + SELECT to PC_DOMO_ROLE here.
--
-- GRANT USAGE  ON SCHEMA  DEV_<PRIMARY_DB>.<PRIMARY_SCHEMA> TO ROLE PC_DOMO_ROLE;
-- GRANT SELECT ON ALL    TABLES IN SCHEMA DEV_<PRIMARY_DB>.<PRIMARY_SCHEMA> TO ROLE PC_DOMO_ROLE;
-- GRANT SELECT ON FUTURE TABLES IN SCHEMA DEV_<PRIMARY_DB>.<PRIMARY_SCHEMA> TO ROLE PC_DOMO_ROLE;
-- GRANT SELECT ON ALL    VIEWS  IN SCHEMA DEV_<PRIMARY_DB>.<PRIMARY_SCHEMA> TO ROLE PC_DOMO_ROLE;
-- GRANT SELECT ON FUTURE VIEWS  IN SCHEMA DEV_<PRIMARY_DB>.<PRIMARY_SCHEMA> TO ROLE PC_DOMO_ROLE;
