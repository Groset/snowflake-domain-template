# Init — Domain Repo Personalization

> **For Claude (or any coding agent)**: this file is an instruction
> script, not a shell script. When a user has just cloned a repo created
> from `snowflake-domain-template` and asks you to "run init", "follow
> INIT.md", "personalize the template", or similar — execute the steps
> below.

## Purpose

A fresh template repo contains three placeholders. This process replaces
them across every template file based on what the user tells you:

| Placeholder | What it is | Example |
|-------------|------------|---------|
| `<DOMAIN_NAME>` | Short kebab-case identifier; matches the GitHub repo name | `il-customers` |
| `<PRIMARY_DB>` | Snowflake database (without `DEV_`/`PRD_` prefix) | `IL_Customers` |
| `<PRIMARY_SCHEMA>` | Primary schema name | `PUBLIC` |

After substitution this file should be deleted — it's bootstrap-only.

---

## Steps

### 1. Detect prior personalization

Before doing anything, check whether the repo is still in its untouched
template state.

- Search for any remaining occurrence of `<DOMAIN_NAME>`, `<PRIMARY_DB>`,
  or `<PRIMARY_SCHEMA>` in the repo (excluding `.git/` and `INIT.md`).
- If **none** are found, the repo has already been personalized. Stop and
  tell the user the repo looks personalized already — ask whether to
  proceed anyway (re-run), skip, or abort.

### 2. Gather context for smart defaults

Before prompting, collect signal to propose good defaults:

- **Working directory basename** (e.g. `il-customers`) — strong candidate
  for `DOMAIN_NAME`.
- **Git remote URL** (`git remote get-url origin` if configured) — the
  GitHub repo name there is another candidate.
- **Derived primary database**: take the domain name, split on `-`, and
  build `{LAYER}_{TitleCase}` where `LAYER` is the first segment uppercased
  (e.g. `il-customers` → `IL_Customers`, `pl-domo` → `PL_Domo`).

### 3. Ask the user

Use the AskUserQuestion tool (or the most natural prompting mechanism
available). Three questions, with the proposed defaults from step 2:

1. **Domain name** (kebab-case identifier matching the GitHub repo)
2. **Primary database** (Snowflake DB without env prefix)
3. **Primary schema** (default: `PUBLIC`)

Phrase each question so the user sees both the proposed default and a
brief reminder of the convention. Allow them to override any value.

### 4. Validate

Run these checks on the collected values:

| Field | Rule | Example failure |
|-------|------|-----------------|
| Domain name | `^[a-z][a-z0-9-]*$` (lowercase kebab-case, no underscores) | `IL_Customers`, `il customers` |
| Primary database | `^(IL|PL|RL)_[A-Za-z][A-Za-z0-9_]*$` (layer prefix + identifier) | `Customers`, `il-customers`, `DEV_IL_Customers` |
| Primary schema | Uppercase, `^[A-Z][A-Z0-9_]*$` | `Public`, `public` |

If any value fails, explain the rule and re-prompt for that field. Don't
proceed until all three are valid.

### 5. Show the change-set and confirm

Before any edits, summarize for the user:

- The three chosen values.
- The set of files that will be modified (every `.md`, `.yml`, `.yaml`,
  and `.sql` outside `.git/`, plus `INIT.md` itself which will be deleted).
- That `sql/_primary_db_/` will be renamed to `sql/<primary_db_lowercased>/` (always).
- Whether the schema folder will also be renamed (yes, if the primary
  schema is not `PUBLIC` — rename `public/` to `<schema-lowercased>/`
  inside the DB folder).
- That `INIT.md` be deleted at the end.

Then ask "Proceed?" via AskUserQuestion. Don't edit anything until they
confirm.

### 6. Apply substitutions

For each file matching the include pattern (`.md`, `.yml`, `.yaml`, `.sql`)
and not under `.git/`:

- Read the file.
- Replace every `<DOMAIN_NAME>` → user's domain name.
- Replace every `<PRIMARY_DB>` → user's primary database.
- Replace every `<PRIMARY_SCHEMA>` → user's primary schema.
- Write the file back.

Rename the placeholder folder structure to match the chosen values. The template ships with `sql/_primary_db_/public/<category>/...`; after personalization it should be `sql/<primary_db_lowercased>/<primary_schema_lowercased>/<category>/...`.

Two renames, both lowercase:

```
sql/_primary_db_/  →  sql/<primary_db_lowercased>/        (always)
sql/<primary_db_lowercased>/public/  →
    sql/<primary_db_lowercased>/<primary_schema_lowercased>/   (only if schema != PUBLIC, case-insensitive)
```

(Use `git mv` if the repo is a git repo, otherwise a plain move.)

### 7. Clean up

- **Delete `INIT.md`** (this file) — its job is done; the personalized
  repo should not retain bootstrap instructions.

### 8. Summarize and hand off

Print a short summary of what was done, then point the user at the next
step:

> Personalization complete.
>
> - Review the changes: `git diff` (or inspect the files directly).
> - Open `CLAUDE.md` and continue with "First Steps" item 2 onward — you've
>   just completed item 1.
> - First commit: `git add -A && git commit -m "chore: personalize template"`

---

## Notes for the agent

- Keep the conversation short. The user has already decided to use this
  template; don't over-explain. A few sentences of context, three
  questions, a confirmation, then execute.
- Do not modify files in `.git/` (you shouldn't be able to anyway).
- If validation fails, re-prompt only the field that failed; don't make
  the user re-answer everything.
- If the user aborts at the confirmation step, leave the repo untouched.
