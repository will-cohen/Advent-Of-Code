-- Day 4, Part 1: count paper rolls with fewer than four rolls in adjacent cells.
WITH adjacent_roll_counts AS (
    -- For each paper roll, count other rolls within one row and column.
    SELECT
        roll.row_no,
        roll.col_no,
        COUNT(neighbor.contents) FILTER (WHERE neighbor.contents = '@') AS adjacent_rolls
    FROM day_04.cells AS roll
    LEFT JOIN day_04.cells AS neighbor
        ON abs(neighbor.row_no - roll.row_no) <= 1
        AND abs(neighbor.col_no - roll.col_no) <= 1
        -- Exclude the roll itself; only its eight surrounding cells count.
        AND (neighbor.row_no, neighbor.col_no) <> (roll.row_no, roll.col_no)
    WHERE roll.contents = '@'
    GROUP BY roll.row_no, roll.col_no
)
SELECT COUNT(*) AS accessible_rolls
FROM adjacent_roll_counts
WHERE adjacent_rolls < 4;
