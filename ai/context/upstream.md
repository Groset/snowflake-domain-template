# Upstream Dependencies

Prose commentary on what this domain reads from external sources.

> The **structured** column-level list of consumed objects lives in
> [`/contracts.yml`](../../contracts.yml). This file explains the *why* and
> the *caveats* — things that don't fit in YAML.

## Sources

<!-- For each upstream source, briefly describe:
     - which producer owns it (which repo)
     - what this domain uses it for
     - any quirks, freshness expectations, or known issues
-->

### `RL_<SOURCE>` (owned by `<source-etl-repo>`)

<!-- e.g.
The Sage ETL lands daily snapshots into RL_SAGE.source. We read from
glt_group_dbo_apm_master__invoice and groset_group_dbo_apm_master__invoice
for the invoice aggregations. Watermark column: `update_date`.

Quirks:
- Sage emits TIMESTAMP_NTZ with no timezone metadata; treat as Australia/Melbourne.
- Some rows have negative amounts indicating credits; preserve sign.
-->

## When upstream contracts change

If an upstream producer changes its schema (column added, removed, renamed,
or type changed):

1. The producer should announce the change via their own PR.
2. Check `contracts.yml` — the `consumes:` entry for any affected object
   may need updating (especially `columns_used`).
3. If we *lose* a column we depend on, this is a breaking change for us;
   coordinate the deploy order with the producer.
