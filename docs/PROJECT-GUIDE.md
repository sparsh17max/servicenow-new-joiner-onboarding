# ServiceNow Portfolio Project 3: New Joiner Onboarding Orchestrator (NJO)

**Portfolio project — CSA-focused (configuration, no scripting)**

Built in the same PDI (`dev407572`, branded Novatrix Solutions) as a **second scoped application** that integrates with ETCMS. Everything in this guide is configurable without code; the few places where a script *could* be used are called out with the no-code alternative, which is the one to use.

---

## 1. Project overview

### Business scenario
When Novatrix hires someone, four teams must each do their part before day one: **HR** (contract, policy sign-off), **IT** (accounts, laptop), **Facilities** (desk, access badge) and **L&D** (mandatory Security Awareness training — which lives in ETCMS). Today the hiring manager chases each team by email. New joiners regularly arrive without a login or a desk, and nobody can say how long onboarding takes.

### Objectives
| Objective | What the application will do |
|-----------|------------------------------|
| Self-service request | A hiring manager raises one catalog request on the Service Portal |
| Task orchestration | The request fans out into tasks for HR, IT, Facilities and L&D |
| Accountability | Each task has an SLA and an owning group; breaches notify the group manager |
| Cross-app integration | The L&D task auto-enrols the joiner in ETCMS's Security Awareness session |
| Visibility | A dashboard shows onboardings in flight, overdue tasks by team and time-to-ready |
| Governance | Role-based access (ACLs), bulk import of joiners, everything captured in an Update Set |

### CSA exam topics this project covers
Service Catalog & variables · Flow Designer (no-code) · Users, Groups, Roles · ACLs · SLA Definitions · Import Sets & Transform Maps · Knowledge · Notifications · Reports & Dashboards · Update Sets · Service Portal

---

## 2. Application architecture

Two custom tables plus references to platform tables.

| Table | Purpose | Key references |
|-------|---------|----------------|
| **Onboarding Case** `[onboarding_case]` | One per new joiner — the parent record | Hiring Manager → `sys_user`, Department → `cmn_department`, Location → `cmn_location` |
| **Onboarding Task** `[onboarding_task]` extends **Task** `[task]` | One per team action — inherits Number, State, Assignment group, Assigned to, SLA support | Onboarding Case → `onboarding_case` |

**Design decisions to document**
- Onboarding Task **extends Task** rather than being a standalone table: that is what gives it SLAs, assignment, approvals and the standard task states for free. (Interviewers ask about this.)
- Onboarding Case does **not** extend Task — it is a container, not a work item; keeping it separate avoids SLAs firing on the parent.
- The new joiner's **User record is created by the flow** (IT's job), so the case stores name/email as text until then, plus a reference field that is filled once the user exists.

### Relationships
| Parent | Child | Relationship |
|--------|-------|--------------|
| Onboarding Case | Onboarding Task | One-to-many |
| sys_user (Hiring Manager) | Onboarding Case | One-to-many |
| Onboarding Case | ETCMS Course Enrollment | One-to-one (created by the flow) |

---

## 3. Roadmap

| Phase | Scope | Difficulty |
|-------|-------|------------|
| 1 | Application, tables, groups, roles | Beginner |
| 2 | Service Catalog item + variables + Knowledge | Beginner |
| 3 | Flow Designer orchestration + ETCMS integration | Intermediate |
| 4 | SLAs, notifications, ACLs | Intermediate |
| 5 | Import Set, reports/dashboard, Update Set export, portfolio docs | Intermediate |

Complete each phase and its test cases before the next. Documentation (dev log, test cases, changelog, Notion) is updated at the end of every step, not at the end of the project.

---

# Phase 1: Application and data model

## Step 1. Create the scoped application
App Engine Studio → Create app.

| Field | Value |
|-------|-------|
| Name | New Joiner Onboarding |
| Description | Self-service onboarding requests that orchestrate HR, IT, Facilities and L&D tasks for new joiners. |
| Roles | keep defaults (`admin`, `user`) |

Note the scope prefix (`x_<id>_new_joiner` or similar) — every table below is prefixed with it.

## Step 2. Create groups and roles (Users, Groups, Roles — CSA core)
**Groups** (`sys_user_group`), each with a manager and 2–3 demo users as members:

