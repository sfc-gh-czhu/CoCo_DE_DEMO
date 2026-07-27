# Talk Track: Getting Started with Snowflake CoCo for Data Engineers

**Event:** Snowflake DISCOVER AI (Live & Local)  
**Date:** 6-10 July 2026  
**Total runtime:** ~40 minutes (15 min slides + 20 min demo + 5 min Q&A)

---

## SLIDE 1 — Event Title (30 sec)

**DISCOVER AI — Explore Your Potential With the AI Data Cloud**

*This is the event-wide title slide. Let it display while attendees settle in.*

"Welcome everyone to DISCOVER AI. We've got 24 sessions across 5 days — and this one is specifically for data engineers who want to see what's possible when you pair AI with Snowflake's native tooling."

---

## SLIDE 2 — Session Title & Speaker (1 min)

**"Getting Started with Snowflake CoCo for Data Engineers"**  
**Chuang Zhu** — Solution Engineering Manager, Snowflake

"I'm Chuang Zhu, Solution Engineering Manager at Snowflake. Today I'm going to show you something that I think is going to fundamentally change how data engineers work on Snowflake. We're going to look at Cortex Code — which we call CoCo — Snowflake's native AI coding agent, and specifically how it accelerates the data engineering lifecycle. By the end of this session, you'll see me build an entire medallion architecture pipeline from scratch, using nothing but natural language prompts."

---

## SLIDE 3 — Safe Harbor and Disclaimers (30 sec)

*Quick acknowledgment, don't read it verbatim.*

"Standard safe harbor applies — what I show today reflects current capabilities and general product direction. Please refer to the slide for the full disclaimer. Let's get into it."

---

## SLIDE 4 — But Current Tools Weren't Built For Data Teams (2 min)

"Let's set the stage. Many of you have probably tried general-purpose AI coding tools — GitHub Copilot, Cursor, and others. They're great for application developers, but they have three fundamental gaps for data teams:

**First, they're built mainly for coding tasks.** They understand Python and JavaScript, but they don't understand pipelines, transformations, or how to build a data agent. They can't generate a dbt project or set up Snowpipe.

**Second, context stops at the repo.** They can see your local files, but they have zero awareness of your data catalog, your Snowflake warehouse, your table schemas, or your governance policies. They're blind to your actual data environment.

**Third, data leaves your secure environment.** When you use a generic tool, your code context — which often contains table names, schema designs, and business logic — gets sent to third-party services outside your security perimeter.

These aren't minor inconveniences. For data engineers working with sensitive data and complex infrastructure, these are dealbreakers."

---

## SLIDE 5 — For Data Teams on Snowflake, The Right Tool... (2 min)

"So what does the right tool look like? It needs four qualities:

**Understands Snowflake** — It has the latest knowledge of your specific data catalog: databases, schemas, tables, semantic models and more.

**Is Context Aware** — It knows all the data you're working with, retains your conversational history, and where you are in the UI as you navigate.

**Automates Complex Tasks** — It intelligently optimizes your requests to solve real jobs, from building an application to managing cost or governing data.

**Is Secure by Design** — It adheres to Snowflake RBAC, ensuring it only sees and acts on the data and objects you have access to.

That tool is Cortex Code."

---

## SLIDE 6 — Introducing Cortex Code (2 min)

"Cortex Code is Snowflake's native AI coding agent, purpose-built for data teams.

It **accelerates end-to-end development** — streamline the entire data lifecycle by using natural language to automate data engineering, machine learning, and agent building tasks. Instead of writing hundreds of lines of SQL and YAML by hand, you describe what you want.

It **understands your enterprise data context** — it's deeply aware of your Snowflake data, compute, governance, and operational semantics empowering everyone from data dabblers to domain experts.

And it's **open, extensible, and enterprise-ready**. It operates on secure Snowflake data and leverages RBAC; natively supports MCP, agents.md, and Agent Skills with access to frontier models like Claude Opus 4.6 & Sonnet 4.6, and GPT 5.2.

You can use it in Snowsight — the web UI — or as a CLI tool in your terminal. Today's demo will use the CLI, because that's where data engineers live."

---

## SLIDE 7 — What Can You Do with Cortex Code? (2 min)

"The use cases are broad, but let me highlight what matters most for this audience:

**Data Discovery** — search the catalog for data, with or without semantic views. Find the tables you need without writing INFORMATION_SCHEMA queries.

**Build AI Agents** — generate realistic synthetic data and create backend logic for agents.

