# Development Log

Format for each entry: **what** I implemented, **why**, and **what I learned**.

**Project rule (CSA focus):** everything is configured through the UI or as Table API records (tables, dictionary entries, choices, roles, groups, layouts, catalog items, flows, ACLs, SLA definitions, transform maps). No business rules, client scripts or script includes. The only script allowed is the one-line `gs.getUserID()` ACL condition in Phase 4. When a script would have been the obvious route, the no-code alternative is used and the reason is logged here under **No-code decision**.

**How the instance was changed:** Table API calls from this machine using session auth (`scripts/sn.sh`: POST `/login.do`, cookies, `g_ck` sent as `X-UserToken`), with the session's current application set to *New Joiner Onboarding* and the current update set set to *NJO v1.0*. The browser (Claude in Chrome) was used only to run test cases and take screenshots.

## 2026-11-03 — Phase 1, Step 1: Scoped application created
- **What:** Created the scoped application *New Joiner Onboarding*, scope **`x_2186817_njo`** (`sys_app` `a75b354293981f10803931697bba109e`), description "Self-service onboarding requests that orchestrate HR, IT, Facilities and L&D tasks for new joiners.", version 1.0.0. Added the two default App Engine Studio roles `x_2186817_njo.admin` and `x_2186817_njo.user` (admin contains user). Created the update set **NJO v1.0** in the app scope and made it the session's current update set before any further configuration, so Step 15 can export one complete set. Added an application menu *New Joiner Onboarding* with modules *Onboarding Cases*, *Onboarding Tasks* and *Open Onboarding Tasks* (`active=true`).
- **Why:** A second scoped application, separate from ETCMS (`x_2186817_employ_0`), keeps the two projects independently deployable and is the precondition for the cross-scope integration in Phase 3. A short scope suffix (`njo`) makes the role names read as the guide writes them (`x_2186817_njo.fulfiller` ≈ `njo.fulfiller`).
- **Learned:** A scoped app is a `sys_app` row; inserting it creates the matching `sys_scope` and a *Default [New Joiner Onboarding]* update set automatically. The scope name is limited to 18 characters, so AES would have shortened "new_joiner" — choosing the suffix explicitly avoids a random `_0` suffix. The session's application and update set are set with `PUT /api/now/ui/concoursepicker/application` and `/updateset`; every metadata record created afterwards carries `sys_scope = x_2186817_njo`.
- **Evidence:** `screenshots/onboarding-task-extends-task.jpg` (application banner shows *New Joiner Onboarding*)

## 2026-11-03 — Phase 1, Step 2: Groups and roles
- **What:**
  - Roles (app scope): `x_2186817_njo.hiring_manager`, `x_2186817_njo.fulfiller`, `x_2186817_njo.coordinator`, each **containing** `x_2186817_njo.user`.
  - Groups: *Onboarding - HR* (manager Beth Anglin; Carol Coughlin, Christen Mitchell), *Onboarding - IT* (Fred Luddy; Abel Tuter, David Loo), *Onboarding - Facilities* (Bow Ruggeri; Rick Berzle, Luke Wilson), *Onboarding - L&D* (Bow Ruggeri; Eric Schroeder), *Hiring Managers* (David Miller, Jerrod Bennett).
  - Role grants: `fulfiller` → the four Onboarding groups (`sys_group_has_role`); `hiring_manager` → *Hiring Managers*; `coordinator` → Beth Anglin directly (`sys_user_has_role`).
- **Why:** Roles are granted to groups, never to individual fulfillers, so joining or leaving a team is a single membership change. Only the coordinator is a named person, which is why that grant is direct.
- **Learned:** Inheritance is **group → role → contained role → user**. Adding a role to a group writes `sys_user_has_role` rows for every member with `inherited = true`; contained roles are expanded the same way (Abel Tuter gets `fulfiller` from *Onboarding - IT* and `user` because `fulfiller` contains it). Beth's direct grant shows `inherited = false`. The platform `admin` role passes every ACL on its own (ACL evaluation short-circuits for admin), so admins never need the app roles. Group managers are **not** members by default: Fred Luddy manages *Onboarding - IT* but does not inherit `fulfiller` — that matters for Phase 4 notifications (sent to the manager field) vs. ACLs (role-based).
- **Evidence:** `screenshots/groups-and-members.jpg`, `screenshots/tc03-inherited-roles.jpg`

