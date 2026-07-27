# Workshop Demo Script
# Infrastructure as Code with Snowflake — DCM Projects, GitOps & Terraform
# Duration: 90 minutes | Audience: Leo, Sarith, Jack + Data Engineering team

---

## Setup Checklist (before the room fills)

- [ ] Terminal open in `CoCo_DE_DEMO/dcm_project/`
- [ ] CoCo Desktop open with `CoCo_DE_DEMO/` as the working directory
- [ ] Snowsight open on `SFSEAPAC-AU_DEMO70` (AU_DEV account)
- [ ] GitHub repo open in browser (for CI/CD demo)
- [ ] Run `snow dcm raw-analyze COCO_DE_DEMO.DCM.PIPELINE_PROJECT -c default --target AU_DEV` once in advance — confirm it passes with no errors
- [ ] Verify the existing Bronze data is loaded: `snow dcm preview COCO_DE_DEMO.DCM.PIPELINE_PROJECT -c default --object COCO_DE_DEMO.BRONZE.CUSTOMERS --limit 5`

---

## Section 1 — Context & Objectives (10 min)

### Talking Points

1. **The multi-account reality**: Most enterprises end up with at least dev/staging/prod, and often multiple regions. Show `dcm_project/manifest.yml` — six targets (AU and UK × dev/staging/prod) defined in one file.

2. **The pain without IaC**: "Has anyone spent an hour debugging why prod has a column that dev doesn't?" Manual `ALTER TABLE` in one account but not the other. No audit trail. No rollback.

3. **What we'll cover today**: Three complementary tools — DCM for database objects, GitHub Actions for GitOps automation, Terraform for account-level bootstrapping. By the end they'll see how these fit together without stepping on each other.

4. **This demo is the pipeline you might build**: Point to `agents.md` briefly — 13 prompts in CoCo built the entire medallion architecture. The DCM project manages the schema of that pipeline declaratively.

---

## Section 2 — DCM Projects Overview (15 min)

### Talking Points

1. **Public Preview status**: DCM is in Public Preview. The `DEFINE` syntax maps 1:1 to `CREATE` statements — same properties, just declarative. If you know Snowflake DDL, you know 90% of DCM.

2. **Core idea — idempotency**: Run the same definitions 10 times, get the same result. DCM figures out whether to CREATE, ALTER, or do nothing. No more "object already exists" errors in deployment scripts.

3. **Walk through the manifest structure** — open `dcm_project/manifest.yml`:
   - `manifest_version: 2` and `type: DCM_PROJECT`
   - Six targets — note AU_DEV and AU_STAGING share the same account but **must have different `project_name` values** (a DCM constraint: two targets on the same account sharing a project_name would overwrite each other)
   - AU_PROD and UK_PROD safely share `project_name` because they are different Snowflake accounts
   - `templating` block — `wh_size` and `env_suffix` resolve differently per environment

4. **Walk through DEFINE syntax** — open `dcm_project/sources/definitions/bronze_tables.sql`:
   - Show `DEFINE TABLE` vs what `CREATE TABLE` looks like
   - Point out `CHANGE_TRACKING = TRUE` and `DATA_METRIC_SCHEDULE`
   - "DCM handles the CREATE vs ALTER decision automatically"

5. **Companion scripts** — open `pre_deploy.sql` and `post_deploy.sql`:
   - Some objects can't be DEFINE'd (storage integrations, external stages, CDC streams, Snowpipe)
   - These live in companion scripts that run before/after DCM operations
   - DCM + companion scripts = full infrastructure coverage

### Key Files to Show

```
dcm_project/
├── manifest.yml                          ← multi-account targets + templating
├── pre_deploy.sql                        ← storage integration (ACCOUNTADMIN)
├── post_deploy.sql                       ← external stage, streams, Snowpipe
└── sources/definitions/
    ├── infrastructure.sql                ← DEFINE SCHEMA + FILE FORMAT
    ├── bronze_tables.sql                 ← DEFINE TABLE with CHANGE_TRACKING
    ├── access.sql                        ← DEFINE WAREHOUSE + roles (new!)
    ├── tasks.sql                         ← DEFINE TASK (8-step DAG)
    └── expectations.sql                  ← DEFINE DATA METRIC FUNCTION + ATTACH
```

---

## Section 3 — Live Demo: DCM in Action (20 min)

### Part A: Show the project analyze (3 min)

