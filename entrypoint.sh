#!/bin/bash
set -euo pipefail

if [ -n "${TZ:-}" ] && [ -f "/usr/share/zoneinfo/${TZ}" ]; then
  ln -snf "/usr/share/zoneinfo/${TZ}" /etc/localtime
  echo "${TZ}" > /etc/timezone
fi

touch /var/log/claude-ping.log

echo "[$(date --iso-8601=seconds)] starting claude-work-ping in TZ=${TZ:-UTC}" \
  >> /var/log/claude-ping.log

cron

exec tail -F /var/log/claude-ping.log
