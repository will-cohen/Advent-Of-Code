.DEFAULT_GOAL := help

ROOT_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
YEAR ?= 2025

.PHONY: help up down logs psql init run part1 part2 FORCE

help up down logs psql init run part1 part2:
	$(MAKE) -C "$(ROOT_DIR)$(YEAR)" $@

FORCE:

day-%: FORCE
	$(MAKE) -C "$(ROOT_DIR)$(YEAR)" $@