## 2026-11-03 — Phase 1, Step 3: Onboarding Case table
- **What:** `x_2186817_njo_onboarding_case` (label *Onboarding Case*, not extensible, does **not** extend Task) with 15 fields: Number (auto-number `NJO0001001…`, display field, read-only), Joiner Name (String 100, mandatory), Joiner Email (Email), Start Date (Date, mandatory), Job Title (String 100), Department → `cmn_department`, Location → `cmn_location`, Hiring Manager → `sys_user`, Equipment Needed (choice: `laptop_standard`, `laptop_developer`, `desktop`, `none`), Needs Desk (True/False, default true), Needs Security Training (True/False, default true), Joiner User Account → `sys_user`, Stage (choice, dropdown without *-- None --*: `requested`, `in_progress`, `ready_for_day_one`, `closed`, `cancelled`, default `requested`), Ready Date (Date/Time), Notes (String 4000). Form in two columns (identity left, stage/logistics right, Notes full width) and a 7-column list.
- **Why:** The case is the container for one joiner. It deliberately does not extend Task: it is not a unit of work, and extending Task would let SLAs, assignment rules and the Task ACLs fire on the parent as well as on the six child tasks.
- **Learned:** A table is a `sys_db_object` row; inserting it creates the physical table and the `sys_*` system columns. Each field is a `sys_dictionary` row (plus an auto-created `sys_documentation` label). Auto-numbering is a `sys_number` row (`category` = table, prefix, starting number, digits) plus the Number field's default `javascript:global.getNextObjNumberPadded();` — the exact default the table form's *Auto-number* checkbox writes; it calls a platform function, nothing project-specific. Choice values live in `sys_choice`; unlike ETCMS (where a background script in the app scope was refused), creating them through the Table API with the session in the app scope works and keeps them in the app. `choice = 3` is *Dropdown without -- None --*, used for Stage so it can never be blank.
- **No-code decision:** The guide says Hiring Manager "defaults to the requester". A dictionary default for that is `javascript:gs.getUserID()`, a script. Left **without a default**: in production every case is created by the Phase 3 flow, which maps Hiring Manager from *RITM ▸ Requested for*; for manual cases the field is filled on the form.
- **Evidence:** `screenshots/tc01-case-created-njo-number.jpg`

## 2026-11-03 — Phase 1, Step 4: Onboarding Task table (extends Task)
- **What:** `x_2186817_njo_onboarding_task` (label *Onboarding Task*) with **Extends table = Task**, auto-number prefix `NJOT` (`sys_number`, `NJOT0001001…`). Added only Onboarding Case → `x_2186817_njo_onboarding_case` (mandatory) and Task Type (choice: `hr_paperwork`, `it_account`, `it_equipment`, `facilities_desk`, `facilities_badge`, `ld_training`). Form: Number, Onboarding Case, Task Type, Assignment group, Assigned to | State, Priority, Due date, Opened, Closed, then Short description, Description, Work notes. List: 8 columns. Related list **Onboarding Tasks** (`x_2186817_njo_onboarding_task.onboarding_case`) on the Onboarding Case form.
- **Why:** Extending Task gives Number, State, Priority, Assignment group, Assigned to, Opened/Closed, Work notes, approvals, the Task SLA engine and the `task` ACLs for free — 71 inherited columns versus 3 added. Those are exactly what Phase 4 needs (SLA definitions only target tables in the Task hierarchy).
- **Learned:** Setting `super_class` on `sys_db_object` is all "extends" means — the child gets every parent column and the parent's number field, and only the `sys_number` row with the child table as category gives it its own prefix (without it, tasks would be numbered `TASK…`). Records of the child also appear in the `task` table.
- **Design decision — Due Date:** Task already has **Due date** (`due_date`, Date/Time). The guide asks to add a Due Date (Date) field; adding a second column with the same meaning would duplicate data and confuse reports, so the inherited `due_date` is reused. The flow will set it to the target day at 09:00.
- **Tested:** see below.
- **Evidence:** `screenshots/onboarding-task-extends-task.jpg`, `screenshots/tc02-task-from-related-list.jpg`, `screenshots/case-related-list-onboarding-tasks.jpg`

## 2026-11-03 — Phase 1 test cases (TC-01 to TC-03, all passed)
- **TC-01:** New Onboarding Case form → Number pre-filled **NJO0001001**, Stage **Requested**. Saved a case for Ananya Iyer (HR Generalist, HR, start 2026-11-10, Standard laptop, hiring manager David Miller).
- **TC-02:** On NJO0001001, *Onboarding Tasks* related list → **New** → Onboarding Case pre-populated **NJO0001001**, Number **NJOT0001001**, State **Open**. Saved as an HR paperwork task for *Onboarding - HR*, due 2026-11-05 09:00; it appears in the case's related list.
- **TC-03:** Impersonated Abel Tuter (member of *Onboarding - IT*) with `POST /api/now/ui/impersonate/<sys_id>`; the session's active roles were `x_2186817_njo.fulfiller` and `x_2186817_njo.user` — granted through the group, not to Abel directly. Impersonation ended by impersonating the admin sys_id. The User Roles list confirms `inherited = true` for every group-granted role and `false` for Beth's direct coordinator grant.