```bash
cd dcm_project

snow dcm raw-analyze COCO_DE_DEMO.DCM.PIPELINE_PROJECT \
    -c default \
    --target AU_DEV
```

**What to highlight in the output:**
- All objects listed (schemas, tables, procedures, tasks, DMFs, now roles + warehouse)
- Dependency ordering — DCM resolves the correct CREATE order automatically
- Any errors would show here before you touch Snowflake

### Part B: Show roles and warehouse (5 min)

Open `sources/definitions/access.sql`. Walk through:

1. `DEFINE WAREHOUSE COCO_DE_DEMO_PIPELINE_WH{{ env_suffix }}` — the `{{ env_suffix }}` token comes from the manifest templating block. DEV deploys `..._DEV`, PROD deploys the bare name.

2. `WAREHOUSE_SIZE = '{{ wh_size }}'` — same definition, XSMALL in DEV, LARGE in PROD. Zero code change needed to size up for production.

3. The three-tier database role pattern: ANALYST → DEVELOPER → ADMIN (each tier inherits from the one below). Role hierarchy with one `GRANT DATABASE ROLE` per tier.

4. **Critical constraint**: `GRANT USAGE ON WAREHOUSE ... TO ROLE` (an account role) — not to a database role. Snowflake won't allow warehouse grants to database roles. The account role `COCO_DE_DEMO_WH_USER` bridges that gap.

### Part C: Run plan (7 min)

```bash
snow dcm plan COCO_DE_DEMO.DCM.PIPELINE_PROJECT \
    -c default \
    --target AU_DEV \
    --save-output
```

Read `out/plan/plan_result.json` (or show in terminal):

```bash
cat out/plan/plan_result.json | python3 -c "
import json, sys
data = json.load(sys.stdin)
ops = data.get('ddlChangeLog', {}).get('operations', [])
for op in ops:
    print(f\"{op.get('operationType','?'):8} {op.get('objectDomain','?'):20} {op.get('objectName','?')}\")
"
```

**Talking points for the plan output:**
- Every change is visible before it touches the database — this is the code review moment
- DROP operations appear in RED (highlight how safe this makes schema changes)
- Zero-change objects (adopted objects, unchanged definitions) show nothing — idempotency confirmed

### Part D: Deploy (5 min)

```bash
snow dcm deploy COCO_DE_DEMO.DCM.PIPELINE_PROJECT \
    -c default \
    --target AU_DEV \
    --alias "workshop-demo-v1"
```

After deploy, show deployment history:

```bash
snow dcm list-deployments COCO_DE_DEMO.DCM.PIPELINE_PROJECT -c default
```

Switch to Snowsight and verify `COCO_DE_DEMO_PIPELINE_WH_DEV` warehouse and the database roles exist.

---

## Section 4 — DCM + GitOps CI/CD (15 min)

### Talking Points

1. **The problem with manual deploy**: Even with DCM, a human still runs `snow dcm deploy`. If two engineers deploy from different local branches, you get drift.

2. **GitOps principle**: The `main` branch is the source of truth. Every change goes through a PR. Plan happens automatically on PR open; deploy happens automatically on merge.

3. **Walk through the workflow files:**

Open `.github/workflows/dcm_plan.yml`:
- Trigger: `pull_request` targeting `main`, only when `dcm_project/**` changes
- Auth: RSA key stored as GitHub Secret — no passwords, no interactive login
- `snow dcm plan --save-output` — writes to `out/plan/plan_result.json`
- The `actions/github-script` step parses the JSON and posts CREATE/ALTER/DROP summary as a PR comment

Open `.github/workflows/dcm_deploy.yml`:
- Trigger: `push` to `main` — i.e., after a PR is merged
- Runs plan first (for the audit artifact), then deploy
- `--alias "deploy-$(git sha)"` — every deployment is tagged and visible in `list-deployments`
- Plan artifact is uploaded and retained for 30 days (audit trail)

4. **Show a simulated PR flow** (if you have the repo on GitHub):
   - Create a branch, add a column to a table definition
   - Open PR → GitHub Actions runs plan → PR gets a comment showing `ALTER TABLE: + column`
   - Merge → deploy runs automatically

5. **Key message for the team**: "You no longer need to remember to run the deploy. You also can't accidentally deploy from a stale local branch. The git history IS the deployment history."

### GitHub Secrets to Set Up

