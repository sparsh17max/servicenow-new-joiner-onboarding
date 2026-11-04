# Business Requirements

## Scenario
Novatrix Solutions (fictional) hires new staff every month. Before a joiner's first day, four teams each have to do something:
- **HR:** contract and policy sign-off
- **IT:** user account and laptop
- **Facilities:** desk and access badge
- **L&D:** mandatory Security Awareness training, which is run in the ETCMS application

At the moment the hiring manager chases each team by email. Joiners often arrive without a login or a desk, and nobody can say how long onboarding takes.

## Requirements
| ID | Requirement | Priority | Delivered by | Test |
|----|-------------|----------|--------------|------|
| BR-01 | A hiring manager raises one request for a new joiner on the Service Portal | Must | Catalog item *Onboard a New Joiner*, variable set *New Joiner Details* | TC-04, TC-05 |
| BR-02 | Each request creates one onboarding record that tracks the joiner to day one | Must | Onboarding Case table, Flow *NJO Onboarding Orchestration* | TC-01, TC-07 |
| BR-03 | The request becomes owned tasks for HR, IT, Facilities and L&D, with due dates relative to the start date | Must | Onboarding Task (extends Task), parallel flow paths | TC-02, TC-07 |
| BR-04 | Tasks that are not needed are not created (no equipment, no desk) | Must | Flow conditions on the case fields | TC-08 |
| BR-05 | When IT closes the account task, the joiner's user account is created and linked | Must | Flow *NJO Create Joiner Account* | TC-09 |
| BR-06 | Every joiner is enrolled in the next Security Awareness session in ETCMS | Must | ETCMS-scoped subflows called from Flow 1 and Flow 2 | TC-07, TC-11 |
| BR-07 | When all tasks are closed the case becomes *Ready for Day One* and the hiring manager is told | Must | Flow 1 wait-for-condition, notification | TC-10 |
| BR-08 | Each task type has a business-hours SLA; at 75% and at breach the group manager is notified | Should | 4 SLA definitions, SLA flow *NJO SLA Notifications*, 3 notifications | TC-12, TC-13 |
| BR-09 | Hiring managers see only their own joiners; teams see only their own tasks; the coordinator sees everything | Must | 9 ACLs (condition builder, no scripts) | TC-14, TC-15 |
| BR-10 | The joiner's personal email is hidden from hiring managers | Should | Field ACL on Joiner Email | TC-16 |
| BR-11 | HR can bulk-load upcoming joiners from a spreadsheet; re-loading updates rows instead of duplicating them | Should | Import set *Joiners Import*, transform map coalescing on Joiner Email | TC-17 |
| BR-12 | A dashboard shows onboardings by stage, open tasks by team, SLA breaches, time to ready and upcoming starts | Should | Dashboard *Onboarding Operations* (5 reports) | TC-18 |
| BR-13 | A first-week article is available to joiners and linked from the request | Could | HR Knowledge article KB0010001 | TC-06 |
| BR-14 | The whole application can be moved to another instance | Must | Update set *NJO v1.0* + dashboard XML in `update-sets/` | TC-19 |

## Constraints
- CSA-focused and configuration only: no business rules, client scripts, script includes or background scripts. The project ended with no scripts at all.
- Cross-application writes into ETCMS go through ETCMS-scoped subflows. An NJO-scoped flow cannot write ETCMS tables on this instance.

## Out of scope (v1)
- Sending email outside the instance (outbound SMTP is off on the PDI; notifications are verified in the outbox).
- Real HRIS or Active Directory integration. The import set stands in for an HR feed, and the flow creates the user in `sys_user` only.
- Offboarding.