| Date | Issue | Resolution | Learning |
|------|-------|------------|----------|
| 2026-11-03 | Session-auth helper reported "login FAILED" although `/login.do` returned 302 | `navpage.do` now redirects to the Next Experience shell, which has no `g_ck`; read `g_ck` from a classic list page (`sys_user_group_list.do`) instead | On Zurich only classic UI16 pages expose `g_ck` in the HTML |
| 2026-11-03 | `sysparm_ck` not found on the login page with a `name="sysparm_ck"…value=` pattern | Matched `sysparm_ck"[^>]*value="…"` regardless of attribute order | Don't depend on HTML attribute order when scraping tokens |
| 2026-11-03 | Form, list and related-list layouts created as `sys_ui_section`/`sys_ui_list`/`sys_ui_related_list` records via the Table API are **not** in the NJO v1.0 update set (58 records captured: tables, dictionary, labels, choices, numbers, roles, menu, modules) | Open item for Step 15: re-save each layout once through *Configure → Form Layout / List Layout / Related Lists* in the app scope so the platform writes the layout update records | Layout capture happens when the UI saves the whole layout, not on each element insert |
| 2026-11-03 | Groups, memberships and role grants are not in the update set | Expected — they are data, not application files. Will travel with the app as an XML export / documented in `docs/sample-data.md` (Step 15) | Update sets capture configuration, not data |
| 2026-11-03 | Inside the browser the current application was still *Employee Training and Certification Management* (banner on the Onboarding Task table record) | Only test data (TC-01/02 records) was created from the browser; all configuration came from the API session scoped to NJO | Current application is per session; check the banner before editing metadata in the UI |

## 2026-11-03 — Phase 2, Step 5: HR Services category and the "Onboard a New Joiner" catalog item
- **What:** Catalog category **HR Services** (Service Catalog). Catalog item **Onboard a New Joiner** (`sc_cat_item` `0a63428293d81f10803931697bba1029`):
  - Short description: "Request accounts, equipment, workspace and training for a new starter".
  - HTML description that explains the process and links to the KB article *Your first week at Novatrix* (`/sp?id=kb_article_view&sysparm_article=KB0010001`).
  - Availability *Desktop Only*, which turns classic mobile off; the Service Portal shows every active item in a portal catalog.
  - *Hide Quantity*, *Hide 'Add to Cart'* and *Hide Delivery time* are on.
  - Fulfilment is left empty for Phase 3 (no workflow, no flow).
- **Why:** One item with a reusable variable set is the CSA pattern for a service request. It produces an RITM that Phase 3's flow can read with *Get Catalog Variables*. A catalog item fits better than a record producer here: the request needs fulfilment orchestration and an RITM audit trail, not just one target record.
- **Learned:** The Service Portal reads the `_v2` display flags (`no_quantity_v2`, `no_cart_v2`, `no_delivery_time_v2`). The older `no_quantity` / `no_cart` flags only affect the classic UI, so the first portal render still showed *Quantity* and *Delivery Time: 2 Days*. Without a flow or workflow, an item falls back to its **execution plan** (`delivery_plan` = DEFAULT). That plan created two catalog tasks for the TC-05 request (*Assess or Scope Task*, *Provide requested service*). A Flow Designer flow attached in Phase 3 takes precedence over the execution plan.
- **Evidence:** `screenshots/tc04-portal-item-david-miller.jpg`

## 2026-11-03 — Phase 2, Step 6: Variable set "New Joiner Details" and the catalog UI policy
- **What:**
  - Single-row variable set **New Joiner Details** (`new_joiner_details`) with 10 variables in the guide's order:
    - `joiner_name`: Single Line Text, mandatory
    - `joiner_email`: Email, mandatory
    - `start_date`: Date, mandatory
    - `job_title`: Single Line Text
    - `department`: Reference → `cmn_department`
    - `location`: Reference → `cmn_location`
    - `equipment`: Select Box with the same values as the table choice (`laptop_standard` as default, `laptop_developer`, `desktop`, `none`)
    - `needs_desk` and `needs_training`: CheckBox, default checked
    - `notes`: Multi Line Text
  - The variable set is linked to the item (`io_set_item`).
  - Catalog UI policy **Equipment none - no equipment task message**, on the variable set: condition `equipment is None`, On load, Reverse if false, **Run on All UIs**.
  - The policy has one action on `equipment`: **Field message type = Info**, **Field message = "No equipment task will be created."**, everything else *Leave alone*.
- **Why:** The variable set mirrors the Onboarding Case columns one-to-one, so the Phase 3 *Create Record* step is a straight mapping. The same set can be reused later by an offboarding or contractor item. The policy lives on the set rather than the item, so it travels with the variables.
- **No-code decision:** Classically, the guide's info message would be `g_form.showFieldMsg()` in a catalog client script. On Zurich, UI policy actions have **Field message / Field message type**, so the message is a plain UI policy action. No script is involved and *Run scripts* stays off.
- **Learned:**
  - When checkbox variables follow each other, the platform groups them under an automatic **Options** label. That label is a synthetic `IO:` container, not a variable.
  - `catalog_conditions` uses the `IO:<variable sys_id>=value^EQ` encoding.
  - Catalog UI policies default to `ui_type = Desktop`, which the Service Portal ignores.
  - The issue table below covers the action-linking problem.
