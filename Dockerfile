FROM node:20-slim

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        cron \
        tzdata \
        ca-certificates \
    && rm -rf /var/lib/apt/lists/*

RUN npm install -g @anthropic-ai/claude-code

COPY crontab /tmp/crontab
RUN crontab /tmp/crontab && rm /tmp/crontab

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

RUN touch /var/log/claude-ping.log

CMD ["/usr/local/bin/entrypoint.sh"]
