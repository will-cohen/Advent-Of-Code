-- Day 7, Part 2: count distinct timelines through the manifold.
WITH RECURSIVE
manifold_dimensions AS (
    -- Get the row and column limits needed to build the timeline state.
    SELECT
        MAX(row_no) AS height,
        MAX(char_length(row_text)) AS width
    FROM day_07.raw
),
start_position AS (
    -- Find the initial particle position.
    SELECT row_no, col_no
    FROM day_07.cells
    WHERE contents = 'S'
),
timeline_counts (row_no, counts) AS (
    -- Store how many timelines reach each column on the start row.
    SELECT
        start.row_no,
        ARRAY(
            SELECT CASE WHEN positions.col_no = start.col_no
                THEN 1::numeric
                ELSE 0::numeric
            END
            FROM manifold_dimensions AS dimensions
            CROSS JOIN LATERAL generate_series(0, dimensions.width + 1)
                AS positions(col_no)
            ORDER BY positions.col_no
        )
    FROM start_position AS start

    UNION ALL

    -- Advance one row. Straight paths continue in their column, while each
    -- splitter contributes its timeline count to both neighboring columns.
    SELECT
        state.row_no + 1,
        ARRAY(
            SELECT
                COALESCE(
                    CASE WHEN current_cell.contents IS DISTINCT FROM '^'
                        THEN state.counts[positions.col_no + 1]
                        ELSE 0::numeric
                    END,
                    0::numeric
                )
                + COALESCE(
                    CASE WHEN left_cell.contents = '^'
                        THEN state.counts[positions.col_no]
                        ELSE 0::numeric
                    END,
                    0::numeric
                )
                + COALESCE(
                    CASE WHEN right_cell.contents = '^'
                        THEN state.counts[positions.col_no + 2]
                        ELSE 0::numeric
                    END,
                    0::numeric
                )
            FROM generate_series(0, dimensions.width + 1)
                AS positions(col_no)
            LEFT JOIN day_07.cells AS current_cell
                ON current_cell.row_no = state.row_no
               AND current_cell.col_no = positions.col_no
            LEFT JOIN day_07.cells AS left_cell
                ON left_cell.row_no = state.row_no
               AND left_cell.col_no = positions.col_no - 1
            LEFT JOIN day_07.cells AS right_cell
                ON right_cell.row_no = state.row_no
               AND right_cell.col_no = positions.col_no + 1
            ORDER BY positions.col_no
        )
    FROM timeline_counts AS state
    CROSS JOIN manifold_dimensions AS dimensions
    WHERE state.row_no <= dimensions.height
)
-- The final transition leaves the manifold. Sum all surviving timelines,
-- including paths that moved one column beyond either edge.
SELECT SUM(final_counts.timeline_count) AS timeline_count
FROM timeline_counts AS final_state
CROSS JOIN manifold_dimensions AS dimensions
CROSS JOIN LATERAL unnest(final_state.counts)
    AS final_counts(timeline_count)
WHERE final_state.row_no = dimensions.height + 1;
