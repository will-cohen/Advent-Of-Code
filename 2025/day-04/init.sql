-- Day 4: Printing Department
-- Safe to rerun: drops and recreates the day_04 schema.
--
-- The psql variable :data selects the input file (without .dat), e.g.
--   make init DAY=04 DATA=example
-- It defaults to data-set when not provided.

\if :{?data}
\else
    \set data data-set
\endif
\set input_path '/aoc/day-04/' :data '.dat'

DROP SCHEMA IF EXISTS day_04 CASCADE;
CREATE SCHEMA day_04;

-- Each input line is one row of the grid; retain its input order.
CREATE TABLE day_04.raw (
    row_no   integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    row_text text NOT NULL CHECK (row_text ~ '^[.@]+$')
);

COPY day_04.raw (row_text) FROM :'input_path';

-- Expand each grid row into cells with one-based row and column coordinates.
CREATE VIEW day_04.cells AS
SELECT
    raw.row_no,
    positions.col_no,
    substr(raw.row_text, positions.col_no, 1) AS contents
FROM day_04.raw AS raw
CROSS JOIN LATERAL generate_series(1, char_length(raw.row_text))
    AS positions(col_no);
