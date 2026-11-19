-- Day 6: Trash Compactor
-- Safe to rerun: drops and recreates the day_06 schema.
--
-- The psql variable :data selects the input file (without .dat), e.g.
--   make init DAY=06 DATA=example
-- It defaults to data-set when not provided.

\if :{?data}
\else
    \set data data-set
\endif
\set input_path '/aoc/day-06/' :data '.dat'

DROP SCHEMA IF EXISTS day_06 CASCADE;
CREATE SCHEMA day_06;

-- Keep worksheet rows as text so the view can split on the original spaces.
CREATE TABLE day_06.raw (
    row_no   integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    row_text text NOT NULL CHECK (row_text ~ '^[ 0-9+*]+$')
);

COPY day_06.raw (row_text) FROM :'input_path';

-- Split each worksheet row at runs of spaces and assign each field a
-- one-based position. LATERAL evaluates the split separately for each row.
CREATE VIEW day_06.cells AS
SELECT
    raw.row_no,
    fields.col_no,
    fields.contents
FROM day_06.raw AS raw
CROSS JOIN LATERAL regexp_split_to_table(btrim(raw.row_text, ' '), ' +')
    WITH ORDINALITY AS fields(contents, col_no);

-- Expand every row to the worksheet's full character width, padding short
-- rows with spaces so blank separator columns are visible.
CREATE VIEW day_06.characters AS
WITH worksheet_width AS (
    -- Find the rightmost character present in any input row.
    SELECT MAX(char_length(row_text)) AS width
    FROM day_06.raw
)
SELECT
    raw.row_no,
    positions.col_no,
    COALESCE(NULLIF(substr(raw.row_text, positions.col_no, 1), ''), ' ')
        AS contents
FROM day_06.raw AS raw
CROSS JOIN worksheet_width
CROSS JOIN LATERAL generate_series(1, worksheet_width.width)
    AS positions(col_no);
