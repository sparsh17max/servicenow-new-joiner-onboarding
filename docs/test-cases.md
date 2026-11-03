# Test Cases

| ID | Test | Steps | Expected result | Actual result | Status |
|----|------|-------|-----------------|---------------|--------|
| TC-01 | Create a case manually (Phase 1) | Onboarding Cases → New → fill Joiner Name, Start Date → Save | NJO number assigned, Stage = Requested | Form pre-filled **NJO0001001**, Stage **Requested**; case for Ananya Iyer saved (2026-11-03) | ✅ |
| TC-02 | Create a task from the related list (Phase 1) | Open NJO0001001 → Onboarding Tasks → New | Onboarding Case pre-populated, NJOT number, State = Open | Onboarding Case **NJO0001001** pre-populated, **NJOT0001001**, State **Open**; saved as HR paperwork / Onboarding - HR and listed in the case's related list (2026-11-03) | ✅ |
| TC-03 | Role via group (Phase 1) | Impersonate Abel Tuter (Onboarding - IT) | Has `njo.fulfiller` via the group | Active roles while impersonating: `x_2186817_njo.fulfiller`, `x_2186817_njo.user`; User Roles list shows both `inherited = true` (2026-11-03) | ✅ |
| TC-04 | Catalog item on the portal (Phase 2) | `/sp` as David Miller → open *Onboard a New Joiner* | Form renders all variables; mandatory fields enforced | | ⬜ |
| TC-05 | Submit the item (Phase 2) | Submit the form | RITM created with the variable values | | ⬜ |
| TC-06 | Knowledge article (Phase 2) | Open the item / search the portal | Article visible and linked from the item | | ⬜ |
| TC-07 | Full orchestration (Phase 3) | Submit for Priya Nair, start +10 days, developer laptop, desk, training | Case + 6 tasks with the right groups and due dates | | ⬜ |
| TC-08 | Conditional tasks (Phase 3) | Equipment = none, no desk | Case + 4 tasks | | ⬜ |
| TC-09 | IT account sub-flow (Phase 3) | Close the IT account task | sys_user `priya.nair` exists; case Joiner User Account set; ETCMS enrollment Employee set | | ⬜ |
| TC-10 | Day-one ready (Phase 3) | Close all tasks | Stage = Ready for Day One, Ready Date set, email to hiring manager in outbox | | ⬜ |
| TC-11 | Cross-app proof (Phase 3) | Open the ETCMS Security Awareness session | Priya in its enrollment related list | | ⬜ |
| TC-12 | SLA attached (Phase 4) | Open an IT account task | SLA *IT account creation* attached, business-hours timer | | ⬜ |
| TC-13 | SLA breach notification (Phase 4) | Short test SLA reaches 100% | Breach notification in outbox | | ⬜ |
| TC-14 | Hiring manager row ACL (Phase 4) | Impersonate David Miller | Only his cases; other manager's case → record not found | | ⬜ |
| TC-15 | Fulfiller row ACL (Phase 4) | Impersonate Abel Tuter | Sees IT tasks, not HR tasks | | ⬜ |
| TC-16 | Field ACL (Phase 4) | Hiring manager opens case list/form | Joiner Email not visible | | ⬜ |
| TC-17 | Import + coalesce (Phase 5) | Import 15 rows, then re-import with 2 changed | 15 cases; then 2 updated, 0 duplicates | | ⬜ |
| TC-18 | Dashboard (Phase 5) | Open *Onboarding Operations* | Five reports with live data | | ⬜ |
| TC-19 | Update Set (Phase 5) | Export *NJO v1.0* XML, preview | Committed to `update-sets/`; preview shows no errors | | ⬜ |