- **Evidence:** `screenshots/catalog-ui-policy-equipment-none.jpg`, `screenshots/catalog-ui-policy-action-field-message.jpg`

## 2026-11-03 — Phase 2, Step 7: HR Knowledge base and "Your first week at Novatrix"
- **What:**
  - Knowledge base **HR Knowledge**, owned by Beth Anglin, with publish flow *Knowledge - Instant Publish* and retire flow *Knowledge - Instant Retire*. It has one category, **Onboarding**.
  - Article **KB0010001 "Your first week at Novatrix"**, authored by Beth Anglin. Sections: before day one, day one, first week, who to contact. Keywords: *onboarding, new joiner, first week, day one, induction*.
  - The article was created as Draft and published with the form's **Publish** button, so the instant-publish flow made the state change.
  - Access:
    - *Can read*: **Any User** / *Any user for KB*
    - *Cannot read*: Guest User
    - *Can contribute*: only the new user criteria **NJO - Onboarding HR group**
  - **HR Knowledge is linked to the Service Portal** (`m2m_sp_portal_knowledge_base`, portal `sp`).
- **Why:** Hiring managers share the link with the joiner. Everyone in the company can read onboarding guidance, but only HR maintains it.
- **Learned:**
  - On Zurich, `glide.knowman.block_access_with_no_user_criteria = true`, so a KB with no *Can read* criteria is invisible to everyone except admins.
  - Inserting a KB automatically adds default criteria: *Can read* Any User, *Cannot read* / *Cannot contribute* Guest User, and **Can contribute "Has atleast one role apart from snc_internal KB"**.
  - That last default would let any fulfiller or hiring manager edit HR articles, so I removed it, leaving *NJO - Onboarding HR group*.
  - Knowledge access on a portal has **three** gates: the record ACL, the KB's user criteria, and whether the KB is linked to that portal.
- **Evidence:** `screenshots/tc06-kb-article-on-portal.jpg`, `screenshots/tc06-portal-search.jpg`, `screenshots/tc06-first-run-insufficient-privileges.jpg`

## 2026-11-03 — Phase 2 test cases (TC-04 to TC-06, all passed)
I ran all three tests in the browser while impersonating **David Miller** (member of *Hiring Managers*, so he has `x_2186817_njo.hiring_manager`). I ended the impersonation afterwards.
- **TC-04:**
  - `/sp?id=sc_cat_item&sys_id=0a63428293d81f10803931697bba1029` renders *Service Catalog › HR Services › Onboard a New Joiner* with the description, the KB link and all 10 variables.
  - Clicking **Request** on the empty form is blocked with "The following fields are incomplete: Joiner name, Personal email, Start date".
  - Equipment = None shows the info message; switching to Standard laptop removes it.
- **TC-05:**
  - Submitted Rohan Mehta (rohan.mehta@example.com, start 2026-11-17, Account Executive, Sales, Standard laptop, desk and training checked).
  - This created **REQ0010001 / RITM0010001**, with Requested for and Opened by both David Miller.
  - All 10 variable values are stored on the RITM (`sc_item_option_mtom`). No Onboarding Case exists yet; that comes in Phase 3.
- **TC-06:**
  - The first run failed with "You do not have sufficient privileges to access this knowledge item" (see the issue table).
  - After I linked HR Knowledge to the portal, KB0010001 opened for David Miller from the item's link (*Knowledge › HR Knowledge › Onboarding*).
  - Portal search for "first week" returns both the article and the catalog item.
- **Evidence:** `screenshots/tc04-portal-item-david-miller.jpg`, `screenshots/tc04-mandatory-enforced.jpg`, `screenshots/tc05-request-submitted-req0010001.jpg`, `screenshots/tc05-ritm-variables.jpg`, `screenshots/tc06-kb-article-on-portal.jpg`

| Date | Issue | Resolution | Learning |
|------|-------|------------|----------|
| 2026-11-03 | A catalog UI policy action created through the Table API saved with an empty *Variable name*. PATCHing `catalog_variable` / `variable` / `ui_policy` was silently blanked again | Deleted that action (created minutes earlier, referenced by nothing) and recreated it from the policy's *Catalog UI Policy Actions* related list in the form. The related-list context sets `ui_policy` | The `catalog_variable` choice list and the `ui_policy` link are only populated by the form, so create UI policy actions in the UI |
| 2026-11-03 | The info message did not appear on the portal even though the policy loaded | Two causes: the action was orphaned (row above) and the policy had `ui_type = Desktop`. Fixed by setting **Run on = All** | Check *Run on* for every catalog UI policy meant for the Service Portal |
| 2026-11-03 | The portal still showed *Quantity* and *Delivery Time: 2 Days* | Set `no_quantity_v2`, `no_cart_v2`, `no_delivery_time_v2` | The portal uses the v2 display flags |
| 2026-11-03 | TC-06 first run: "You do not have sufficient privileges to access this knowledge item" for David Miller, although the Table API returned the article for him | Linked HR Knowledge to portal `sp` (`m2m_sp_portal_knowledge_base`) | Portals only serve knowledge bases that are linked to them |
| 2026-11-03 | The KB insert added a default *Can contribute* criteria for anyone with a role | Removed it; only *NJO - Onboarding HR group* can contribute | Review the auto-created KB criteria after creating a knowledge base |
| 2026-11-03 | Test request REQ0010001 created two catalog tasks from the DEFAULT execution plan | Left them as test data. The Phase 3 flow replaces the execution plan for new requests | Having no fulfilment configured does not mean nothing runs: the execution plan is the fallback |
| 2026-11-03 | Reloading the portal form was blocked by a *Leave site?* prompt for the unsaved test form | Cleared `onbeforeunload` before reloading | Portal forms register an unsaved-changes guard |
| 2026-11-03 | Catalog/KB configuration in the browser was read-only because the browser session's current application was ETCMS | Switched the browser session to *New Joiner Onboarding* (`PUT /api/now/ui/concoursepicker/application`); NJO v1.0 became current | Each session (API and browser) has its own current application |

## 2026-11-03 — Phase 3, Steps 8–9: Flow Designer orchestration and the ETCMS integration
**Status: complete. TC-07 to TC-11 passed on 2026-11-03 after moving every ETCMS write into two ETCMS-scoped subflows (see "Fixing TC-07" below). The first build failed TC-07 five times; this entry keeps that history.**

- **Preparation (no-code records):**
  - **ETCMS *Course Enrollment* table, Application Access:** turned on *Can create* and *Can update*. *Accessible from: All application scopes* was already set, and *Can delete* stays off. The change was made in the ETCMS scope, so it lands in the ETCMS *Default* update set, not in NJO v1.0.
  - **Cross-scope decision:** NJO writes into ETCMS only through table-level application access plus explicit `sys_scope_privilege` rows (create, read and write on `x_2186817_employ_0_course_enrollment`, status Allowed). Nothing in ETCMS was scripted or re-scoped, and no existing ETCMS course or record was changed.
  - **ETCMS test data:** the only *Information Security Awareness* session (*Security Awareness Q4*, 2026-10-20) is Completed. I therefore created a future open session as test data: **Security Awareness Nov 2026** (2026-11-24 14:00–16:00, Microsoft Teams, trainer Rick Berzle, capacity 50, Open).
  - **Onboarding Case, two new reference fields:** **Requested Item** (→ `sc_req_item`) and **Training Enrollment** (→ ETCMS Course Enrollment), both added to the form. They give a real link to the request instead of putting the case number in the RITM comments (guide step 8.3), and they let Flow 2 find the enrollment without querying on free text.
- **Flow 1 "NJO Onboarding Orchestration"** (`sys_hub_flow` `46b982ce93d81f10803931697bba1043`, NJO scope, Run as System user, Active), 32 steps:
  1. Trigger *Service Catalog*, then **Get Catalog Variables** (all 10 variables from *New Joiner Details*).
  2. **Create Record** Onboarding Case: the 10 variables mapped one-to-one, plus *Hiring Manager = RITM ▸ Requested for*, *Requested Item = RITM* and *Stage = In Progress*.
  3. **Update Record** RITM: work note "Onboarding case created by flow NJO Onboarding Orchestration: <case number>".
  4. **Do the following in Parallel**, with six paths. Each path runs *Create Record Onboarding Task* (case, task type, group, short description "<type> … for <joiner>", **Due date = start_date pill with a Subtract Time / Add Time transform**), then *Wait For Condition* on that task's State being Closed Complete:
     - HR paperwork → Onboarding - HR, due start − 5 days
     - IT account → Onboarding - IT, start − 2
     - **If** *Equipment requested* (equipment is not None) → IT equipment → Onboarding - IT, start − 3
     - **If** *Desk needed* → Facilities desk → Onboarding - Facilities, start − 1
     - Facilities badge → Onboarding - Facilities, start − 1
     - **If** *Security training needed* → L&D training → Onboarding - L&D, start + 5. This path then also:
       - runs **Look Up Record** on Training Session where *Course is Information Security Awareness* and *Session Status is one of Planned, Open*, **ordered by Start Date a→z, first record only** (the earliest session);
       - runs **Create Record** on Course Enrollment (session = lookup result, *Enrollment Status = Enrolled*, *Enrollment Date = run date*, Employee left empty because the account does not exist yet). *First build. This step is now the ETCMS subflow call inside Try (see "Fixing TC-07")*;
       - **updates the case**: *Training Enrollment* = the new enrollment;
       - **adds a work note to the L&D task**: "Enrolled in ETCMS Information Security Awareness: <ENR number>";
       - waits for the L&D task to close.
  5. After the parallel block:
     - **Look Up Record** finds the case's last-closed task (ordered by Closed z→a).
     - **Update Record** on the case: *Stage = Ready for Day One*, *Ready Date* = that task's Closed time.
     - **Send Email** to the *Hiring Manager*: "Everything is ready for {joiner} on {start date}", including the case number.
  - The flow is attached to the catalog item through the item's *Flow* field, and the DEFAULT execution plan was cleared automatically.
- **Flow 2 "NJO Create Joiner Account"** (`sys_hub_flow` `7e1b964e935c1f10803931697bba10f5`, Run as System user, Active). Trigger: *Onboarding Task updated* where *Task Type is IT account AND State is Closed Complete*, Run Trigger **Once**.
  1. **Create Record** User:
     - *User ID* = joiner email → **Split "@" → Get First Item** (`priya.nair@example.com` → `priya.nair`).
     - *First name* / *Last name* = joiner name → **Split " " → Get First Item / Get Last Item**.
     - *Email*, *Title*, *Department* and *Location* come from the case; *Manager = Hiring Manager*.
  2. **Look Up Record** Onboarding Case where *Sys ID is trigger ▸ Onboarding Case ▸ Sys ID*.
  3. **Update Record** case: *Joiner User Account* = the new user.
  4. **If** *case ▸ Training Enrollment is not empty* → **Look Up Record** Course Enrollment by sys_id → **Update Record** *Employee* = the new user. *First build. Now Try → subflow "Link Enrollment to Employee"; see "Fixing TC-07"*.
- **Why two flows:**
  - Flow 1 is long-running because it waits for six tasks; account creation is a short reaction to one task closing.
  - Keeping them separate means IT can close its task in any order relative to the others.
  - User creation can be tested on its own, and a failure there does not break the orchestration.
- **No-code decisions:**
  - Date arithmetic uses **pill transform functions** (*Date & Time → Subtract Time / Add Time*), so the guide's "Start − N days" needs no script.
  - `user_name` from email uses *String → Split* plus *Utilities → Get First Item from Array*. First and last name use the same transforms with a space separator.
  - "Ready Date = now" uses the last-closed task's *Closed* value instead of a `gs.nowDateTime()` script; the last task's close time is the moment the joiner became ready.
  - "Earliest open session" uses Look Up Record's *Order by* plus *Return only the first record* instead of a scripted query.
  - Workflow Studio offers only *Convert to subflow* for a multi-select, so the six task/wait pairs could not be copy-pasted and each path was built by hand.
- **Tested:**
  - **Flow 1 *Test* with RITM0010001**, run before the parallel block existed. It created case NJO0001002 with all variables, Hiring Manager David Miller and Stage In Progress, wrote the RITM work note with the case number, and created HR task NJOT0001002 due 2026-11-12 (start − 5). That test context is still *Waiting* on its HR task.
  - **TC-07 failed in 5 runs:** REQ0010002–REQ0010006 for Priya Nair. Four went through the Service Catalog REST API as David Miller and one through the portal form as David Miller.
    - Each run creates the case correctly (Stage In Progress, Hiring Manager David Miller) and creates the L&D task.
    - The flow then errors with *"Scope does not have create access to table x_2186817_employ_0_course_enrollment"*.
    - The other five parallel paths never create their tasks.
- **Evidence (first build):** `screenshots/flow2-create-joiner-account.jpg`, `screenshots/tc07-flow-contexts-error.jpg`, `screenshots/tc07-portal-priya-nair.jpg`, `screenshots/etcms-enrollment-application-access.jpg`

### Fixing TC-07: ETCMS writes moved into ETCMS-scoped subflows
- **Root cause, as far as it could be pinned down:** Flow Designer would not let a flow in the NJO scope create or update ETCMS Course Enrollment records, whatever the table-level settings said.
  - Final check, at the user's request: *Accessible from* (`sys_db_object.access`) is **All application scopes** on Course Enrollment, Training Session and both NJO tables. `sys_user` is a global table with create and update allowed. So *Accessible from* was **not** the cause.
  - Together with the five failed attempts in the issue table (Can create / Can update, explicit `sys_scope_privilege` rows, cache flush, portal vs REST, re-saving in the ETCMS scope), every documented cross-scope setting was already correct.
  - The reads in the same branch (Look Up Training Session) worked. Only writes were refused: create in Flow 1, and update in Flow 2, which failed the same way with *"Scope does not have write access to table x_2186817_employ_0_course_enrollment"* the first time an IT task was closed.
  - **Conclusion:** I could not find a no-code switch that lets an NJO-scoped flow write to the ETCMS table on this instance. The reliable design is for **the scope that owns the table to do the write**, which is also the cleaner integration contract.
