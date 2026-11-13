-- Day 2, Part 1: sum the IDs made of a digit sequence repeated twice.
--
-- Generate possible half-values rather than scanning every ID in each range.
WITH half_lengths AS (
    SELECT
        ranges.first_id,
        ranges.last_id,
        half_length,
        power(10::numeric, half_length) AS place_value
    FROM day_02.ranges AS ranges
    -- For each range, generate every possible digit length for the repeated
    -- half; a repeated sequence must use no more than half the ID's digits.
    CROSS JOIN LATERAL generate_series(
        1,
        length(ranges.last_id::text) / 2
    ) AS lengths(half_length)
),
invalid_ids AS (
    SELECT DISTINCT halves.half * (half_lengths.place_value + 1) AS id
    FROM half_lengths
    -- For each half-length and range, generate only half-values whose
    -- doubled form falls within the range.
    CROSS JOIN LATERAL generate_series(
        GREATEST(
            ceil(half_lengths.first_id::numeric / (half_lengths.place_value + 1))::bigint,
            power(10::numeric, half_lengths.half_length - 1)::bigint
        ),
        LEAST(
            floor(half_lengths.last_id::numeric / (half_lengths.place_value + 1))::bigint,
            (half_lengths.place_value - 1)::bigint
        )
    ) AS halves(half)
)
SELECT SUM(id) AS password
FROM invalid_ids;
