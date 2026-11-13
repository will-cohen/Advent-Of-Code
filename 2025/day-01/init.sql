-- Day 1: Secret Entrance
-- Safe to rerun: drops and recreates the day_01 schema.

DROP SCHEMA IF EXISTS day_01 CASCADE;
CREATE SCHEMA day_01;

-- Raw input, one rotation per line. The identity column preserves file order.
CREATE TABLE day_01.part1_raw (
    line_no  integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    rotation text    NOT NULL
);

COPY day_01.part1_raw (rotation) FROM '/aoc/day-01/part1.dat';

-- Parsed rotations: direction (L/R) and click distance.
CREATE VIEW day_01.part1_rotations AS
SELECT
    line_no,
    left(rotation, 1)                 AS direction,
    substr(rotation, 2)::integer      AS distance
FROM day_01.part1_raw;
