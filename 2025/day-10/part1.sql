-- Day 10, Part 1: find the minimum button presses for each indicator pattern.
WITH RECURSIVE
target_masks AS (
    -- Represent each target pattern as a bit mask, with bit N set when light
    -- N is on. This matches the zero-based indexes in the button schematics.
    SELECT
        machines.machine_no,
        COALESCE(
            bit_or(1::bigint << (positions.light_no - 1))
                FILTER (
                    WHERE substr(
                        machines.indicator_pattern,
                        positions.light_no,
                        1
                    ) = '#'
                ),
            0
        ) AS target_mask
    FROM day_10.machines AS machines
    CROSS JOIN LATERAL generate_series(
        1,
        char_length(machines.indicator_pattern)
    ) AS positions(light_no)
    GROUP BY machines.machine_no
),
button_masks AS (
    -- Convert each button's list of toggled lights to a bit mask.
    SELECT
        wiring.machine_no,
        wiring.button_no,
        bit_or(1::bigint << light_indexes.light_no) AS toggle_mask
    FROM day_10.button_wirings AS wiring
    CROSS JOIN LATERAL unnest(wiring.light_indexes) AS light_indexes(light_no)
    GROUP BY wiring.machine_no, wiring.button_no
),
button_counts AS (
    -- Record how many ordered buttons each machine has, for identifying a
    -- complete selection of button presses below.
    SELECT
        button_masks.machine_no,
        count(*) AS button_count
    FROM button_masks
    GROUP BY button_masks.machine_no
),
button_subsets (machine_no, button_no, light_mask, press_count) AS (
    -- Recursive CTE: start with no buttons pressed, then branch at each button
    -- into the two possibilities: skip it or press it once. Pressing a button
    -- twice cannot improve a minimum because two toggles cancel each other.
    SELECT
        machines.machine_no,
        0::bigint,
        0::bigint,
        0::integer
    FROM day_10.machines AS machines

    UNION ALL

    SELECT
        subsets.machine_no,
        buttons.button_no,
        subsets.light_mask # (buttons.toggle_mask * choices.press),
        subsets.press_count + choices.press
    FROM button_subsets AS subsets
    JOIN button_masks AS buttons
        ON buttons.machine_no = subsets.machine_no
       AND buttons.button_no = subsets.button_no + 1
    CROSS JOIN (VALUES (0), (1)) AS choices(press)
),
machine_minimums AS (
    -- Keep only complete button selections that produce the target mask, then
    -- choose the one with the fewest total presses for each machine.
    SELECT
        subsets.machine_no,
        MIN(subsets.press_count) AS minimum_presses
    FROM button_subsets AS subsets
    JOIN button_counts AS counts
        ON counts.machine_no = subsets.machine_no
       AND counts.button_count = subsets.button_no
    JOIN target_masks AS targets
        ON targets.machine_no = subsets.machine_no
       AND targets.target_mask = subsets.light_mask
    GROUP BY subsets.machine_no
)
SELECT SUM(minimum_presses) AS answer
FROM machine_minimums;
