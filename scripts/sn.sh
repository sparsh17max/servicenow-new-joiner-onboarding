#!/usr/bin/env bash
# REST helper for the NJO build. Not a ServiceNow script: it only calls the Table API
# from this machine, using session auth (Basic auth returns 401 on this PDI — see ETCMS HANDOFF).
#
#   source scripts/sn.sh
#   sn_login                                   # POST /login.do, keep cookies, read g_ck
#   sn GET  "/api/now/table/sys_user_group?sysparm_query=nameSTARTSWITHOnboarding"
#   sn POST "/api/now/table/sys_user_group" '{"name":"…"}'
#   sn_scope <app sys_id>                      # set the session's current application
#
# Credentials come from .env (git-ignored): SN_INSTANCE, SN_USER, SN_PASS.

_SN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
set -a; . "$_SN_DIR/.env"; set +a
SN_JAR="$_SN_DIR/.sn-session/cookies.txt"
SN_CK_FILE="$_SN_DIR/.sn-session/g_ck"
mkdir -p "$_SN_DIR/.sn-session"

sn_login() {
  rm -f "$SN_JAR"
  local ck
  ck=$(curl -s -c "$SN_JAR" -b "$SN_JAR" "$SN_INSTANCE/login.do" | grep -o 'sysparm_ck"[^>]*value="[^"]*"' | head -1 | sed 's/.*value="//;s/"$//')
  curl -s -o /dev/null -c "$SN_JAR" -b "$SN_JAR" -X POST "$SN_INSTANCE/login.do" \
    --data-urlencode "user_name=$SN_USER" --data-urlencode "user_password=$SN_PASS" \
    --data-urlencode "sys_action=sysverb_login" --data-urlencode "sysparm_ck=$ck"
  curl -s -c "$SN_JAR" -b "$SN_JAR" "$SN_INSTANCE/sys_user_group_list.do" | grep -o "g_ck = '[^']*'" | head -1 | sed "s/g_ck = '//;s/'//" > "$SN_CK_FILE"
  if [ -s "$SN_CK_FILE" ]; then echo "logged in"; else echo "login FAILED" >&2; return 1; fi
}

# sn METHOD PATH [JSON-BODY]
sn() {
  local m="$1" p="$2" body="$3"
  local args=(-s -b "$SN_JAR" -c "$SN_JAR" -X "$m" -H "Accept: application/json" -H "X-UserToken: $(cat "$SN_CK_FILE")")
  if [ -n "$body" ]; then args+=(-H "Content-Type: application/json" --data "$body"); fi
  curl "${args[@]}" "$SN_INSTANCE$p"
}

sn_scope() { sn PUT "/api/now/ui/concoursepicker/application" "{\"app_id\":\"$1\"}"; echo; }
