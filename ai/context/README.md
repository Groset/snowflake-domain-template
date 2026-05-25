# Reference Context

Long-lived reference material for this domain. Anything expensive to re-derive each session lives here.

## Convention

For large reference material, pair a **summary** file (`*-summary.md`) with the raw source. Claude reads the summary first and only drills into the raw file when a specific question demands full detail. This keeps context windows lean.

The **structured contract** (column-level produces/consumes) lives in the repo root at `contracts.yml`. The files here are prose commentary on top of that.

## Index

| File | Purpose |
|------|---------|
| [upstream.md](upstream.md) | Prose commentary on upstream dependencies. Structured list is in `contracts.yml`. |
| [downstream.md](downstream.md) | Prose commentary on downstream consumers. Structured list is in `contracts.yml`. |
| [snowflake-contract.md](snowflake-contract.md) | What Snowflake-Administration must provision before this repo can deploy. |
| [target-layout.md](target-layout.md) | This domain's schemas, naming, run order, and conventions. |

Add summary-paired files here when the domain accumulates large reference material (e.g. table inventories generated from `INFORMATION_SCHEMA`).
