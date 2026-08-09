#!/usr/bin/env bash
# gitkit.sh - helper for git + GitHub Actions operations (used by opencode).
# Reads the auth token from the remote URL at runtime; never stores secrets.
set -euo pipefail

REPO_HOME="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPO_SLUG="$(git -C "$REPO_HOME" remote get-url origin | sed -E 's#https://[^@]*@github.com/##; s#\.git$##')"

token() {
  git -C "$REPO_HOME" remote get-url origin | sed -E 's#https://([^@]*)@.*#\1#'
}

api() {
  curl -s -H "Authorization: token $(token)" "$@"
}

now() { date +%H:%M:%S; }

usage() {
  cat <<'EOF'
gitkit.sh <command> [args]

  status                 git status --short + current branch
  log [n]                structured git log (default 5)
  diff [stat]            show uncommitted diff (or --stat)
  push "<message>"       add all, commit, push to origin/main
  ci [n]                 recent workflow runs (name|sha|status|conclusion|event)
  cijobs [run_id]        steps of a workflow run (default: latest run for HEAD)
  cilog [run_id]         stream full log of the latest failed step
  cifollow [n]           poll latest n runs until they complete
  cifail [run_id]        show failed step + error/warning lines from a run
  cancel [run_id]        cancel an in-progress run
  help                   this help
EOF
}

cmd_status() {
  echo "== branch =="
  git -C "$REPO_HOME" rev-parse --abbrev-ref HEAD
  echo "== status =="
  git -C "$REPO_HOME" status --short
}

cmd_log() {
  local n="${1:-5}"
  git -C "$REPO_HOME" log --pretty=format:'%h %ci %s' -n "$n"
  echo
}

cmd_diff() {
  if [[ "${1:-}" == "stat" ]]; then
    git -C "$REPO_HOME" diff --stat
  else
    git -C "$REPO_HOME" diff
  fi
}

cmd_push() {
  local msg="${1:-}"
  if [[ -z "$msg" ]]; then
    echo "error: push needs a commit message" >&2
    exit 1
  fi
  git -C "$REPO_HOME" add -A
  git -C "$REPO_HOME" commit -q -m "$msg"
  git -C "$REPO_HOME" push origin main -q
  echo "pushed: $(git -C "$REPO_HOME" rev-parse --short HEAD) $msg"
}

cmd_ci() {
  local n="${1:-5}"
  api "https://api.github.com/repos/$REPO_SLUG/actions/runs?per_page=$n" \
    | python3 -c "
import json, sys
for r in json.load(sys.stdin).get('workflow_runs', []):
    print('%-20s|%s|%-12s|%-10s|%s' % (r['name'], r['head_sha'][:7], r['status'], str(r['conclusion']), r['event']))
"
}

run_id_for_sha() {
  local sha="${1:-}"
  local n="${2:-10}"
  api "https://api.github.com/repos/$REPO_SLUG/actions/runs?per_page=$n" \
    | python3 -c "
import json, sys
sha = sys.argv[1]
for r in json.load(sys.stdin).get('workflow_runs', []):
    if r['head_sha'].startswith(sha):
        print(r['id'], r['name'], r['status'], r['conclusion'])
" "$sha"
}

latest_run_id() {
  run_id_for_sha "$(git -C "$REPO_HOME" rev-parse --short HEAD)" | head -1 | awk '{print $1}'
}

# Accept a numeric run id or a (short) commit sha; resolves to numeric run id.
resolve_run_id() {
  local x="${1:-}"
  if [[ -z "$x" ]]; then
    latest_run_id
  elif [[ "$x" =~ ^[0-9]+$ ]]; then
    echo "$x"
  else
    run_id_for_sha "$x" | head -1 | awk '{print $1}'
  fi
}

cmd_cijobs() {
  local run_id
  run_id="$(resolve_run_id "${1:-}")"
  api "https://api.github.com/repos/$REPO_SLUG/actions/runs/$run_id/jobs" \
    | python3 -c "
import json, sys
d = json.load(sys.stdin)
print('run: %d jobs' % d.get('total_count', 0))
for j in d.get('jobs', []):
    print('JOB %s [%s]' % (j['name'], j['conclusion']))
    for s in j['steps']:
        print('  %10s | %s' % (str(s['conclusion']), s['name']))
"
}

latest_failed_step_log() {
  local run_id="$1"
  local job_id
  job_id=$(api "https://api.github.com/repos/$REPO_SLUG/actions/runs/$run_id/jobs" \
    | python3 -c "
import json, sys
d = json.load(sys.stdin)
for j in d.get('jobs', []):
    if j['conclusion'] == 'failure':
        print(j['id']); break
")
  if [[ -z "$job_id" ]]; then
    echo "no failed job found" >&2
    return 1
  fi
  api "https://api.github.com/repos/$REPO_SLUG/actions/jobs/$job_id/logs"
}

cmd_cilog() {
  local run_id
  run_id="$(resolve_run_id "${1:-}")"
  echo "== streaming logs for run $run_id =="
  latest_failed_step_log "$run_id"
}

cmd_cifail() {
  local run_id
  run_id="$(resolve_run_id "${1:-}")"
  echo "== failed step analysis for run $run_id =="
  latest_failed_step_log "$run_id" \
    | sed -E 's/^[0-9T:.Z-]+Z?//' \
    | grep -E "\b(error|warning|info|fatal|FAILED|Exception)\b" \
    | sort -u \
    | head -40
}

cmd_cifollow() {
  local n="${1:-2}"
  local sha
  sha="$(git -C "$REPO_HOME" rev-parse --short HEAD)"
  echo "polling runs for $sha ..."
  while true; do
    local out ts
    ts="$(now)"
    out=$(api "https://api.github.com/repos/$REPO_SLUG/actions/runs?per_page=$n" \
      | python3 -c "
import json, sys
sha = sys.argv[1]
for r in json.load(sys.stdin).get('workflow_runs', []):
    if not r['head_sha'].startswith(sha):
        continue
    print('%-20s %-10s %s' % (r['name'], r['status'], r['conclusion']))
" "$sha" 2>/dev/null || true)
    echo "$out" | sed "s/^/  [$ts] /"
    local finished
    finished=$(echo "$out" | grep -c "completed" || true)
    if [[ "$finished" -ge 1 ]]; then
      break
    fi
    sleep 20
  done
}

cmd_cancel() {
  local run_id
  run_id="$(resolve_run_id "${1:-}")"
  echo "cancelling run $run_id"
  api -X POST "https://api.github.com/repos/$REPO_SLUG/actions/runs/$run_id/cancel" -o /dev/null -w "http %{http_code}\n"
}

cmd="${1:-help}"
shift || true

case "$cmd" in
  status)   cmd_status ;;
  log)      cmd_log "${1:-5}" ;;
  diff)     cmd_diff "${1:-}" ;;
  push)     cmd_push "${1:-}" ;;
  ci)       cmd_ci "${1:-5}" ;;
  cijobs)   cmd_cijobs "${1:-}" ;;
  cilog)    cmd_cilog "${1:-}" ;;
  cifail)   cmd_cifail "${1:-}" ;;
  cifollow) cmd_cifollow "${1:-2}" ;;
  cancel)   cmd_cancel "${1:-}" ;;
  help|-h|--help) usage ;;
  *) echo "unknown command: $cmd" >&2; usage; exit 1 ;;
esac
