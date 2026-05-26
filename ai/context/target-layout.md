# Target Layout

This domain's structure inside Snowflake (what objects live where) and the repo's source organization. For deployment mechanics, see [`deployment.md`](deployment.md).

## In Snowflake

```
DEV_<PRIMARY_DB>                ← also exists as PRD_<PRIMARY_DB>
└── <PRIMARY_SCHEMA>
    ├── procedures   ← CREATE OR REPLACE every deploy
    ├── functions    ← CREATE OR REPLACE every deploy
    ├── views        ← CREATE OR REPLACE every deploy
    └── tables       ← CREATE OR REPLACE TABLE by default;
                        CREATE TABLE IF NOT EXISTS for historical /
                        non-rebuildable tables (documented exception)
```

<!-- Add secondary databases / schemas here if this domain writes elsewhere,
     e.g. into a PL presentation database like PL_DOMO. -->

## In the source repo

```
sql/
  dev_<primary_db>/                ← env-prefixed, lowercase. After INIT.md.
    <primary_schema>/
      <files organized however the domain prefers>
        EXAMPLE_TABLE.sql
        UDF_EXAMPLE.sql
        vw_example.sql
        SP_EXAMPLE.sql
        SEED_REGIONS.sql           ← if any
grants/
  <files>.sql                      ← grants on this domain's objects
```

Files below `<schema>/` can be flat, grouped by feature, by purpose, or by category — domain's choice. The deploy assembler classifies by filename prefix (`SP_`, `UDF_`, `vw_`, `SEED_`) and CREATE statement, not by folder name.

Every database reference in a source file is `DEV_*`-prefixed. PRD versions are produced by the assembler at deploy time — see [`deployment.md`](deployment.md).

## Naming

See [`/CONVENTIONS.md`](../../CONVENTIONS.md) for the full reference. Summary:

| Type | Pattern | Example |
|------|---------|---------|
| Procedure | `SP_<VERB>_<NOUN>` | `SP_BUILD_CUSTOMER_360` |
| Function | `UDF_<PURPOSE>` | `UDF_NORMALIZE_PHONE` |
| View | `vw_<noun>` (lowercase) | `vw_customer_latest` |
| Table | `ALLCAPS_SNAKE` | `CUSTOMER_TRANSACTION` |
| Seed | `SEED_<NOUN>` | `SEED_REGIONS` |

## Recommended manual run order (DEV)

When running multiple changed source files in DEV via VSCode, run in this order so downstream objects see their dependencies:

```
tables  →  functions  →  views  →  procedures  →  seed  →  grants
```

The assembler applies the same order automatically when bundling for PRD.

## Drift detection

The aggregator in `Snowflake-Administration/contracts/` compares `contracts.yml` claims against `INFORMATION_SCHEMA` daily. If an object disappears or grows/loses columns, the aggregator's `DRIFT.md` report flags it.

When reviewing a PR, the reviewer should check whether claimed shape in `contracts.yml` matches what the SQL in this PR will actually deploy.
