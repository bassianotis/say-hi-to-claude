SHELL := /bin/bash
-include .env
export

.PHONY: help build up down restart logs auth ping shell status deploy

help:
	@echo "On the Pi:"
	@echo "  make build       Build the container image"
	@echo "  make up          Start the container (run after build)"
	@echo "  make down        Stop and remove the container"
	@echo "  make restart     Restart the container"
	@echo "  make status      Show container status"
	@echo "  make logs        Tail the ping log (Ctrl-C to exit)"
	@echo "  make auth        Run 'claude login' inside the container (one-time)"
	@echo "  make ping        Send a test ping right now"
	@echo "  make shell       Open a bash shell inside the container"
	@echo ""
	@echo "From your dev machine (needs PI_HOST and PI_PATH in .env):"
	@echo "  make deploy      git push, ssh to the Pi, pull + rebuild"

build:
	docker compose build

up:
	docker compose up -d

down:
	docker compose down

restart:
	docker compose restart

status:
	docker compose ps

logs:
	docker compose logs -f

auth:
	docker compose exec claude-work claude login

ping:
	docker compose exec -T claude-work bash -c 'echo "ping" | claude --print'

shell:
	docker compose exec claude-work bash

deploy:
	@if [ -z "$(PI_HOST)" ] || [ -z "$(PI_PATH)" ]; then \
	  echo "PI_HOST and PI_PATH must be set in .env for deploy"; exit 1; \
	fi
	git push
	ssh "$(PI_HOST)" "cd $(PI_PATH) && git pull && docker compose up -d --build"
