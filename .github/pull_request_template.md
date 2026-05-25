## Summary

<!-- 1-2 sentences: what does this PR do and why? -->

## Changes

<!-- List of objects created / modified / removed. -->

- [ ] Procedure(s):
- [ ] Function(s):
- [ ] View(s):
- [ ] Table(s):
- [ ] Grant(s):

## Reviewer Checklist

- [ ] File names match object names; one object per file.
- [ ] Every changed file has a complete header comment (File / Object / Purpose / Returns / Called by).
- [ ] Stateless objects use `CREATE OR REPLACE`; tables use `CREATE TABLE IF NOT EXISTS`.
- [ ] No destructive operations (`DROP`, `TRUNCATE`, type narrowing, NOT NULL on existing column) without explicit reviewer awareness.
- [ ] If a table's shape changed, the matching `tables/<name>.sql` file reflects the new shape.
- [ ] `contracts.yml` updated if any `produces:` or `consumes:` claim changed.
- [ ] `ai/context/upstream.md` / `downstream.md` updated if commentary needs to reflect a change.
- [ ] Grants only touch objects this repo owns.

## Deployment

- [ ] DEV deploy planned (paste run order):
- [ ] PRD deploy coordinated with: <!-- @other-dev -->

## Related PRs

<!-- Link any cross-repo PRs: Snowflake-Administration (grants/roles),
     SF-Orchestration (parser updates), other domain repos. -->

- Snowflake-Administration:
- SF-Orchestration:
- Other:
