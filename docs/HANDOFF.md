# Project handoff — NJO (as of 2026-11-03)

## Links
- PDI: https://dev407572.service-now.com (Zurich), same instance as ETCMS. Login is the owner's; credentials only in the local `.env`.
- GitHub: https://github.com/sparsh17max/servicenow-new-joiner-onboarding (commit identity: Sparsh Varde <sparshvarde@gmail.com>, per-repo config)
- Notion tracker: https://app.notion.com/p/23b588ec7d454b2fb47c815626198e06 — data source `7ac3abbc-9d62-4916-b2ae-9ce2f35480d3`; properties Task, Phase, Status [Not Started/In Progress/Testing/Completed], Priority, Start Date, Completion Date, Evidence (URL), Concepts Learned, Issues Encountered. Views: Default (table), Kanban (board by Status).
- Companion app: ETCMS, scope `x_2186817_employ_0`, repo `../servicenow-employee-training-management`.

## Rules
CSA-focused: configure via UI / Table API records only. No business rules, client scripts, script includes or background scripts. Only script allowed: the `gs.getUserID()` ACL condition (Step 12). Log every no-code decision in the dev log.

## Instance IDs
| Item | sys_id |
|------|--------|
| App *New Joiner Onboarding* (`x_2186817_njo`) | `a75b354293981f10803931697bba109e` |
| Update set *NJO v1.0* | `336bb50e93581f10803931697bba10bb` |
| Table Onboarding Case | `94cb358293981f10803931697bba104f` |
| Table Onboarding Task | `e50c7d8293981f10803931697bba10b9` |
| App menu | `dc8cfdc293981f10803931697bba10b6` |
| Role admin / user | `f27bb54293981f10803931697bba106c` / `1f7b394293981f10803931697bba1092` |
| Role hiring_manager / fulfiller / coordinator | `a77b394293981f10803931697bba10cf` / `b37b394293981f10803931697bba10f3` / `8c8b794293981f10803931697bba1016` |
| Group Onboarding - HR / IT | `229b390293981f10803931697bba10c2` / `48ab7d4293981f10803931697bba1055` |
| Group Onboarding - Facilities / L&D | `ddab7d4293981f10803931697bba10d6` / `72abbd4293981f10803931697bba10ab` |
| Group Hiring Managers | `efabfd4293981f10803931697bba1023` |
| Catalog category HR Services | `3d03024293d81f10803931697bba100c` |
| Catalog item Onboard a New Joiner | `0a63428293d81f10803931697bba1029` |
| Variable set New Joiner Details | `3a434e4293d81f10803931697bba100f` |
| Variables joiner_name / joiner_email / start_date | `5f434e4293d81f10803931697bba101a` / `b3434e4293d81f10803931697bba1090` / `88534e4293d81f10803931697bba10b6` |
| Variables job_title / department / location | `14534e4293d81f10803931697bba10c4` / `e0534e4293d81f10803931697bba10f7` / `38538e4293d81f10803931697bba1011` |
| Variables equipment / needs_desk / needs_training / notes | `8d538e4293d81f10803931697bba1050` / `ad538e4293d81f10803931697bba1061` / `35538e4293d81f10803931697bba10a1` / `c2538e4293d81f10803931697bba10d4` |
| Catalog UI policy (+ action) | `6373428293d81f10803931697bba10de` (`a7a40a0693d81f10803931697bba107b`) |
| KB HR Knowledge / category Onboarding | `ee03824293d81f10803931697bba107f` / `f2138a8a93981f10803931697bba104a` |
| Article KB0010001 | `df13064293d81f10803931697bba10ea` |
| User criteria NJO - Onboarding HR group | `8a03824293d81f10803931697bba1077` |
| Flow *NJO Onboarding Orchestration* | `46b982ce93d81f10803931697bba1043` (Active, attached to the catalog item) |
| Flow *NJO Create Joiner Account* | `7e1b964e935c1f10803931697bba10f5` (Active) |
| ETCMS test session *Security Awareness Nov 2026* | `9649c68693d81f10803931697bba10dc` |
| ETCMS subflow *Enroll in Security Awareness* (ETCMS scope, Default update set) | `8919ea0e93dc1f10803931697bba10e1` |
| ETCMS subflow *Link Enrollment to Employee* (ETCMS scope, Default update set) | `b782fec293505f10803931697bba103f` |

### Cross-scope pattern (Phase 3)
An NJO-scoped flow cannot create or update ETCMS Course Enrollment on this instance, even with table access, `sys_scope_privilege` rows and *All application scopes*. All ETCMS writes go through the two ETCMS-scoped subflows above, called inside **Try** blocks. Reads (Look Up) from NJO work. Reuse this pattern for any future cross-app write.

### Test data after Phase 3
- NJO0001008 (Priya Nair, REQ0010007): Ready for Day One, 6 tasks closed, user `priya.nair`, ENR0001021. Its Employee was set by hand after the first TC-09 attempt.
- NJO0001009 (Arjun Rao, REQ0010008): In Progress, IT account task closed, user `arjun.rao`, ENR0001022. HR, badge and L&D tasks are still open, so its Flow 1 context is Waiting.
- The failed-run data (NJO0001002–07, REQ0010002–06) was deleted. The 5 ERROR flow contexts from those runs remain as history.
- Known gap: enrollments created by the subflow have no *Enrollment Date* (Phase 5 polish).

## Open items
- **Step 15:** re-save the form, list and related-list layouts of both tables once through *Configure → Form Layout / List Layout / Related Lists* (app scope, NJO v1.0 current) so they are captured; they were created via the Table API and are not yet in the update set.
- Groups, members and role grants are data — not captured by the update set.
- Test data:
  - NJO0001001 (Ananya Iyer) and NJOT0001001 from TC-01/02.
  - REQ0010001 / RITM0010001 (Rohan Mehta, requested by David Miller) from TC-05, plus its two DEFAULT-execution-plan catalog tasks SCTASK0010001/2.
- Phase 3: attaching the flow to the item replaces the DEFAULT execution plan. Make UI configuration changes in the browser with the current application set to New Joiner Onboarding. It was switched back to NJO after the ETCMS subflows were built (2026-11-03).
- Workflow Studio automation: open each Studio record in a fresh tab and keep few tabs open, otherwise Chrome freezes.
- The KB, KB category and article are data and are not in the update set. The portal link, user criteria and KB criteria mappings are captured.