**Create, Manage & Optimize** — this is the big one for today. Agentic data engineering with support for dbt and Apache Airflow. Build pipelines, manage schemas, orchestrate tasks.

**Admin Tasks** — manage access, cost & usage policies, and permissions.

**Analytics & Apps** — Streamlit, Notebook, Data engineering and pipelines.

**Code Migration & Refactoring** — convert code/pipelines from other platforms to Snowflake.

...and much much more!

Today we're going to focus on that highlighted box — **Create, Manage & Optimize** — and build a complete data engineering pipeline from scratch."

---

## SLIDE 8 — Why Data Engineers Need Cortex Code (3 min)

Let me frame why this matters with the challenges I hear from every data engineering team:

    Pipeline development is slow. You're writing hundreds of lines of SQL, YAML, and DDL by hand. You're context-switching between Snowflake docs, AWS console, dbt documentation, and your IDE. You're writing repetitive boilerplate for tables, pipes, streams, and tasks.

    Quality and governance are afterthoughts. DMFs, tests, and tags get added late — or never. There are no validation gates between medallion layers. PII columns go untagged and quality goes unchecked.

    Debugging and optimization take too long. Diagnosing failing tasks, broken pipes, and stale streams requires deep platform expertise. You're manually querying ACCOUNT_USAGE views for root cause. Warehouse tuning is a specialist skill.

    Now look at the right column — the Cortex Code advantage:

    Accelerated pipeline generation — full medallion pipelines from a single prompt. Auto-generates Bronze tables, Snowpipe, Streams, Tasks. Produces dbt models with tests and schema.yml included.

    Built-in quality and governance — it attaches DMFs, creates validation gate procedures, applies governance tags and propagates them across layers, and generates Snowpark Python stored procedures for profiling and anomaly detection.

    Intelligent debugging and optimization — diagnoses task failures, pipe issues, and stream lag. Queries system views and explains root cause in plain English. Recommends warehouse sizing and query optimizations.


---

## SLIDE 9 — Architecture Overview (2 min)

*Show this slide as you transition to the live demo to set expectations.*

"Before I jump into the terminal, let me show you what we're going to build. This is the architecture we'll have at the end:

- **Data Sources**: CSV files in an AWS S3 bucket — customers, orders, order items, products, payments, and shipments
- **RAW/Bronze layer**: Snowpipe Services ingestion into 6 landing tables with Tables
- **Silver layer**: dbt staging models for aggregation using Streams & Tasks, plus Join & Transformation via Serverless Tasks and SnowPark
- **Gold layer**: dbt dimensional models and optimized views, with a Streamlit dashboard on top
- **Anomaly Detection**: Python Stored Procedures and UDFs for data quality checks

Underneath it all:
- **Orchestration**: Tasks (5-Step DAG) | CDC Streams (6) | Stored Procedures | Snowpark Python (3 SPs)
- **Governance**: 5 Tag Types | 19 Tagged Tables | PII Classification | Quality Tiers | Tag Propagation (B→S→G)
- **Data Quality**: 32 DMFs (System + Custom) | 3 Validation Gates | dbt Tests | Snowpark Anomaly Detection

That's a lot of infrastructure. In a traditional workflow, this would be days of work. I'm going to build the foundational layers in about 20 minutes using Cortex Code.

But first — let me explain the tool that manages our Bronze infrastructure layer."

---

## SLIDE 10 — Snowflake DCM Projects (2.5 min)

Before I start building, I want to introduce DCM — Database Change Management. This is a key part of the demo you're about to see.

What is it? 
Infrastructure-as-code with declarative SQL definitions. You write DEFINE TABLE, DEFINE SCHEMA, DEFINE FUNCTION — and DCM translates those into the appropriate CREATE, ALTER, or DROP statements at deploy time. It's like Terraform, but native to Snowflake and purpose-built for data teams.

Why use it?
All infrastructure is defined as code, versioned in git
You can test changes before deploying to production — DCM has a PLAN phase that shows you what will change

You can preview exactly what will happen with each deployment
It manages different environments (dev, staging, prod) from a single template

It's natively integrated with Snowflake — leverages RBAC, works with Cortex Code, the Snow CLI, and Workspaces

How does it work? You create a schema-level DCM Project object. Your definitions go in SQL files. When you run snow dcm deploy, it executes a PLAN to diff your definitions against the current state, then DEPLOY to apply the changes. The diagram on the right shows this flow: DEFINE statements go in, PLAN validates, DEPLOY executes the ALTER/CREATE/DROP statements needed.
In our demo, DCM will manage the Bronze layer — tables, file formats, procedures, tags, and tasks. The dbt project handles Silver and Gold transformations separately. This is a deliberate architecture choice: infrastructure and transformations have different lifecycles and different tools are best suited for each."