| Group | Manager (demo user) | Members |
|-------|---------------------|---------|
| Onboarding - HR | Beth Anglin | Carol Coughlin, Christen Mitchell |
| Onboarding - IT | Fred Luddy | Abel Tuter, David Loo |
| Onboarding - Facilities | Bow Ruggeri | Rick Berzle, Luke Wilson |
| Onboarding - L&D | Bow Ruggeri | Eric Schroeder |

**Roles** (in the app scope):

| Role | Granted to | Purpose |
|------|-----------|---------|
| `njo.hiring_manager` | a "Hiring Managers" group (add David Miller, Jerrod Bennett) | Can raise requests and see their own cases |
| `njo.fulfiller` | the four Onboarding groups | Can work tasks assigned to their group |
| `njo.coordinator` | Beth Anglin | Sees everything, runs reports |

Document: role inheritance (group → role → user), and that `admin` already contains everything.

## Step 3. Create the Onboarding Case table
| Field label | Type | Configuration |
|-------------|------|---------------|
| Number | String | Auto-number, prefix `NJO`, **display field** |
| Joiner Name | String (100) | Mandatory |
| Joiner Email | Email | Personal email used before the corporate account exists |
| Start Date | Date | Mandatory |
| Job Title | String (100) | |
| Department | Reference → Department `[cmn_department]` | |
| Location | Reference → Location `[cmn_location]` | |
| Hiring Manager | Reference → User `[sys_user]` | Defaults to the requester |
| Equipment Needed | Choice | laptop_standard, laptop_developer, desktop, none |
| Needs Desk | True/False | Default true |
| Needs Security Training | True/False | Default true |
| Joiner User Account | Reference → User `[sys_user]` | Filled by the flow once IT creates the account |
| Stage | Choice | requested, in_progress, ready_for_day_one, closed, cancelled — default `requested` |
| Ready Date | Date/Time | Set by the flow when all tasks close |
| Notes | String (4000) | |

## Step 4. Create the Onboarding Task table — **extends Task**
Create the table with **Extends table = Task [task]**. Inherited: Number (set prefix `NJOT`), Short description, Description, State, Priority, Assignment group, Assigned to, Opened, Closed, Work notes, SLA support.

Add only:
| Field label | Type | Configuration |
|-------------|------|---------------|
| Onboarding Case | Reference → Onboarding Case | Mandatory |
| Task Type | Choice | hr_paperwork, it_account, it_equipment, facilities_desk, facilities_badge, ld_training |
| Due Date | Date | Calculated by the flow from Start Date |

Add a **related list** "Onboarding Tasks" to the Onboarding Case form, configure both forms and lists (same approach as ETCMS Phase 2).

**Phase 1 test cases**
- TC-01 Create a case manually → NJO number assigned, Stage = Requested.
- TC-02 Create a task from the case's related list → Onboarding Case pre-populated, NJOT number assigned, State = Open.
- TC-03 Impersonate a member of Onboarding - IT → has `njo.fulfiller` via the group.

---

# Phase 2: Service Catalog and Knowledge

## Step 5. Catalog category and item
*Service Catalog → Catalog Definitions → Maintain Items → New.*

| Field | Value |
|-------|-------|
| Name | Onboard a New Joiner |
| Catalog | Service Catalog |
| Category | create **HR Services** |
| Short description | Request accounts, equipment, workspace and training for a new starter |
| Fulfilment | leave the workflow/flow empty for now — Phase 3 attaches the flow |
| Availability | Desktop + Service Portal |

## Step 6. Variables (mirror the case fields)
Use a **Variable Set** named *New Joiner Details* so it can be reused:

| Variable | Type | Notes |
|----------|------|-------|
| joiner_name | Single Line Text | mandatory |
| joiner_email | Email | mandatory |
| start_date | Date | mandatory |
| job_title | Single Line Text | |
| department | Reference → cmn_department | |
| location | Reference → cmn_location | |
| equipment | Select Box | same choices as the table |
| needs_desk | Checkbox | default checked |
| needs_training | Checkbox | default checked |
| notes | Multi Line Text | |

Add a **Catalog UI Policy**: when `equipment = none`, hide nothing but show an info message "No equipment task will be created." (demonstrates catalog UI policies without complexity).

## Step 7. Knowledge article
Create a Knowledge Base **HR Knowledge** and an article *"Your first week at Novatrix"* (what to expect, who to contact). Link it from the catalog item's description. Publish it.

