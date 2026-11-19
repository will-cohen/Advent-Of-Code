-- Day 6, Part 1: calculate each worksheet problem, then sum the answers.
WITH RECURSIVE problem_inputs AS (
    -- Gather each problem's operator and its numeric operands in row order.
    SELECT
        col_no,
        MAX(contents) FILTER (WHERE contents IN ('+', '*')) AS operation,
        array_agg(contents::numeric ORDER BY row_no)
            FILTER (WHERE contents ~ '^[0-9]+$') AS operands
    FROM day_06.cells
    GROUP BY col_no
),
problem_values AS (
    -- Expand each problem's operand array into one row per value.
    -- LATERAL lets unnest refer to the current problem's operand array.
    SELECT
        problems.col_no,
        problems.operation,
        values.value_no,
        cardinality(problems.operands) AS value_count,
        values.value
    FROM problem_inputs AS problems
    CROSS JOIN LATERAL unnest(problems.operands)
        WITH ORDINALITY AS values(value, value_no)
),
running_totals (col_no, operation, value_no, value_count, total) AS (
    -- Start each problem's running total with its first operand.
    SELECT
        col_no,
        operation,
        value_no,
        value_count,
        value
    FROM problem_values
    WHERE value_no = 1

    UNION ALL

    -- Apply the problem's operator to the next operand until all are used.
    SELECT
        next_value.col_no,
        running.operation,
        next_value.value_no,
        next_value.value_count,
        CASE running.operation
            WHEN '+' THEN running.total + next_value.value
            WHEN '*' THEN running.total * next_value.value
        END
    FROM running_totals AS running
    JOIN problem_values AS next_value
        ON next_value.col_no = running.col_no
       AND next_value.value_no = running.value_no + 1
),
problem_answers AS (
    -- Keep the final running total for each problem.
    SELECT total
    FROM running_totals
    WHERE value_no = value_count
)
SELECT SUM(total) AS grand_total
FROM problem_answers;
