# update-sets/

| File | What it is |
|------|------------|
| `NJO-v1.0.xml` | Update set **NJO v1.0**, state Complete, 179 customer updates, all in scope `x_2186817_njo` (exported 2026-11-04) |
| `par_dashboard_onboarding_operations.xml` | XML unload of the *Onboarding Operations* dashboard header record (see below) |

## Installing on another instance
Import each file with *System Update Sets → Retrieved Update Sets → Import Update Set from XML* → **Preview** → **Commit**, in this order:
1. **ETCMS full application:** [`ETCMS-v1.0-full-application.xml`](https://github.com/sparsh17max/servicenow-employee-training-management/blob/main/update-sets/ETCMS-v1.0-full-application.xml) (ETCMS repo, 202 updates).
2. **ETCMS v1.1:** [`ETCMS-v1.1-enrollment-date.xml`](https://github.com/sparsh17max/servicenow-employee-training-management/blob/main/update-sets/ETCMS-v1.1-enrollment-date.xml) (ETCMS repo). The full export already contains these two subflow versions, so this step changes nothing on a fresh install. It is kept in the sequence so the history is visible.
3. **NJO v1.0:** `NJO-v1.0.xml` (this folder).
4. *System Definition → Import XML* (on any list's context menu) → `par_dashboard_onboarding_operations.xml`.
5. Recreate the data listed below, or load the joiners with the import set (`docs/sample-data/joiners.xlsx`). ETCMS needs an *Information Security Awareness* course with a Planned or Open session (ETCMS `scripts/07-sample-data.js`).

## What an update set captures
It captures **configuration** (application files and records marked `update_synch`) made while the update set is current. For NJO that is:
- the application record, tables and dictionary, field labels, choices and numbering
- form, list and related-list layouts, the application menu and modules
- roles and contained roles, ACLs, and cross-scope privileges
- the catalog item, category, variable set, variables, question choices and UI policy
- the three flows, SLA definitions and notifications
- the knowledge base criteria and the portal link
- the import set table, transform map, field maps and data sources
- the reports, plus the dashboard's tab, canvas, widgets and permission

## What it does not capture
- **Data:** cases, tasks, requests, users, groups, group members and role grants, the KB, its category and the article, import set rows, and SLA instances. Data travels as an import (the joiners spreadsheet) or XML unloads, or is recreated by hand.
- **The `par_dashboard` header record:** Platform Analytics does not write it to the update set on this instance, although its children are captured. It is shipped separately as `par_dashboard_onboarding_operations.xml`.
- **Changes made through the Table API:** on this instance only UI saves (forms, lists, Form Designer, Workflow Studio) create update records. Configuration first created over REST was re-saved in the UI so that it was captured.
- **Changes in another scope:** the ETCMS subflows and the cross-scope access settings on Course Enrollment belong to ETCMS. They are in the ETCMS repo's update sets (full application and v1.1).

## Preview result (TC-19)
I loaded the exported XML back onto the source PDI as a Retrieved Update Set and previewed it: **179 total, 0 collisions, 0 preview problems**. It shows 177 updated and 2 deleted because the records already exist there. No second instance was available, so a preview on an instance without the scope has not been run.
