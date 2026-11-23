-- Day 10: Factory
-- Safe to rerun: drops and recreates the day_10 schema.
--
-- The psql variable :data selects the input file (without .dat), e.g.
--   make init DAY=10 DATA=example
-- It defaults to data-set when not provided.

\if :{?data}
\else
    \set data data-set
\endif
\set input_path '/aoc/day-10/' :data '.dat'

DROP SCHEMA IF EXISTS day_10 CASCADE;
CREATE SCHEMA day_10;

-- Keep each machine's manual entry intact and preserve its input order.
CREATE TABLE day_10.raw (
    machine_no integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    line_text  text NOT NULL CHECK (
        line_text ~ '^\[[.#]+\]( \([0-9]+(,[0-9]+)*\))+ \{[0-9]+(,[0-9]+)*\}$'
    )
);

COPY day_10.raw (line_text) FROM :'input_path';

-- Split out the target light pattern and the joltage values for each machine.
CREATE VIEW day_10.machines AS
SELECT
    raw.machine_no,
    substring(raw.line_text FROM '^\[([.#]+)\]') AS indicator_pattern,
    string_to_array(
        substring(raw.line_text FROM '\{([0-9,]+)\}$'),
        ','
    )::integer[] AS joltage_requirements
FROM day_10.raw AS raw;

-- Expand each button schematic into one row, preserving button order. Its
-- zero-based light indexes are stored as an integer array.
CREATE VIEW day_10.button_wirings AS
SELECT
    raw.machine_no,
    wiring.button_no,
    string_to_array(wiring.captures[1], ',')::integer[] AS light_indexes
FROM day_10.raw AS raw
CROSS JOIN LATERAL regexp_matches(
    raw.line_text,
    '\(([0-9,]+)\)',
    'g'
) WITH ORDINALITY AS wiring(captures, button_no);
