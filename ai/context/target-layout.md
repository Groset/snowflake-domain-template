# Target Layout

This domain's structure inside Snowflake: schemas, naming, and the recommended manual run order.

## Database & schemas

```
{ENV}_<PRIMARY_DB>
└── <PRIMARY_SCHEMA>
    ├── procedures   ← CREATE OR REPLACE on every run
    ├── functions    ← CREATE OR REPLACE on every run
    ├── views        ← CREATE OR REPLACE on every run
    └── tables       ← CREATE TABLE IF NOT EXISTS (drift-prone; review carefully)
```

<!-- Add secondary databases / schemas here if this domain writes elsewhere,
     e.g. into a PL presentation database. -->

## Naming

See [`/CONVENTIONS.md`](../../CONVENTIONS.md) for the full naming reference.
Summary:

| Type | Pattern |
|------|---------|
| Procedure | `SP_<VERB>_<NOUN>` |
| Function | `UDF_<PURPOSE>` |
| View | `V_<NOUN>` |
| Table | ALLCAPS_SNAKE |

## Recommended manual run order

When deploying multiple changed files to DEV or PRD, run in this order so that downstream objects always see their dependencies:

```
tables  →  functions  →  views  →  procedures  →  grants
```

Rationale: tables hold the data; functions are used inside views and procedures; views may be used inside procedures; procedures are the leaf operational objects; grants come last so they cover whatever was just (re-)created.

## Drift detection

The aggregator in `Snowflake-Administration/contracts/` compares `contracts.yml` claims against `INFORMATION_SCHEMA` daily. If an object disappears or grows/loses columns, the aggregator's `DRIFT.md` report flags it.

When reviewing a PR, the reviewer should check whether claimed shape in `contracts.yml` matches what the SQL in this PR will actually deploy.
