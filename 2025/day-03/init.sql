-- Day 3: Lobby
-- Safe to rerun: drops and recreates the day_03 schema.
--
-- The psql variable :data selects the input file (without .dat), e.g.
--   make init DAY=03 DATA=example
-- It defaults to data-set when not provided.

\if :{?data}
\else
    \set data data-set
\endif
\set input_path '/aoc/day-03/' :data '.dat'

DROP SCHEMA IF EXISTS day_03 CASCADE;
CREATE SCHEMA day_03;

-- Each input line is one bank; retain the joltage digits in their input order.
CREATE TABLE day_03.raw (
    line_no integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    bank    text NOT NULL CHECK (bank ~ '^[1-9]+$')
);

COPY day_03.raw (bank) FROM :'input_path';
