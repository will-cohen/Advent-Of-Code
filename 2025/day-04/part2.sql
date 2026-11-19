-- Day 4, Part 2: repeatedly remove every roll with fewer than four
-- remaining rolls in its eight neighboring cells.
WITH RECURSIVE paper_rolls AS MATERIALIZED (
    -- Read the grid once and give each roll a unique coordinate key.
    SELECT row_no, col_no, format('%s:%s', row_no, col_no) AS position
    FROM day_04.cells
    WHERE contents = '@'
),
neighbor_offsets AS (
    -- These are the eight surrounding cells, excluding the roll itself.
    SELECT *
    FROM (VALUES
        (-1, -1), (-1, 0), (-1, 1),
        (0, -1),           (0, 1),
        (1, -1),  (1, 0),  (1, 1)
    ) AS offsets(row_offset, col_offset)
),
roll_neighbors AS (
    -- Precompute each roll's neighbors instead of rescanning the grid per round.
    SELECT
        roll.position,
        COALESCE(
            jsonb_agg(neighbor.position) FILTER (WHERE neighbor.position IS NOT NULL),
            '[]'::jsonb
        ) AS neighbors
    FROM paper_rolls AS roll
    -- CROSS JOIN pairs each roll with all eight offsets; the LEFT JOIN retains
    -- isolated rolls and matches only actual paper at each neighboring position.
    CROSS JOIN neighbor_offsets AS offsets
    LEFT JOIN paper_rolls AS neighbor
        ON neighbor.row_no = roll.row_no + offsets.row_offset
        AND neighbor.col_no = roll.col_no + offsets.col_offset
    GROUP BY roll.position
),
removal_rounds AS (
    -- The recursive state maps remaining coordinate keys to their neighbor lists.
    -- An empty input starts with an empty map and zero rolls.
    SELECT
        COALESCE(jsonb_object_agg(position, neighbors), '{}'::jsonb) AS remaining,
        COUNT(*) AS remaining_count
    FROM roll_neighbors

    UNION ALL

    -- Keep only rolls with at least four neighbors in the previous state.
    -- WITH RECURSIVE feeds each round into the next until no rolls are removed.
    SELECT survivors.remaining, survivors.remaining_count
    FROM removal_rounds AS rounds
    -- LATERAL evaluates this aggregation for the current recursive state;
    -- CROSS JOIN attaches its single result row to that state.
    CROSS JOIN LATERAL (
        SELECT
            COALESCE(jsonb_object_agg(roll.key, roll.value), '{}'::jsonb) AS remaining,
            COUNT(*) AS remaining_count
        FROM jsonb_each(rounds.remaining) AS roll
        WHERE (
            SELECT COUNT(*)
            FROM jsonb_array_elements_text(roll.value) AS neighbor(position)
            -- JSONB's ? operator tests whether the neighbor's key still exists.
            WHERE rounds.remaining ? neighbor.position
        ) >= 4
    ) AS survivors
    -- Every recursive step must strictly decrease the finite number of rolls.
    WHERE survivors.remaining_count < rounds.remaining_count
)
-- Subtract the final stable count from the original count, including zero removals.
SELECT MAX(remaining_count) - MIN(remaining_count) AS removable_rolls
FROM removal_rounds;
