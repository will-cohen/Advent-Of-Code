-- Day 3, Part 1: take the largest two-digit joltage from each bank.
-- Build each bank's joltage one digit at a time. At each step, choosing the
-- highest available digit that leaves enough batteries to finish is optimal:
-- the leftmost digit has greater place value than any later digit.
WITH RECURSIVE selected AS (
    -- Start one independent selection for every bank, with two digits to choose.
    SELECT
        raw.line_no,
        raw.bank,
        1 AS start_pos,
        2 AS remaining,
        ''::text AS joltage
    FROM day_03.raw AS raw

    UNION ALL

    -- Append one chosen digit, then advance past it. The recursive step runs
    -- again until both digits have been selected.
    SELECT
        selected.line_no,
        selected.bank,
        battery.position + 1,
        selected.remaining - 1,
        selected.joltage || battery.digit
    FROM selected
    -- LATERAL lets this candidate search use the current bank and selection
    -- state (start_pos and remaining) from the recursive row.
    CROSS JOIN LATERAL (
        SELECT
            positions.position,
            substr(selected.bank, positions.position, 1) AS digit
        -- Stop before positions that would leave too few batteries to choose
        -- the remaining digits; positions are still considered in input order.
        FROM generate_series(
            selected.start_pos,
            length(selected.bank) - selected.remaining + 1
        ) AS positions(position)
        -- Maximize the next digit. On ties, take the earliest one so that the
        -- remaining suffix stays as long as possible for future choices.
        ORDER BY digit DESC, positions.position
        LIMIT 1
    ) AS battery
    WHERE selected.remaining > 0
)
-- Each completed row contains one bank's maximum two-digit joltage.
-- Sum those per-bank values for the puzzle answer.
SELECT SUM(joltage::bigint) AS total_joltage
FROM selected
WHERE remaining = 0;
