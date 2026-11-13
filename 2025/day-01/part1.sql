-- Day 1, Part 1: count the rotations that leave the dial pointing at 0.
-- Position after each rotation = (50 + running signed total) mod 100;
-- the extra "+ 100) % 100" keeps the result non-negative for left turns.

WITH positions AS (
    SELECT
        line_no,
        -- SUM(...) OVER (ORDER BY line_no) is a window function: instead of
        -- collapsing rows like a GROUP BY, it keeps every row and attaches the
        -- sum of all rows up to and including the current one in line_no
        -- order. Without an explicit frame clause, ORDER BY defaults to
        -- RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW, which is exactly
        -- a running total. Each row therefore gets the net number of clicks
        -- applied so far, so 50 plus that total is the dial position after
        -- that rotation. (line_no is unique, so RANGE and ROWS are
        -- equivalent here.)
        ((50 + SUM(CASE direction WHEN 'R' THEN distance ELSE -distance END)
                   OVER (ORDER BY line_no)) % 100 + 100) % 100 AS position
    FROM day_01.rotations
)
SELECT COUNT(*) AS password
FROM positions
WHERE position = 0;
