# say-hi-to-claude

A single-purpose Docker utility that sends one non-interactive "ping" message to the [Claude Code](https://docs.claude.com/en/docs/claude-code) CLI every morning at 6:00 AM. The point is to **anchor the 5-hour usage window early**, so it resets at 11 AM rather than drifting to later in the workday.

## What it does

- Runs as a long-lived Docker container.
- An internal `cron` daemon fires `echo "ping" | claude --print` once a day at 06:00 in your configured timezone.
- Auth state persists to a host-mounted volume so it survives container restarts.
- Logs each ping attempt (with stdout + stderr) to a file you can tail.

Total footprint: a few MB of image, ~20 MB of RAM, one network call per day.

## Requirements

- A machine that can run Docker and Docker Compose (this is written for a Raspberry Pi 4 but should work anywhere).
- A Claude Code account with API access for the account you want to anchor.
- SSH access to the target machine (if you plan to deploy from elsewhere via `make deploy`).

## First-time setup on the Pi

```bash
# 1. Pick a directory (e.g. ~/docker/say-hi-to-claude) and clone the repo.
cd ~/docker
git clone <your-repo-url> say-hi-to-claude
cd say-hi-to-claude

# 2. Copy and edit the environment file.
cp .env.example .env
# Confirm TZ is correct for your locale. Default: America/Detroit.

# 3. Build and start.
make build
make up

# 4. One-time interactive auth. Log in with the account you want to anchor.
#    This will print a URL to open in any browser. Paste the code it returns.
make auth

# 5. Manually send a test ping. You should see a short response printed.
make ping

# 6. Verify the container restarts on reboot.
sudo reboot
# ...after reboot...
make status   # should show claude-work-ping as Up
```

## Verify cron is firing

Three ways, from cheapest to most thorough:

**Check the log file.** After a real 6 AM run, `make logs` will show a dated line with the ping response or error.

**Temporarily move the schedule.** Edit `crontab` to `* * * * *` (every minute), `make build && make up`, wait 90 seconds, `make logs`. You should see a response. Change it back to `0 6 * * *` when done.

**Verify the usage window is anchored.** Before the cron fires, run `claude` interactively and note the current window reset time. Run `make ping` to simulate a 6 AM trigger. Open Claude Code again; the window reset should now be 5 hours after the ping.

## Daily use

Nothing to do. The container runs, cron fires at 06:00 local time, and you get two clean 3-hour usage blocks (06:00–11:00 and 11:00–16:00, then 16:00–21:00 if you anchor a third).

## Updating from your dev machine

With `PI_HOST` and `PI_PATH` set in `.env` on your dev machine, one command pushes and rebuilds:

```bash
make deploy
```

That runs `git push`, SSHes to the Pi, `git pull`s, and `docker compose up -d --build`.

## Avoiding collisions with other Claude Code containers

If you already run a Claude Code instance in another container with its own auth, make sure `CLAUDE_WORK_AUTH` points to a **different directory** than that container's auth volume. The default `./claude-auth` stays inside this project folder, so it won't collide with anything unless you explicitly point it somewhere else.

## Troubleshooting

- **`make ping` fails with an auth error.** Run `make auth` again; the session token may have expired.
- **Cron fires but no ping output in the log.** Check `make logs` for stderr. Often it's a network or auth issue.
- **Time zone is wrong.** Edit `TZ` in `.env`, then `make restart`. The entrypoint re-symlinks `/etc/localtime` on boot.
- **Want to change the message.** Edit `crontab`, then `make build && make up` to rebake it into the image.

## Maintenance

- **Rebuild for updates.** `docker compose build --no-cache` every month or so to pick up new `@anthropic-ai/claude-code` releases and base image patches.
- **Re-auth when it expires.** You'll notice when `make logs` starts showing auth errors. Run `make auth` again.
- **Log rotation.** One line per day, negligible for years. Run `> /var/log/claude-ping.log` inside the container if you want to reset it.

## License

GPL-3.0-or-later. See [LICENSE](./LICENSE).
