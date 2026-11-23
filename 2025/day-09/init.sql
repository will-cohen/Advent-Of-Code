-- Day 9: Movie Theater
-- Safe to rerun: drops and recreates the day_09 schema.
--
-- The psql variable :data selects the input file (without .dat), e.g.
--   make init DAY=09 DATA=example
-- It defaults to data-set when not provided.

\if :{?data}
\else
    \set data data-set
\endif
\set input_path '/aoc/day-09/' :data '.dat'

DROP SCHEMA IF EXISTS day_09 CASCADE;
CREATE SCHEMA day_09;

-- Each input line identifies a red tile; retain its position in the input.
CREATE TABLE day_09.raw (
    tile_no   integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tile_text text NOT NULL CHECK (tile_text ~ '^[0-9]+,[0-9]+$')
);

COPY day_09.raw (tile_text) FROM :'input_path';

-- Parse each coordinate pair while keeping tile_no as its input-order key.
CREATE VIEW day_09.red_tiles AS
SELECT
    raw.tile_no,
    split_part(raw.tile_text, ',', 1)::bigint AS x,
    split_part(raw.tile_text, ',', 2)::bigint AS y
FROM day_09.raw AS raw;