*This slide bridges the architecture overview into the demo by explaining the "how" of infrastructure management.*

"Before I start building, I want to introduce **DCM — Database Change Management**. This is a key part of the demo you're about to see.

**What is it?**
- Infrastructure-as-code with declarative SQL definitions (DEFINE statements, translated internally to CREATE or ALTER statements)
- Parameterized infrastructure templates for large organizations or asset bundles for data products / pipelines
- A CI/CD solution for deploying changes to Snowflake

**Why use it?**
- Keep all infrastructure defined as code - versioned in git
- Test infrastructure changes before deploying them to production
- Preview what will change with each deployment
- Easily manage different environments
- Natively integrated in Snowflake (leveraging RBAC, Cortex Code, snowCLI, Workspaces, etc)

**How to use it?**
- Create a schema-level "DCM Project" object that can be executed to PLAN and DEPLOY these definitions to a target environment
- Flexibly organize your object definitions in SQL files
- Define your target environments and values for templating variables in a project manifest.yml
- Let Cortex migrate your existing infrastructure or create, debug and extend new data product with you

The diagram shows the flow: DEFINE statements go in → PLAN validates → DEPLOY executes the ALTER/CREATE/DROP statements needed.

In our demo, DCM will manage the Bronze layer — tables, file formats, procedures, tags, and tasks. The dbt project handles Silver and Gold transformations separately. This is a deliberate architecture choice: infrastructure and transformations have different lifecycles and different tools are best suited for each.

Let me show you."

---

## LIVE DEMO (20 min)

### Demo Part 1: Foundation & DCM for Bronze (~10 min)

**What you'll show:** Prompts 1-5 from agents.md — foundation setup, S3 integration, Bronze tables via DCM, Snowpipe, and CDC Streams.

**Talking points as you type/run:**

"I'm going to use the Cortex Code CLI. The first thing I'll do is give it my project instructions via an `agents.md` file — this tells Cortex Code about our dataset, our architecture decisions, and what we're building. Think of it as the AI equivalent of a design doc.

Now I'll prompt it to set up our foundation..."

**Prompt 1 (Foundation + DCM):**

"Watch what happens — it's creating a Snowflake database with our four schemas, and critically, it's setting up a **DCM project**. DCM — Database Change Management — is Snowflake's native way to declaratively manage infrastructure objects. Think of it like Terraform, but for Snowflake. Tables, file formats, tags, tasks — all defined in SQL definition files, version-controlled, and deployed with `snow dcm deploy`.

This is important: the Bronze layer — raw landing tables, file formats, ingestion infrastructure — is managed by DCM. It's infrastructure. It changes infrequently but needs to be reproducible and auditable."

**Prompt 3 (Bronze tables via DCM):**

"Now I'm asking it to create the 6 Bronze landing tables. Notice it's writing these as DCM definition files — `bronze_tables.sql` — and deploying them with the Snowflake CLI. Change tracking is enabled, data metric schedules are set. Everything is declarative and version-controlled."

**Prompts 4-5 (Snowpipe + Streams):**

"Snowpipe for auto-ingestion, CDC streams for change capture — these are the event-driven mechanisms that will trigger our pipeline. The streams are set to capture existing rows so we can process the initial load."

---

### Demo Part 2: dbt for Silver & Gold Transformations (~10 min)

**What you'll show:** Prompt 6 (dbt project generation) and Prompt 7 (deploy to Snowflake).

**Transition talking point:**

"Now here's where the second tool comes in — **dbt**. Why dbt for Silver and Gold instead of DCM? Because transformations are fundamentally different from infrastructure.

DCM is perfect for declaring 'these objects should exist with these properties.' But transformations are about *logic* — cleaning nulls, standardizing formats, computing derived columns, building dimensional models. dbt gives us:
- Modular SQL with refs and sources
- Built-in testing with schema.yml
- Lineage documentation
- Incremental materialization strategies

So our approach is a **hybrid**: DCM manages the infrastructure layer (Bronze), dbt manages the transformation layers (Silver and Gold). This maps naturally to how most teams already think about their pipeline."

**Prompt 6 (dbt generation):**

