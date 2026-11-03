# Data Dictionary

Application **New Joiner Onboarding**, scope `x_2186817_njo`.

## Onboarding Case — `x_2186817_njo_onboarding_case`
Standalone table (does not extend Task). Auto-number `NJO0001001…`.

| Label | Column | Type | Notes |
|-------|--------|------|-------|
| Number | `number` | String (40) | Auto-number prefix `NJO`, display field, read-only |
| Joiner Name | `joiner_name` | String (100) | Mandatory |
| Joiner Email | `joiner_email` | Email | Personal email used before the corporate account exists |
| Start Date | `start_date` | Date | Mandatory |
| Job Title | `job_title` | String (100) | |
| Department | `department` | Reference → `cmn_department` | |
| Location | `location` | Reference → `cmn_location` | |
| Hiring Manager | `hiring_manager` | Reference → `sys_user` | Set by the flow from *Requested for* (no scripted default) |
| Equipment Needed | `equipment_needed` | Choice | `laptop_standard`, `laptop_developer`, `desktop`, `none` |
| Needs Desk | `needs_desk` | True/False | Default true |
| Needs Security Training | `needs_security_training` | True/False | Default true |
| Joiner User Account | `joiner_user_account` | Reference → `sys_user` | Filled by the flow once IT creates the account |
| Stage | `stage` | Choice (no *None*) | `requested` (default), `in_progress`, `ready_for_day_one`, `closed`, `cancelled` |
| Ready Date | `ready_date` | Date/Time | Set by the flow when all tasks close |
| Notes | `notes` | String (4000) | |

## Onboarding Task — `x_2186817_njo_onboarding_task` (extends `task`)
Auto-number `NJOT0001001…`. Inherits 71 Task columns, including Number, Short description, Description, State, Priority, Assignment group, Assigned to, Opened, Closed, **Due date** (`due_date`, reused instead of a new Date field) and Work notes.

| Label | Column | Type | Notes |
|-------|--------|------|-------|
| Onboarding Case | `onboarding_case` | Reference → Onboarding Case | Mandatory; drives the *Onboarding Tasks* related list |
| Task Type | `task_type` | Choice | `hr_paperwork`, `it_account`, `it_equipment`, `facilities_desk`, `facilities_badge`, `ld_training` |

## Roles
| Role | Contains | Granted to |
|------|----------|-----------|
| `x_2186817_njo.admin` | `x_2186817_njo.user` | (application admin) |
| `x_2186817_njo.user` | — | via the roles below |
| `x_2186817_njo.hiring_manager` | `x_2186817_njo.user` | group *Hiring Managers* |
| `x_2186817_njo.fulfiller` | `x_2186817_njo.user` | groups *Onboarding - HR / IT / Facilities / L&D* |
| `x_2186817_njo.coordinator` | `x_2186817_njo.user` | Beth Anglin (direct) |

## Groups
| Group | Manager | Members |
|-------|---------|---------|
| Onboarding - HR | Beth Anglin | Carol Coughlin, Christen Mitchell |
| Onboarding - IT | Fred Luddy | Abel Tuter, David Loo |
| Onboarding - Facilities | Bow Ruggeri | Rick Berzle, Luke Wilson |
| Onboarding - L&D | Bow Ruggeri | Eric Schroeder |
| Hiring Managers | — | David Miller, Jerrod Bennett |
