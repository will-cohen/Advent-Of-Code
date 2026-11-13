.DEFAULT_GOAL := help

YEAR_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
COMPOSE := docker compose -f "$(YEAR_DIR)docker-compose.yml"
DAY ?= 01
PART ?= 1
DATA ?= data-set
PSQL := $(COMPOSE) exec -T postgres psql -X -v ON_ERROR_STOP=1 -v data="$(DATA)" -U aoc -d aoc2025

.PHONY: help up down logs psql init run part1 part2 check-day FORCE

help:
	@printf '%s\n' \
		'make up                  Start PostgreSQL and wait for readiness' \
		'make down                Stop PostgreSQL (preserve data)' \
		'make logs                Show PostgreSQL logs' \
		'make psql DAY=01         Initialize a day and open a SQL shell in its schema' \
		'make init DAY=01         Run day-01/init.sql' \
		'make run DAY=01 PART=1   Initialize and run day-01/part1.sql' \
		'make part1 DAY=01        Initialize and run part 1' \
		'make part2 DAY=01        Initialize and run part 2' \
		'make day-01 PART=1       Shortcut for running a day' \
		'' \
		'DATA selects the input file (default data-set):' \
		'make part1 DAY=01 DATA=example   Use day-01/example.dat'

up:
	$(COMPOSE) up -d --wait postgres

down:
	$(COMPOSE) down

logs:
	$(COMPOSE) logs postgres

psql: init
	$(COMPOSE) exec -e PGOPTIONS="-c search_path=day_$(DAY),public" postgres \
		psql -X -U aoc -d aoc2025 -v PROMPT1='day_$(DAY)=# '

check-day:
	@case "$(DAY)" in \
		0[1-9]|1[0-9]|2[0-5]) ;; \
		*) echo 'DAY must be two digits from 01 to 25' >&2; exit 1 ;; \
	esac

init: check-day
	@test -f "$(YEAR_DIR)day-$(DAY)/init.sql" || \
		{ echo "Missing day-$(DAY)/init.sql" >&2; exit 1; }
	@test -f "$(YEAR_DIR)day-$(DAY)/$(DATA).dat" || \
		{ echo "Missing day-$(DAY)/$(DATA).dat" >&2; exit 1; }
	$(MAKE) -C "$(YEAR_DIR)" up
	$(PSQL) -f "/aoc/day-$(DAY)/init.sql"

run: check-day
	@case "$(PART)" in \
		1|2) ;; \
		*) echo 'PART must be 1 or 2' >&2; exit 1 ;; \
	esac
	@test -f "$(YEAR_DIR)day-$(DAY)/part$(PART).sql" || \
		{ echo "Missing day-$(DAY)/part$(PART).sql" >&2; exit 1; }
	$(MAKE) -C "$(YEAR_DIR)" init DAY="$(DAY)"
	$(PSQL) -f "/aoc/day-$(DAY)/part$(PART).sql"

part1:
	$(MAKE) -C "$(YEAR_DIR)" run PART=1

part2:
	$(MAKE) -C "$(YEAR_DIR)" run PART=2

FORCE:

day-%: FORCE
	$(MAKE) -C "$(YEAR_DIR)" run DAY="$*"
