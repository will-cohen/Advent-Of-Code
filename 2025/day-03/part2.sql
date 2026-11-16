-- Day 3, Part 2: take the largest twelve-digit joltage from each bank.
-- Select exactly twelve digits in order. Since earlier digits have greater
-- place value, maximize the next digit while preserving enough positions to
-- complete the twelve-digit number.
WITH RECURSIVE selected AS (
    -- Start one independent selection for each bank, with twelve digits left.
    SELECT
        raw.line_no,
        raw.bank,
        1 AS start_pos,
        12 AS remaining,
        ''::text AS joltage
    FROM day_03.raw AS raw

    UNION ALL

    -- Append the best next digit and continue from the position after it.
    -- Each recursive row reduces the number of digits still to select by one.
    SELECT
        selected.line_no,
        selected.bank,
        battery.position + 1,
        selected.remaining - 1,
        selected.joltage || battery.digit
    FROM selected
    -- LATERAL makes the candidate search depend on this bank's current
    -- position and count of remaining digits.
    CROSS JOIN LATERAL (
        SELECT
            positions.position,
            substr(selected.bank, positions.position, 1) AS digit
        -- The last eligible position leaves exactly enough following
        -- batteries to complete the selection, with no reordering.
        FROM generate_series(
            selected.start_pos,
            length(selected.bank) - selected.remaining + 1
        ) AS positions(position)
        -- Choose the largest possible next digit; for ties, prefer the
        -- earliest occurrence to leave the most choices for later digits.
        ORDER BY digit DESC, positions.position
        LIMIT 1
    ) AS battery
    WHERE selected.remaining > 0
)
-- Keep only completed twelve-digit selections and sum each bank's joltage.
SELECT SUM(joltage::bigint) AS total_joltage
FROM selected
WHERE remaining = 0;
