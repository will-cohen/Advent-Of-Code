-- Day 11: Reactor
-- Safe to rerun: drops and recreates the day_11 schema.
--
-- The psql variable :data selects the input file (without .dat), e.g.
--   make init DAY=11 DATA=example
-- It defaults to data-set when not provided.

\if :{?data}
\else
    \set data data-set
\endif
\set input_path '/aoc/day-11/' :data '.dat'

DROP SCHEMA IF EXISTS day_11 CASCADE;
CREATE SCHEMA day_11;

-- Keep each device's manual entry intact and preserve its input order.
CREATE TABLE day_11.raw (
    line_no   integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    line_text text NOT NULL CHECK (
        line_text ~ '^[a-z]{3}: [a-z]{3}( [a-z]{3})*$'
    )
);

COPY day_11.raw (line_text) FROM :'input_path';

-- Parse each device name and its ordered list of output device names.
CREATE VIEW day_11.devices AS
SELECT
    raw.line_no,
    split_part(raw.line_text, ': ', 1) AS device_name,
    string_to_array(split_part(raw.line_text, ': ', 2), ' ') AS output_devices
FROM day_11.raw AS raw;

-- Expand output lists into directed connections, keeping their listed order.
CREATE VIEW day_11.connections AS
SELECT
    devices.device_name,
    outputs.output_device,
    outputs.output_no
FROM day_11.devices AS devices
CROSS JOIN LATERAL unnest(devices.output_devices)
    WITH ORDINALITY AS outputs(output_device, output_no);