**Phase 2 test cases**
- TC-04 Open the item on the Service Portal (`/sp`) as David Miller (hiring manager) → form renders with all variables; mandatory fields enforced.
- TC-05 Submit → a Requested Item (RITM) is created with the variable values. (No case yet — that's Phase 3.)
- TC-06 Knowledge article is visible on the portal and linked from the item.

---

# Phase 3: Flow Designer orchestration (no-code)

## Step 8. The main flow — "NJO Onboarding Orchestration"
Trigger: **Service Catalog** (runs when the item is requested).

Steps, all standard actions:
1. **Get Catalog Variables** from the RITM.
2. **Create Record** → Onboarding Case, mapping the variables; Hiring Manager = RITM ▸ Requested for; Stage = In Progress.
3. **Update Record** on the RITM: link it to the case (add a reference field *Onboarding Case* on `sc_req_item` or just put the case number in the RITM comments).
4. **Create Record** × tasks, each an Onboarding Task with Assignment group, Task Type, Short description, Due Date = Start Date minus N days:
   - HR paperwork → Onboarding - HR, due Start − 5
   - IT account → Onboarding - IT, due Start − 2
   - IT equipment → Onboarding - IT, due Start − 3 — **only if** equipment ≠ none (use an *If* step)
   - Facilities desk → Facilities, due Start − 1 — only if Needs Desk
   - Facilities badge → Facilities, due Start − 1
   - L&D training → Onboarding - L&D, due Start + 5 — only if Needs Security Training
5. **ETCMS integration** (inside the L&D branch): **Create Record** on `x_2186817_employ_0_course_enrollment` — Employee = Joiner User Account *if set, else leave empty and add a work note*, Training Session = *Look Up Record*: Training Session where Course = "Information Security Awareness" and Session Status = Open/Planned, earliest Start Date. Enrollment Status = Enrolled.
   - Cross-scope note: the ETCMS table must allow create from other scopes (Application Access → "Can create" from other application scopes). Document this — it is a CSA topic.
6. **Wait for condition** → all Onboarding Tasks for this case are Closed Complete.
7. **Update Record** → Case Stage = Ready for Day One, Ready Date = now.
8. **Send Email** → Hiring Manager: "Everything is ready for {Joiner Name} on {Start Date}".

## Step 9. The IT account sub-step (no-code)
When the *IT account* task closes, a second small flow (trigger: Onboarding Task updated, Task Type = it_account, State = Closed Complete) **creates the sys_user** record (user_name from email, name, department, manager = Hiring Manager) and **updates the case's Joiner User Account**. Then it **updates the ETCMS enrollment** created earlier to set Employee. (Two flows instead of one keeps each simple — document why.)

**Phase 3 test cases**
- TC-07 Submit the catalog item for "Priya Nair", start in 10 days, developer laptop, desk, training → case created, 6 tasks created with the right groups and due dates.
- TC-08 Same with equipment = none and no desk → 4 tasks.
- TC-09 Close the IT account task → sys_user "priya.nair" exists; case Joiner User Account set; ETCMS enrollment now has Employee = Priya Nair.
- TC-10 Close all tasks → Stage = Ready for Day One, Ready Date set, email in outbox to the hiring manager.
- TC-11 Open the Novatrix ETCMS Security Awareness session → Priya appears in its enrollment related list (cross-app proof).

---

# Phase 4: SLAs, notifications, ACLs

## Step 10. SLA Definitions (`contract_sla`) on Onboarding Task
| SLA | Start | Duration | Stop |
|-----|-------|----------|------|
| IT account creation | Task Type = it_account, State = Open | 2 business days (8–5 weekdays schedule) | State = Closed Complete |
| Equipment ready | Task Type = it_equipment | 3 business days | same |
| Desk & badge | Task Type in facilities_* | 2 business days | same |
| HR paperwork | Task Type = hr_paperwork | 3 business days | same |

Add the **Task SLAs** related list to the task form. Show the SLA timers on the list (`task_sla` → Business time left).

## Step 11. Notifications
1. *Task assigned to your group* — to the group, on insert.
2. *SLA at 75%* — to Assignment group manager (use the SLA definition's warning/breach notification options).
3. *SLA breached* — to the group manager and the Coordinator.
4. *Day-one ready* — already sent by the flow; document it here as the fourth.

## Step 12. ACLs (the CSA topic to showcase)
Table-level ACLs in the app scope:

| Table | Operation | Who | Condition |
|-------|-----------|-----|-----------|
| onboarding_case | read | `njo.hiring_manager` | Hiring Manager is the logged-in user (`hiring_manager=javascript:gs.getUserID()` — this is the one place a one-line script is standard; the no-code alternative is a **query business rule**… which is also a script. Use the condition and explain it.) |
| onboarding_case | read | `njo.coordinator`, `njo.fulfiller` | none |
| onboarding_case | write | `njo.coordinator` | none |
| onboarding_task | read/write | `njo.fulfiller` | Assignment group is one of my groups (*condition builder: Assignment group · is (dynamic) · One of My Groups*) |
| onboarding_task | read | `njo.hiring_manager` | Onboarding Case ▸ Hiring Manager = me |
| onboarding_case.joiner_email | read | `njo.coordinator`, `njo.fulfiller` | field-level ACL: hiring managers can't see other joiners' emails |

Test with **Impersonate**: David Miller sees only his cases; Abel Tuter sees only IT tasks; Beth sees all.

**Phase 4 test cases**
- TC-12 Open an IT account task → SLA "IT account creation" attached, timer counting business hours.
- TC-13 Set the SLA to 100% via a short schedule in testing (or use a 10-minute test SLA) → breach notification in outbox.
- TC-14 Impersonate David Miller → only his cases listed; another manager's case gives "record not found".
- TC-15 Impersonate Abel Tuter → sees IT tasks, not HR tasks.
- TC-16 Hiring manager cannot see the Joiner Email column.

---

# Phase 5: Import, reporting, Update Set, portfolio

## Step 13. Import Set + Transform Map
Build a spreadsheet of 15 upcoming joiners (name, email, start date, department, title, equipment). *System Import Sets → Load Data* → create a transform map to **Onboarding Case** with field mapping, a **coalesce** on Joiner Email (so re-import updates rather than duplicates), and a choice mapping for Equipment. Run it twice to prove coalesce.

## Step 14. Reports and dashboard — "Onboarding Operations"
| Report | Table | Type |
|--------|-------|------|
| Onboardings by Stage | onboarding_case | Donut |
| Open tasks by Group | onboarding_task | Bar |
| SLA breaches by Group (last 30 days) | task_sla | Bar |
| Average days to Ready | onboarding_case | Single score (Ready Date − Opened) |
| Upcoming starts (next 30 days) | onboarding_case | List |

## Step 15. Update Set
Capture the *entire* application configuration in a named Update Set (*NJO v1.0*), complete it, and **export the XML** into the GitHub repo under `update-sets/`. Document what an update set does and does not capture (data records are not captured — the import set is how the demo data travels).

## Step 16. Portfolio
Same repo pattern as ETCMS: `README.md`, `docs/` (requirements, architecture, data dictionary, test-cases, development-log, sample-data), `screenshots/`, `update-sets/`, `CHANGELOG.md`. Add a short section in **both** READMEs that links the two projects ("NJO enrols joiners into ETCMS").

**Phase 5 test cases**
- TC-17 Import 15 rows → 15 cases; re-import with 2 changed rows → 2 updated, 0 duplicates.
- TC-18 Dashboard renders all five reports with live data.
- TC-19 Update Set XML exported and committed; preview on a fresh scope shows no errors.

---

## Appendix A — Sample data

**Joiners (for the import set and portal tests)**
| Name | Email | Start | Dept | Title | Equipment |
|------|-------|-------|------|-------|-----------|
| Priya Nair | priya.nair@example.com | +10 days | IT | Junior Developer | laptop_developer |
| Rohan Mehta | rohan.mehta@example.com | +14 days | Sales | Account Executive | laptop_standard |
| Ananya Iyer | ananya.iyer@example.com | +7 days | HR | HR Generalist | laptop_standard |
| Kabir Shah | kabir.shah@example.com | +21 days | Finance | Analyst | desktop |
| Meera Pillai | meera.pillai@example.com | +3 days | Marketing | Content Lead | laptop_standard |
| …10 more in `docs/sample-data.md` | | | | | |

**Fictional**: none of these are real people.

## Appendix B — Interview talking points this project earns you
- Why extend Task vs. a standalone table
- Group → role → user inheritance; what `admin` includes
- Row-level vs field-level ACLs; how ACL evaluation order works
- Catalog item vs record producer; variable sets
- SLA schedules and business time; when retroactive start applies
- Coalesce in transform maps
- What an update set captures (configuration) vs doesn't (data)
- Cross-scope access between two scoped apps
