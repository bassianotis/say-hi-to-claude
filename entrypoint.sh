#!/bin/bash
set -euo pipefail

if [ -n "${TZ:-}" ] && [ -f "/usr/share/zoneinfo/${TZ}" ]; then
  ln -snf "/usr/share/zoneinfo/${TZ}" /etc/localtime
  echo "${TZ}" > /etc/timezone
fi

touch /var/log/claude-ping.log

echo "[$(date --iso-8601=seconds)] starting claude-work-ping in TZ=${TZ:-UTC}" \
  >> /var/log/claude-ping.log

# Claude Code splits auth state between /root/.claude/ (mounted) and
# /root/.claude.json (not mounted, wiped on image rebuild). Restore from
# the latest backup so `claude login` doesn't have to be re-run.
if [ ! -f /root/.claude.json ]; then
  latest_backup=$(ls -t /root/.claude/backups/.claude.json.backup.* 2>/dev/null | head -n1 || true)
  if [ -n "$latest_backup" ]; then
    cp "$latest_backup" /root/.claude.json
    echo "[$(date --iso-8601=seconds)] restored /root/.claude.json from $(basename "$latest_backup")" \
      >> /var/log/claude-ping.log
  fi
fi

cron

exec tail -F /var/log/claude-ping.log