- **Fix, step 1: subflow "Enroll in Security Awareness"** (ETCMS scope, `sys_hub_flow` `8919ea0e93dc1f10803931697bba10e1`, Run as System user, Accessible from All application scopes, Published).
  - **Inputs:** *Employee sys_id* and *Session sys_id*, both optional Strings.
  - **Outputs:** *Enrollment sys_id* and *Enrollment number*.
  - **Logic:** If no session is given, Look Up the earliest Planned/Open *Information Security Awareness* session (order by Start Date, first record) and Create the Course Enrollment on it. Else, create the enrollment on the given session. Both branches set *Enrollment Status = Enrolled* and finish with **Assign Subflow Outputs**.
- **Fix, step 2: subflow "Link Enrollment to Employee"** (ETCMS scope, `sys_hub_flow` `b782fec293505f10803931697bba103f`, same settings).
  - **Inputs:** *Enrollment sys_id* and *Employee sys_id*.
  - **Logic:** Look Up the Course Enrollment by sys_id, then Update Record with *Employee* = the input.
- **Fix, step 3: Flow 1 L&D path** (after the L&D task is created and the session is looked up):
  - **Try:**
    1. call *Enroll in Security Awareness* (session = lookup ▸ Sys ID);
    2. Update the case *Training Enrollment* = subflow output *Enrollment sys_id*;
    3. add the L&D task work note "Enrolled in ETCMS Information Security Awareness: <Enrollment number>".
  - **Catch** (*and if error occurs*): work note on the L&D task: "ETCMS Security Awareness enrollment failed … enrol the joiner manually in ETCMS. Other onboarding tasks are not affected."
  - Then wait for the L&D task as before.
- **Fix, step 4: Flow 2.** The direct Look Up and Update of the enrollment were replaced:
  - **Try:** call *Link Enrollment to Employee* (enrollment = case ▸ Training Enrollment, employee = new user ▸ Sys ID).
  - **Catch:** a work note on the IT account task telling IT to set the Employee manually.
- **Option 2 safety net:** the Try blocks mean an ETCMS failure no longer ends the parallel block. The other five paths keep going and the failure is visible on the task.
  - **Deviation from the brief:** the brief asked for the note on the *case*, but the Onboarding Case table does not extend Task and has no work-notes journal. The note goes on the L&D task, or in Flow 2 on the IT task. Those records are auditable and are the ones the responsible team works from.
- **Why String sys_id inputs instead of Reference inputs:** the subflow-input *Reference* table picker is a virtualized list of every table with no search, so `sys_user` could not be selected reliably under automation. Strings carrying sys_ids work for both Create and Update (a reference field accepts a sys_id), and Flow Designer converts reference pills to their sys_id when they are dropped into a String input.
- **Subflows are ETCMS artifacts:** they are captured in the ETCMS *Default* update set, not in NJO v1.0. NJO depends on ETCMS anyway; the subflows are ETCMS's published interface for "enrol a user in Security Awareness", which another app could reuse.
- **Known gap:** the old Create Record set *Enrollment Date* = the flow run date. A subflow has no trigger date pill, so the new enrollments have an empty Enrollment Date. It does not affect TC-07 to TC-11; I note it for Phase 5 polish. Options: add a Date/Time input that NJO fills with its run date, or an ETCMS field default.
- **Re-test (2026-11-03), all passed.** The test data from the failed runs was deleted first, as approved: NJO0001002–NJO0001007 with their tasks, REQ0010002–REQ0010006 with their RITMs, and the waiting Flow 1 test context was cancelled.
  - **TC-07:** REQ0010007 for Priya Nair via the Service Catalog API as David Miller.
    - Case NJO0001008 got **6 tasks**, each with its group and due date: HR 11-08, IT equipment 11-10, IT account 11-11, Facilities desk and badge 11-12, L&D 11-18.
    - The subflow created **ENR0001021** on *Security Awareness Nov 2026*. The case links to it, and the L&D task has the ENR work note.
  - **TC-08:** REQ0010008 for Arjun Rao (equipment None, no desk). Case NJO0001009 got **4 tasks** (HR, IT account, Facilities badge, L&D) and **ENR0001022**.
  - **TC-09, first attempt (before the Flow 2 fix):** closing Priya's IT account task created `priya.nair` and set *Joiner User Account*. The enrollment update then failed with the *write access* error above. That led to the second subflow.
    - Priya's ENR0001021 Employee was then set once by hand as a test-data repair. The flow cannot re-run for her because the user already exists.
  - **TC-09, re-run on Arjun's IT task:** the flow COMPLETEd. `arjun.rao` was created, *Joiner User Account* was set, and the subflow set ENR0001022 *Employee* = Arjun Rao.
  - **TC-10:** after Priya's other five tasks were closed, Flow 1 COMPLETEd. The case is **Ready for Day One** with a Ready Date, and the email "Everything is ready for Priya Nair on 2026-11-13" to `david.miller@example.com` is in `sys_email` as *send-ready*.
  - **TC-11:** the *Security Awareness Nov 2026* session's Course Enrollments related list shows ENR0001021 Priya Nair and ENR0001022 Arjun Rao, both Enrolled.
