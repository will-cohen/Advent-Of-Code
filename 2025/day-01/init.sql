-- Day 1: Secret Entrance
-- Safe to rerun: drops and recreates the day_01 schema.
--
-- The psql variable :data selects the input file (without .dat), e.g.
--   make init DAY=01 DATA=example
-- It defaults to data-set when not provided.

\if :{?data}
\else
    \set data data-set
\endif
\set input_path '/aoc/day-01/' :data '.dat'

DROP SCHEMA IF EXISTS day_01 CASCADE;
CREATE SCHEMA day_01;

-- Raw input, one rotation per line. The identity column preserves file order.
CREATE TABLE day_01.raw (
    line_no  integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    rotation text    NOT NULL
);

COPY day_01.raw (rotation) FROM :'input_path';

-- Parsed rotations: direction (L/R) and click distance.
CREATE VIEW day_01.rotations AS
SELECT
    line_no,
    left(rotation, 1)                 AS direction,
    substr(rotation, 2)::integer      AS distance
FROM day_01.raw;
