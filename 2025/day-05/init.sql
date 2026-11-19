-- Day 5: Cafeteria
-- Safe to rerun: drops and recreates the day_05 schema.
--
-- The psql variable :data selects the input file (without .dat), e.g.
--   make init DAY=05 DATA=example
-- It defaults to data-set when not provided.

\if :{?data}
\else
    \set data data-set
\endif
\set input_path '/aoc/day-05/' :data '.dat'

DROP SCHEMA IF EXISTS day_05 CASCADE;
CREATE SCHEMA day_05;

-- Retain each input line's position so ranges and ingredient IDs can be
-- distinguished by their position relative to the blank-line separator.
CREATE TABLE day_05.raw (
    line_no   integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    line_text text NOT NULL CHECK (
        line_text = '' OR line_text ~ '^[0-9]+(-[0-9]+)?$'
    )
);

COPY day_05.raw (line_text) FROM :'input_path';

-- Parse the inclusive fresh-ID ranges that appear before the separator.
CREATE VIEW day_05.ranges AS
SELECT
    raw.line_no,
    split_part(raw.line_text, '-', 1)::bigint AS first_id,
    split_part(raw.line_text, '-', 2)::bigint AS last_id
FROM day_05.raw AS raw
WHERE raw.line_no < (
    SELECT min(separator.line_no)
    FROM day_05.raw AS separator
    WHERE separator.line_text = ''
)
  AND raw.line_text ~ '^[0-9]+-[0-9]+$';

-- Parse the available ingredient IDs that appear after the separator.
CREATE VIEW day_05.available_ingredients AS
SELECT
    raw.line_no,
    raw.line_text::bigint AS ingredient_id
FROM day_05.raw AS raw
WHERE raw.line_no > (
    SELECT min(separator.line_no)
    FROM day_05.raw AS separator
    WHERE separator.line_text = ''
)
  AND raw.line_text ~ '^[0-9]+$';
