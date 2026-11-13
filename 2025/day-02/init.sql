-- Day 2: Gift Shop
-- Safe to rerun: drops and recreates the day_02 schema.
--
-- The psql variable :data selects the input file (without .dat), e.g.
--   make init DAY=02 DATA=example
-- It defaults to data-set when not provided.

\if :{?data}
\else
    \set data data-set
\endif
\set input_path '/aoc/day-02/' :data '.dat'

DROP SCHEMA IF EXISTS day_02 CASCADE;
CREATE SCHEMA day_02;

-- The puzzle input contains all ID ranges on one comma-separated line.
CREATE TABLE day_02.raw (
    line_no integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    ranges  text NOT NULL
);

COPY day_02.raw (ranges) FROM :'input_path';

CREATE VIEW day_02.ranges AS
SELECT
    raw.line_no,
    range_no,
    split_part(range_text, '-', 1)::bigint AS first_id,
    split_part(range_text, '-', 2)::bigint AS last_id
FROM day_02.raw
-- Split each input line into ranges; ordinality keeps each range's input order.
CROSS JOIN LATERAL string_to_table(raw.ranges, ',')
    WITH ORDINALITY AS input_ranges(range_text, range_no);
