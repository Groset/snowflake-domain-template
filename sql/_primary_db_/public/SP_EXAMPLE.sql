-- File: SP_EXAMPLE.sql
-- Object: DEV_<PRIMARY_DB>.<PRIMARY_SCHEMA>.SP_EXAMPLE
-- Purpose: Example stored procedure illustrating the file convention.
-- Returns: VARIANT JSON with keys: status, rows_processed
-- Called by: manual (replace with calling asset / SP when wired up)

CREATE OR REPLACE PROCEDURE DEV_<PRIMARY_DB>.<PRIMARY_SCHEMA>.SP_EXAMPLE()
RETURNS VARIANT
LANGUAGE SQL
AS
$$
DECLARE
    rows_processed NUMBER DEFAULT 0;
BEGIN
    -- Replace this body with the real procedure logic.
    SELECT COUNT(*) INTO :rows_processed
      FROM DEV_<PRIMARY_DB>.<PRIMARY_SCHEMA>.EXAMPLE_TABLE;

    RETURN OBJECT_CONSTRUCT(
        'status',         'success',
        'rows_processed', :rows_processed
    );
END;
$$;
