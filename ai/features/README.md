# Feature Index

Significant changes to this domain — each in its own numbered directory with planning and implementation notes.

A "feature" here is any change worth designing before coding: a new table, a redesigned SP, a new presentation-layer materialization, a contract change.

## Index

<!-- Add a row per feature directory. Numbered in execution order. -->

| Feature | Status | Directory | Description |
|---------|--------|-----------|-------------|
| 01 — Initial bootstrap | Planning | [01-initial-bootstrap/](01-initial-bootstrap/) | Import existing objects, populate contracts.yml |

## Dependency Order

```
01
```

<!-- As features accumulate, draw the dependency graph here so a new
     reader can see the order of work. Example:

01 ──┬─► 02 ──► 04
     └─► 03 ──► 05
-->

## Template

New features copy [_template/](_template/) into a new numbered directory.

```
ai/features/_template/  →  ai/features/NN-short-name/
```

Renumber if you start a parallel track. Lower numbers run first.
