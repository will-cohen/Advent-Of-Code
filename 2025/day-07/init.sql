-- Day 7: Laboratories
-- Safe to rerun: drops and recreates the day_07 schema.
--
-- The psql variable :data selects the input file (without .dat), e.g.
--   make init DAY=07 DATA=example
-- It defaults to data-set when not provided.

\if :{?data}
\else
    \set data data-set
\endif
\set input_path '/aoc/day-07/' :data '.dat'

DROP SCHEMA IF EXISTS day_07 CASCADE;
CREATE SCHEMA day_07;

-- Each input line is one row of the manifold; retain its input order.
CREATE TABLE day_07.raw (
    row_no   integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    row_text text NOT NULL CHECK (row_text ~ '^[.S^]+$')
);

COPY day_07.raw (row_text) FROM :'input_path';

-- Expand each manifold row into cells with one-based row and column coordinates.
CREATE VIEW day_07.cells AS
SELECT
    raw.row_no,
    positions.col_no,
    substr(raw.row_text, positions.col_no, 1) AS contents
FROM day_07.raw AS raw
CROSS JOIN LATERAL generate_series(1, char_length(raw.row_text))
    AS positions(col_no);