| Secret Name | Value |
|-------------|-------|
| `SNOWFLAKE_ACCOUNT` | `SFSEAPAC-AU_DEMO70` |
| `SNOWFLAKE_USER` | service account username |
| `SNOWFLAKE_PRIVATE_KEY` | RSA private key (PEM, no passphrase) |

Generate key pair:
```bash
openssl genrsa 2048 | openssl pkcs8 -topk8 -inform PEM -out sf_key.pem -nocrypt
openssl rsa -in sf_key.pem -pubout -out sf_key_pub.pem
# In Snowflake:
# ALTER USER <svc_user> SET RSA_PUBLIC_KEY='<contents of sf_key_pub.pem>';
```

---

## Section 5 — Hybrid Approach: DCM + Terraform (15 min)

### Talking Points

1. **Why both?** Terraform excels at account-level bootstrapping — users, warehouse creation, network policies, SSO/SCIM. DCM excels at database-level declarative management with dependency resolution. They don't overlap.

2. **The boundary** — open `terraform/README.md` and walk through the ASCII diagram:
   - Terraform creates `COCO_DE_DEMO_PIPELINE_WH_DEV` (the warehouse object itself)
   - DCM's `access.sql` then grants USAGE on that warehouse to the project roles
   - Clear handoff: Terraform runs first (infra bootstrap), then DCM runs (database objects)

3. **Show the warehouse module** — open `terraform/modules/snowflake_warehouses/main.tf`:
   - Single `snowflake_warehouse` resource
   - `var.warehouse_size` — same concept as DCM's `{{ wh_size }}`, but in tfvars
   - `terraform/environments/dev/terraform.tfvars`: `warehouse_size = "XSMALL"`
   - `terraform/environments/prod/terraform.tfvars`: `warehouse_size = "LARGE"`

4. **Show the account roles module** — open `terraform/modules/snowflake_account_roles/main.tf`:
   - Creates `PIPELINE_DEPLOYER` and `COCO_DE_DEMO_WH_USER` account roles
   - Creates the CI/CD service account user
   - Note the comment: "database roles are managed by DCM in access.sql — not here"

5. **Common question**: "Can Terraform manage my tables and views too?"
   - Technically yes, but DCM is better at it: dependency resolution, DCM PLAN diff, idempotency without needing Terraform state drift detection.
   - The right rule: if it lives outside a database, use Terraform. If it lives inside, use DCM.

6. **Migration path**: Teams already using Terraform for Snowflake can adopt DCM incrementally — start with one database, let Terraform keep managing the account-level stuff it already owns.

---

## Section 6 — AI-Assisted IaC with Cortex Code (10 min)

### Demo Flow

This section shows how CoCo + the `/dcm` skill eliminates the manual work of converting existing SQL DDL to DCM definitions.

1. **Open `sql/03_bronze_tables.sql`** in CoCo — show the imperative CREATE TABLE statements with no change tracking, no data quality schedule.

2. **In CoCo chat, type:**
   ```
   /dcm
   Convert the CREATE TABLE statements in sql/03_bronze_tables.sql to DCM DEFINE statements.
   Add CHANGE_TRACKING = TRUE and DATA_METRIC_SCHEDULE = '60 MINUTE' to each table.
   Place the output in sources/definitions/ following the existing naming conventions.
   ```

3. **Walk through what CoCo generates** — compare to the existing `bronze_tables.sql`:
   - `CREATE TABLE` → `DEFINE TABLE`
   - Fully qualified names added automatically
   - CHANGE_TRACKING and DATA_METRIC_SCHEDULE added
   - Comments preserved

4. **Key message**: "For teams with hundreds of existing SQL scripts, this cuts the DCM migration from weeks to hours. You feed CoCo your existing DDL and it produces valid DEFINE statements ready to plan and deploy."

5. **Broader pattern**: `/dcm` also helps with:
   - Designing a multi-environment manifest from scratch
   - Debugging `PLAN_FAILED` errors
   - Converting dbt model definitions to dynamic tables

### Talking Points

- CoCo has read the DCM documentation and knows the exact DEFINE syntax
- It respects the three-tier role pattern and companion script boundaries
- Every suggestion can be reviewed before running `snow dcm plan` — the GitOps loop applies here too

---

## Section 7 — Q&A & Next Steps (5 min)

### Anticipated Questions

**Q: What's the rollback story if a deploy goes wrong?**
A: Two options. (1) Fix the definition and redeploy — DCM will ALTER back. (2) For data loss (DROP), Time Travel is your safety net — `SELECT * FROM table AT(offset => -5)` gives you 90 days on most editions. The `--alias` flag on deploy means you can always identify exactly which deploy caused the issue.

