-- Day 7, Part 1: count the splitter cells reached by tachyon beams.
WITH RECURSIVE
start_position AS (
    -- Find the beam's initial position at the marked start.
    SELECT
        row_no,
        col_no
    FROM day_07.cells
    WHERE contents = 'S'
),
beam_positions (row_no, col_no) AS (
    -- Begin with the single beam at S.
    SELECT
        row_no,
        col_no
    FROM start_position

    UNION

    -- Move every beam down one row. A splitter sends beams to its two
    -- neighboring columns; UNION merges beams that reach the same cell.
    SELECT
        next_cell.row_no,
        next_cell.col_no
    FROM beam_positions AS beam
    JOIN day_07.cells AS current_cell
        ON current_cell.row_no = beam.row_no
       AND current_cell.col_no = beam.col_no
    CROSS JOIN LATERAL generate_series(
        CASE WHEN current_cell.contents = '^' THEN -1 ELSE 0 END,
        CASE WHEN current_cell.contents = '^' THEN  1 ELSE 0 END,
        CASE WHEN current_cell.contents = '^' THEN  2 ELSE 1 END
    ) AS offsets(col_offset)
    JOIN day_07.cells AS next_cell
        ON next_cell.row_no = beam.row_no + 1
       AND next_cell.col_no = beam.col_no + offsets.col_offset
),
splitters_reached AS (
    -- Each reached splitter position represents one beam split.
    SELECT beam.row_no, beam.col_no
    FROM beam_positions AS beam
    JOIN day_07.cells AS cell
        ON cell.row_no = beam.row_no
       AND cell.col_no = beam.col_no
    WHERE cell.contents = '^'
)
SELECT COUNT(*) AS split_count
FROM splitters_reached;
