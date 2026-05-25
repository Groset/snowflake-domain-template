# snowflake-domain-template

Template repository for a new Groset Snowflake domain.

A "domain" here means one primary Snowflake database (typically an IL — Integration Layer) plus any schemas this team is responsible for inside shared presentation-layer databases (e.g. `PL_DOMO`).

This template contains the conventions, folder layout, AI working agreements, and contract specification a new domain needs on day one. There is **no automated deploy**: developers run `.sql` files manually via the Snowflake VSCode extension. CI lints SQL only.

---

## Creating a new domain repo from this template

1. On the GitHub page for this template, click **Use this template** → **Create a new repository**.
2. Clone the new repo locally.
3. Open the repo in Claude Code (or your AI coding agent of choice) and ask it to **"follow `INIT.md`"** (or "run init", "personalize the template" — anything natural). Claude will:
   - Read `INIT.md` for instructions
   - Propose defaults based on the folder/repo name
   - Ask you to confirm the domain name, primary database, and primary schema
   - Substitute the placeholders across every template file
   - Delete `INIT.md` when done
4. Commit the personalization changes.
5. Open `CLAUDE.md` and work through the rest of **First Steps**.

There is no fallback script. If you don't have an AI agent available, `INIT.md` is human-readable — you can do the same substitutions by hand (search-replace `<DOMAIN_NAME>`, `<PRIMARY_DB>`, `<PRIMARY_SCHEMA>` across all `.md`/`.yml`/`.sql` files).

---

## Repo layout (at a glance)

| Path | Purpose |
|------|---------|
| `snowflake.yml` | Contract document — what Snowflake-Administration must provision before this repo deploys |
| `contracts.yml` | Declarative data contract — what this domain produces and consumes |
| `sql/<schema>/procedures/` | `CREATE OR REPLACE PROCEDURE` files |
| `sql/<schema>/functions/`  | `CREATE OR REPLACE FUNCTION` files |
| `sql/<schema>/views/`      | `CREATE OR REPLACE VIEW` files |
| `sql/<schema>/tables/`     | `CREATE TABLE IF NOT EXISTS` files |
| `grants/` | Grants on objects this repo owns |
| `ai/agents/` | Subagent role prompts tuned for this domain |
| `ai/context/` | Long-lived reference material (summary-paired with raw where large) |
| `ai/features/` | Numbered feature directories — planning + implementation history |
| `ai/session/` | Ad-hoc scripts, validation reports, ephemeral working files |
| `.github/` | PR template + lint CI |

See `CLAUDE.md` for the full project guide and `CONVENTIONS.md` for naming + review standards.

---

## License

Add a `LICENSE` file appropriate to your project once the repo is personalized.
