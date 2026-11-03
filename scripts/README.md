# scripts/

This project contains **no ServiceNow scripts** (no business rules, client scripts, script includes or background scripts) — see the project rule in [../docs/development-log.md](../docs/development-log.md).

| File | Purpose |
|------|---------|
| `sn.sh` | Local Bash helper for the Table API. Logs in with session auth (POST `/login.do`, keeps cookies, reads `g_ck` from a classic page and sends it as `X-UserToken` — Basic auth returns 401 on this PDI) and exposes `sn METHOD PATH [JSON]` and `sn_scope <app sys_id>`. Credentials come from the git-ignored `.env` (`SN_INSTANCE`, `SN_USER`, `SN_PASS`; template in `.env.example`). |

Usage:
```bash
source scripts/sn.sh
sn_login
sn_scope a75b354293981f10803931697bba109e   # New Joiner Onboarding
sn GET "/api/now/table/x_2186817_njo_onboarding_case?sysparm_limit=5"
```