- **Evidence (fix):** `screenshots/etcms-subflow-enroll-in-security-awareness.jpg`, `screenshots/etcms-subflow-link-enrollment-to-employee.jpg`, `screenshots/flow1-ld-path-try-subflow.jpg`, `screenshots/flow2-try-link-enrollment.jpg`, `screenshots/tc07-flow1-execution-top.jpg`, `screenshots/tc07-flow1-execution-ld-try.jpg`, `screenshots/tc08-tc09-case-arjun-rao.jpg`, `screenshots/tc09-flow2-execution.jpg`, `screenshots/tc10-case-ready-for-day-one.jpg`, `screenshots/tc10-day-one-email.jpg`, `screenshots/tc11-etcms-session-enrollments.jpg`

| Date | Issue | Resolution | Learning |
|------|-------|------------|----------|
| 2026-11-03 | **TC-07:** Flow 1's Create Record on ETCMS Course Enrollment fails with "Scope does not have create access" | **Resolved by redesign** (see "Fixing TC-07"): the create and the later update now run in ETCMS-scoped subflows that NJO calls inside Try. A sixth check confirmed *Accessible from = All application scopes* on every table involved, so that was not the cause. Failed attempts, in order: table *Can create* / *Can update* = true (the form shows both ticked); explicit `sys_scope_privilege` create/read/write Allowed from NJO to ETCMS; a `cache.do` flush; submitting through the portal instead of the REST API (rules out the `sn_sc` originating scope); toggling *Can create* off and on through the table form in the ETCMS scope. The flow runs as `system` in scope `x_2186817_njo`, and the read on *Training Session* in the same branch succeeds | Table-level access and scope privileges were not enough for a Flow Designer write from another scope on this instance. Let the owning scope do the write and expose it as a subflow |
| 2026-11-03 | After the TC-07 fix, Flow 2 failed with "Scope does not have **write** access to table x_2186817_employ_0_course_enrollment" | Second ETCMS subflow *Link Enrollment to Employee*, called from Flow 2 inside Try | Create and update are refused the same way. Any cross-app write needs the same pattern |
| 2026-11-03 | Moving existing steps into a new Try block by drag-and-drop did not work under automation | Deleted the old case/task updates and rebuilt them inside the Try (two Update Record steps) | Add the Try first, then build inside it |
| 2026-11-03 | The case form showed *Requested Item* and *Training Enrollment* twice | Two duplicate `sys_ui_element` rows from the field adds were deleted, then `cache.do` | Form layout rows are cached; flush after removing them |
| 2026-11-03 | The failure note was meant for the case, but the Onboarding Case has no work-notes field | Put the note on the L&D task (Flow 1) or the IT task (Flow 2) | Only Task-extended tables carry the journal fields |
| 2026-11-03 | Opening a second Workflow Studio record in the same browser tab showed a blank page; many open Studio tabs froze Chrome | One fresh tab per Studio record, closing old ones | Workflow Studio is heavy; keep few tabs open |
| 2026-11-03 | An error in one parallel path stops the whole *Do the following in Parallel* block | Matters for the fix: the ETCMS step should not take the other teams' tasks down with it | Parallel paths share one flow context; an unhandled error ends all of them |
| 2026-11-03 | Dot-walked record pills (trigger ▸ task ▸ Onboarding Case) are greyed out as the *Record* input of Update Record | Added a **Look Up Record** on Onboarding Case by sys_id and updated its output instead | Update Record needs a record pill produced by a step, not a dot-walk |
| 2026-11-03 | Pill transforms were not offered when clicking a pill | They appear as an **f(x)** icon when hovering over a dropped pill | Transforms are per pill and can be chained (Split → Get First Item) |
| 2026-11-03 | Workflow Studio jumped to its Home tab after closing the transform panel with Escape, or after a horizontal scroll | Close panels by clicking elsewhere, and avoid horizontal scrolling | Escape and horizontal swipe are bound to tab navigation |
| 2026-11-03 | The Chrome renderer froze twice in the Flow 2 editor (CDP screenshot timeouts) | Opened the flow in a fresh tab. Steps already confirmed with *Done* were persisted; the step being edited had to be re-entered | Each *Done* saves the step server-side |
| 2026-11-03 | Native `<select>` operators in If conditions ignore clicks under automation | Focus the select, press Escape, type the option text, press Tab | Keyboard selection works for native selects |