**Q: Does DCM support Snowflake Streams?**
A: Not via `DEFINE` syntax — streams go in `post_deploy.sql` as imperative `CREATE STREAM` statements. The companion script pattern covers all unsupported object types cleanly.

**Q: Can two teams share one DCM project?**
A: Better to split into separate projects per team boundary. Each project has a single `project_owner` role. Separate projects can be deployed independently and have separate GitOps pipelines.

**Q: What about schema migrations — ALTER TABLE ADD COLUMN?**
A: DCM handles it automatically. You add the column to your `DEFINE TABLE` definition, run `snow dcm plan`, and the plan shows `ALTER TABLE ... ADD COLUMN`. No migration scripts needed.

**Q: Does this replace dbt?**
A: No — complementary. dbt owns transformation logic (models, tests, macros). DCM owns infrastructure (schemas, raw tables, task DAGs, roles). This demo uses both: DCM defines Bronze tables and orchestration, dbt builds Silver and Gold.

### Suggested Action Items for the Team

1. Pick one database or schema to onboard to DCM as a pilot — low risk, high learning
2. Set up the GitHub Actions workflows against your dev account first
3. Terraform: audit what you currently manage manually at the account level — that's your Terraform backlog
4. Use CoCo's `/dcm` skill to convert the pilot's existing CREATE statements to DEFINE — run `snow dcm plan` with `--save-output` to verify zero drift before committing
5. Review DCM Public Preview release notes for the multi-account roadmap

---

## Command Reference Card

```bash
# Analyze — validate definitions, show objects and dependencies
snow dcm raw-analyze COCO_DE_DEMO.DCM.PIPELINE_PROJECT \
    -c default --target AU_DEV

# Plan — preview changes (always run before deploy)
snow dcm plan COCO_DE_DEMO.DCM.PIPELINE_PROJECT \
    -c default --target AU_DEV --save-output

# Deploy — apply changes to Snowflake
snow dcm deploy COCO_DE_DEMO.DCM.PIPELINE_PROJECT \
    -c default --target AU_DEV --alias "workshop-demo-v1"

# List all projects (use --database "" to see all, not just default DB)
snow dcm list -c default --database ""

# Show deployment history
snow dcm list-deployments COCO_DE_DEMO.DCM.PIPELINE_PROJECT -c default

# Preview data in a managed table
snow dcm preview COCO_DE_DEMO.DCM.PIPELINE_PROJECT \
    -c default --object COCO_DE_DEMO.BRONZE.CUSTOMERS --limit 10

# Run data quality tests
snow dcm test COCO_DE_DEMO.DCM.PIPELINE_PROJECT -c default
```

---

## Repo Structure Quick Reference

```
CoCo_DE_DEMO/
├── dcm_project/
│   ├── manifest.yml                  ← 6 targets (AU/UK × dev/staging/prod) + templating
│   ├── pre_deploy.sql                ← storage integration (ACCOUNTADMIN required)
│   ├── post_deploy.sql               ← external stage, streams, Snowpipe
│   └── sources/definitions/
│       ├── infrastructure.sql        ← schemas, CSV file format
│       ├── access.sql                ← warehouse + 3-tier roles (new)
│       ├── bronze_tables.sql         ← 6 raw landing tables
│       ├── silver_tables.sql         ← anomaly flags table
│       ├── gold_tables.sql           ← RFM scores, pipeline summary
│       ├── procedures.sql            ← validation gates + dbt wrappers
│       ├── tasks.sql                 ← 8-task orchestration DAG
│       ├── governance.sql            ← 5 governance tags
│       └── expectations.sql          ← custom DMFs + ATTACH statements
├── .github/workflows/
│   ├── dcm_plan.yml                  ← plan on PR (posts comment)
│   └── dcm_deploy.yml                ← deploy on merge to main
├── terraform/
│   ├── README.md                     ← DCM vs Terraform boundary explanation
│   ├── provider.tf
│   ├── modules/
│   │   ├── snowflake_warehouses/
│   │   └── snowflake_account_roles/
│   └── environments/
│       ├── dev/                      ← XSMALL warehouse
│       └── prod/                     ← LARGE warehouse
├── sql/                              ← imperative SQL (reference + Section 6 demo)
├── dbt_project/                      ← Silver + Gold transformations
└── agents.md                         ← 13 CoCo prompts that built this pipeline
```
