-- Day 2, Part 2: sum the IDs made of a digit sequence repeated at least twice.
WITH block_lengths AS (
    SELECT
        ranges.first_id,
        ranges.last_id,
        block_length,
        power(10::numeric, block_length) AS place_value
    FROM day_02.ranges AS ranges
    -- For each range, generate block widths that can repeat at least twice
    -- within the number of digits in its upper bound.
    CROSS JOIN LATERAL generate_series(
        1,
        length(ranges.last_id::text) / 2
    ) AS lengths(block_length)
),
patterns AS (
    SELECT
        block_lengths.*,
        -- For a two-digit block repeated three times, the multiplier is
        -- (10^6 - 1) / (10^2 - 1) = 10101, so 12 becomes 121212.
        div(
            power(10::numeric, block_lengths.block_length * repeat_count) - 1,
            block_lengths.place_value - 1
        ) AS multiplier
    FROM block_lengths
    -- For each block width and range, generate every feasible repeat count,
    -- from twice up to the number of blocks that fit in the upper bound.
    CROSS JOIN LATERAL generate_series(
        2,
        length(block_lengths.last_id::text) / block_lengths.block_length
    ) AS repeats(repeat_count)
),
invalid_ids AS (
    -- An ID can match several patterns (1111 is both 1 x 4 and 11 x 2).
    SELECT DISTINCT blocks.block * patterns.multiplier AS id
    FROM patterns
    -- For each repeated-pattern multiplier, generate the base blocks whose
    -- resulting IDs fall within the input range.
    CROSS JOIN LATERAL generate_series(
        GREATEST(
            div(patterns.first_id + patterns.multiplier - 1, patterns.multiplier)::bigint,
            power(10::numeric, patterns.block_length - 1)::bigint
        ),
        LEAST(
            div(patterns.last_id, patterns.multiplier)::bigint,
            (patterns.place_value - 1)::bigint
        )
    ) AS blocks(block)
)
SELECT COALESCE(SUM(id), 0) AS password
FROM invalid_ids;
