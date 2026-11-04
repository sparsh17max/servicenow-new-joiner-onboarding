# New Joiner Onboarding Orchestrator (NJO) — ServiceNow

A **ServiceNow scoped application** that turns a hiring manager's single Service Portal request into coordinated onboarding work for **HR, IT, Facilities and L&D**, with SLAs, role-based access and a cross-app integration that enrols every new joiner in mandatory Security Awareness training in the [Employee Training and Certification Management (ETCMS)](https://github.com/sparsh17max/servicenow-employee-training-management) application.

Built **without code** — a CSA-focused project: Service Catalog, Flow Designer, Users/Groups/Roles, ACLs, SLA Definitions, Import Sets, Reports and Update Sets are all configuration. There are no scripts: even the hiring-manager ACL, where a one-line `gs.getUserID()` condition is the usual answer, uses the condition builder's *is (dynamic) Me*.

- **Instance:** ServiceNow PDI (Zurich), branded for the fictional company *Novatrix Solutions*
- **Scope:** `x_2186817_njo`
- **Author:** Sparsh Varde

## Business scenario
When Novatrix hires someone, four teams each have to act before day one. Today the hiring manager chases them by email; joiners arrive without a login or a desk and nobody knows how long onboarding takes. NJO gives the request one record, fans it out into owned and timed tasks, and shows the state of every onboarding on a dashboard.

## Data model
| Table | Purpose |
|-------|---------|
| **Onboarding Case** `x_2186817_njo_onboarding_case` | One per new joiner — the container (`NJO0001001…`) |
| **Onboarding Task** `x_2186817_njo_onboarding_task` — *extends Task* | One per team action (`NJOT0001001…`); inherits State, Assignment group, SLA support |

Why the task extends Task but the case does not, and every field, is in [docs/data-dictionary.md](docs/data-dictionary.md).

## Progress
| Phase | Scope | Status |
|-------|-------|--------|
| 1 | Application, tables, groups, roles | ✅ Complete — TC-01…03 passed |
| 2 | Service Catalog item, variable set, Knowledge | ✅ Complete — TC-04…06 passed |
| 3 | Flow Designer orchestration + ETCMS integration | ✅ Complete — TC-07…11 passed (ETCMS writes run in ETCMS-scoped subflows) |
| 4 | SLAs, notifications, ACLs | ✅ Complete — TC-12…16 passed (no-script ACLs) |
| 5 | Import Set, dashboard, Update Set export, portfolio docs | 🟡 In progress — TC-17, TC-18 passed; Update Set export and portfolio pending |

## Screenshots
| | |
|---|---|
| ![Case created](screenshots/tc01-case-created-njo-number.jpg) | ![Related list](screenshots/case-related-list-onboarding-tasks.jpg) |
| Onboarding Case with auto-number and default stage | Onboarding Tasks related list on the case |
| ![Extends Task](screenshots/onboarding-task-extends-task.jpg) | ![Inherited roles](screenshots/tc03-inherited-roles.jpg) |
| Onboarding Task extends Task | Roles inherited through groups |
| ![Portal item](screenshots/tc04-portal-item-david-miller.jpg) | ![UI policy](screenshots/catalog-ui-policy-equipment-none.jpg) |
| *Onboard a New Joiner* on the Service Portal | No-code catalog UI policy message |
| ![RITM variables](screenshots/tc05-ritm-variables.jpg) | ![KB article](screenshots/tc06-kb-article-on-portal.jpg) |
| RITM with the variable set values | *Your first week at Novatrix* on the portal |
| ![Flow 1 execution](screenshots/tc07-flow1-execution-ld-try.jpg) | ![ETCMS subflow](screenshots/etcms-subflow-enroll-in-security-awareness.jpg) |
| Flow 1 run: the L&D path calls the ETCMS subflow inside Try | ETCMS-scoped subflow *Enroll in Security Awareness* |
| ![Ready for Day One](screenshots/tc10-case-ready-for-day-one.jpg) | ![ETCMS session](screenshots/tc11-etcms-session-enrollments.jpg) |
| Case Ready for Day One, all six tasks closed | New joiners in the ETCMS Security Awareness session |
| ![Task SLAs](screenshots/tc12-it-account-task-slas.jpg) | ![SLA emails](screenshots/tc13-sla-warning-and-breach-emails.jpg) |
| Business-hours SLAs on an onboarding task | SLA 75% warning and breach emails from the SLA flow |
| ![David Miller's cases](screenshots/tc14-david-miller-case-list.jpg) | ![No Joiner Email](screenshots/tc16-david-miller-case-no-joiner-email.jpg) |
| Row ACL: a hiring manager sees only their own cases | Field ACL: Joiner Email hidden from hiring managers |

## Documentation
- [Development log](docs/development-log.md) — what / why / learned for each step, with issue tables
- [Test cases](docs/test-cases.md) — TC-01…TC-19
- [Data dictionary](docs/data-dictionary.md)
- [Changelog](CHANGELOG.md)
- [Project guide](docs/PROJECT-GUIDE.md)

## How this was built
Configuration was applied as Table API records from a local shell (session auth, see [scripts/README.md](scripts/README.md)) with the session scoped to the application and the *NJO v1.0* update set; tests and screenshots were done in the browser.
