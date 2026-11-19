-- Day 6, Part 2: read each operand vertically, then apply its problem's operator.
WITH RECURSIVE column_contents AS (
    -- Collect each column's digits from top to bottom and identify its operator.
    SELECT
        col_no,
        string_agg(contents, '' ORDER BY row_no)
            FILTER (WHERE contents ~ '^[0-9]$') AS digits,
        MAX(contents) FILTER (WHERE contents IN ('+', '*')) AS operation,
        bool_and(contents = ' ') AS is_separator
    FROM day_06.characters
    GROUP BY col_no
),
numbered_columns AS (
    -- Increment the problem number at every full blank separator column.
    SELECT
        col_no,
        digits,
        operation,
        is_separator,
        SUM(CASE WHEN is_separator THEN 1 ELSE 0 END)
            OVER (ORDER BY col_no) AS problem_no
    FROM column_contents
),
problem_columns AS (
    -- Carry the problem's operator onto each of its non-separator columns.
    SELECT
        col_no,
        problem_no,
        digits,
        MAX(operation) OVER (PARTITION BY problem_no) AS operation
    FROM numbered_columns
    WHERE NOT is_separator
),
problem_values AS (
    -- Keep numbered operands and order them from left to right within a problem.
    SELECT
        problem_no,
        operation,
        ROW_NUMBER() OVER (PARTITION BY problem_no ORDER BY col_no) AS value_no,
        COUNT(*) OVER (PARTITION BY problem_no) AS value_count,
        digits::numeric AS value
    FROM problem_columns
    WHERE digits IS NOT NULL
),
running_totals (problem_no, operation, value_no, value_count, total) AS (
    -- Initialize each problem's running total from its first operand.
    SELECT
        problem_no,
        operation,
        value_no,
        value_count,
        value
    FROM problem_values
    WHERE value_no = 1

    UNION ALL

    -- Apply the operator to successive operands until the problem is complete.
    SELECT
        next_value.problem_no,
        running.operation,
        next_value.value_no,
        next_value.value_count,
        CASE running.operation
            WHEN '+' THEN running.total + next_value.value
            WHEN '*' THEN running.total * next_value.value
        END
    FROM running_totals AS running
    JOIN problem_values AS next_value
        ON next_value.problem_no = running.problem_no
       AND next_value.value_no = running.value_no + 1
),
problem_answers AS (
    -- Retain the completed total for each worksheet problem.
    SELECT total
    FROM running_totals
    WHERE value_no = value_count
)
SELECT SUM(total) AS grand_total
FROM problem_answers;
