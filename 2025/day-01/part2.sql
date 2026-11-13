-- Day 1, Part 2: count every click that lands the dial on 0, including
-- clicks in the middle of a rotation.
--
-- For a rotation starting at position s with distance d:
--   right: 0 is hit at clicks k where (s + k) % 100 = 0  ->  floor((s + d) / 100)
--   left:  mirror image, i.e. a right turn from (100 - s) % 100
--          ->  floor((d + (100 - s) % 100) / 100)

WITH starts AS (
    SELECT
        line_no,
        direction,
        distance,
        -- Position before this rotation: 50 plus every earlier signed move.
        --
        -- Same running-total window as part 1, but with an explicit frame:
        -- ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING tells the window
        -- to sum from the first row up to the row *before* the current one,
        -- excluding the current row. That gives the dial position at the
        -- start of this rotation rather than at the end. The first row has
        -- no preceding rows, so its frame is empty and SUM returns NULL;
        -- COALESCE turns that into 0 so the dial starts at 50.
        ((50 + COALESCE(SUM(CASE direction WHEN 'R' THEN distance ELSE -distance END)
                            OVER (ORDER BY line_no
                                  ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING), 0))
            % 100 + 100) % 100 AS start_pos
    FROM day_01.rotations
),
zero_hits AS (
    SELECT
        line_no,
        -- Moving right on an unwrapped number line hits 0 at 100, 200, etc.
        -- Since start_pos is 0..99, dividing the endpoint by 100 counts those
        -- crossings, including a landing exactly on 0. PostgreSQL integer
        -- division discards the remainder: (50 + 149) / 100 = 1 hit, while
        -- (50 + 150) / 100 = 2 hits. Starting on 0 alone is not a click.
        -- The left-turn branch mirrors the starting position to count the
        -- same crossings while moving in the opposite direction.
        CASE direction
            WHEN 'R' THEN (start_pos + distance) / 100
            ELSE          (distance + (100 - start_pos) % 100) / 100
        END AS hits
    FROM starts
)
SELECT SUM(hits) AS password
FROM zero_hits;
