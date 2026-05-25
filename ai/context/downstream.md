# Downstream Consumers

Prose commentary on who consumes this domain's outputs.

> The **structured** column-level list of produced objects (and their
> contract level) lives in [`/contracts.yml`](../../contracts.yml). This
> file explains the *who* and the *coordination protocols*.

## Consumers

<!-- For each downstream consumer, briefly describe:
     - which repo / system consumes from us
     - which of our objects they read
     - how breaking changes should be coordinated with them
-->

### SF-Orchestration

<!-- e.g.
The Dagster code location in SF-Orchestration calls our SPs and parses
their VARIANT/text output to build asset metadata.

Coordination protocol when SP output shape changes:
1. Update this domain's PR to also link the SF-Orchestration parser PR.
2. Both PRs land together (this repo's first, since the asset just
   re-runs and picks up the new output naturally).
-->

### <Other consumer>

<!-- e.g. PL_DOMO.<DOMAIN_NAME>.* tables consumed by the Domo dataset
"Sales Daily Snapshot" — owned by analytics team. -->

## When our contracts change

Removing or renaming a produced column is a **breaking change** — even
when it's "obvious" the column was unused. Always:

1. Demote `contract_level` in `contracts.yml` first (a separate PR).
2. Confirm with named consumers that they no longer depend on the column.
3. Then remove it.

Adding columns is non-breaking and can ship in a single PR.
