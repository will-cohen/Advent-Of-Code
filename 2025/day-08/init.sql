-- Day 8: Playground
-- Safe to rerun: drops and recreates the day_08 schema.
--
-- The psql variable :data selects the input file (without .dat), e.g.
--   make init DAY=08 DATA=example
-- It defaults to data-set when not provided.

\if :{?data}
\else
    \set data data-set
\endif
\set input_path '/aoc/day-08/' :data '.dat'

DROP SCHEMA IF EXISTS day_08 CASCADE;
CREATE SCHEMA day_08;

-- Each input line is one junction box as "x,y,z"; keep the raw text for loading.
CREATE TABLE day_08.raw (
    box_no   integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    box_text text NOT NULL CHECK (box_text ~ '^[0-9]+,[0-9]+,[0-9]+$')
);

COPY day_08.raw (box_text) FROM :'input_path';

-- Parse each line into numeric coordinates. split_part picks the nth
-- comma-separated field. box_no preserves input order and identifies the box.
CREATE VIEW day_08.boxes AS
SELECT
    raw.box_no,
    split_part(raw.box_text, ',', 1)::bigint AS x,
    split_part(raw.box_text, ',', 2)::bigint AS y,
    split_part(raw.box_text, ',', 3)::bigint AS z
FROM day_08.raw AS raw;