"One prompt — and watch what it generates:
- 6 Silver staging models with data cleaning, null handling, format standardization, and derived columns like customer tenure, order day-of-week, delivery speed classification
- 7 Gold analytics models — customer dimension with loyalty tiers, product dimension with performance tiers, date dimension, sales fact, daily revenue fact, payment summary, shipment performance
- Comprehensive schema.yml with unique tests, not-null tests, relationship tests, and accepted-values tests

This would typically take a data engineer a couple of days of focused work. Cortex Code generated it with awareness of the upstream Bronze schema, Snowflake best practices, and dbt conventions."

**Prompt 7 (Deploy):**

"Now I deploy it as a native dbt project object in Snowflake and execute it. The Silver and Gold tables materialize. The lineage is captured. The tests run."

---

### Demo Wrap-Up

"So what you just saw: in about 20 minutes, we went from an empty Snowflake account to a production-ready medallion architecture with:
- DCM-managed Bronze infrastructure
- dbt-powered Silver and Gold transformations
- CDC-driven ingestion
- All wired together and ready for the orchestration, governance, and quality layers that I showed in the architecture slide.

The key insight: Cortex Code didn't just write code for us. It *understood our platform*. It knew when to use DCM vs. dbt. It knew how to configure Snowpipe patterns. It knew how to structure a dbt project with proper tests. That's the difference between a generic AI tool and one built for data teams on Snowflake."

---

## SLIDE 11 — Thank You / Q&A (5 min)

"That's the demo. Let me summarize what we covered:

1. **The problem**: generic AI tools don't understand data platforms, data context, or data security
2. **The solution**: Cortex Code — purpose-built for data teams on Snowflake, with intelligence, relevance, efficiency, and governance
3. **The proof**: we built a complete medallion architecture pipeline — DCM for infrastructure, dbt for transformations — from natural language prompts in one session

If you're a data engineer on Snowflake, Cortex Code is available today. You can access it in Snowsight or install the CLI. The `agents.md` file I used is in our demo repo and you can replicate this entire pipeline yourself.

I'm happy to take questions."

---

## Timing Summary

| Section | Duration |
|---------|----------|
| Slide 1: Event Title | 0.5 min |
| Slide 2: Session Title & Speaker | 1 min |
| Slide 3: Safe Harbor | 0.5 min |
| Slide 4: Current Tools Gap | 2 min |
| Slide 5: Right Tool Qualities | 2 min |
| Slide 6: Introducing Cortex Code | 2 min |
| Slide 7: What Can You Do | 2 min |
| Slide 8: Why DE Need It | 3 min |
| Slide 9: Architecture Overview | 2 min |
| Slide 10: Snowflake DCM Projects | 2.5 min |
| **Demo Part 1: DCM + Bronze** | **10 min** |
| **Demo Part 2: dbt + Silver/Gold** | **10 min** |
| Slide 11: Thank You + Q&A | 3 min |
| **Total** | **~41 min** |

---

## Key Narrative Threads

1. **Hybrid approach**: DCM for infrastructure (Bronze), dbt for transformations (Silver/Gold) — each tool in its sweet spot
2. **Not just code generation**: Cortex Code understands the *platform* — RBAC, catalog, governance, orchestration primitives
3. **Security posture**: Data never leaves Snowflake, RBAC is respected, no third-party data leakage
4. **Practical acceleration**: What takes days is done in minutes — and with quality/governance baked in from the start, not bolted on later

---

## APPENDIX — DCM Key Use Cases (use for Q&A if asked)

*Jump to this if asked: "What else can DCM manage beyond tables?"*

"DCM covers four key areas:

**DCM for Managing Infrastructure** — Programmatically define and deploy databases, schemas, warehouses, roles, and grants for large organizations. Use Jinja templates and macros to maintain one template for multiple teams — change it in one place and apply it everywhere. List all teams and their configurations in a single file.

**DCM for Data Pipelines** — Build, test, and deploy transformation pipelines using Dynamic Tables, Task Graphs, or dbt Projects. Version pipeline definitions as code and parameterize deployments to multiple environments. Clone existing pipelines into a dev-sandbox to iterate and test changes safely with real data before deployment.

**DCM for Data Governance** — Full audit trail for all infrastructure changes managed by DCM. Manage grants programmatically at scale. Define data quality gates for your deployment pipelines. Drift detection: automatically detect and alert on changes in role privileges or when expectations are violated.

**DCM for ML Infrastructure & AI Projects** *(coming soon)* — Build, test, and deploy Feature Stores, Semantic Views, Models, and Agents. Version your AI/ML in code and parameterize deployments to multiple environments. Clone existing Semantic Views, Models, and Agents into a dev-sandbox to test changes safely before deployment."
