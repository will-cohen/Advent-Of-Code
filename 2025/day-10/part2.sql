-- Day 10, Part 2: minimize presses using the binary digits of button counts.
--
-- Write each button count as odd_bit + 2 * remaining_count. The selected
-- odd bits must produce the target's parity (odd/even counters). Subtract
-- their joltage contribution, halve the target, and repeat. This considers
-- only zero-or-one subsets instead of every possible full press count.

-- Temporary tables are session-local; recreate them for repeated runs.
DROP TABLE IF EXISTS pg_temp.parity_options;
DROP TABLE IF EXISTS pg_temp.button_wirings;
DROP TABLE IF EXISTS pg_temp.machine_targets;

-- Parse the wiring once and index each machine's ordered buttons.
CREATE TEMP TABLE button_wirings AS
SELECT machine_no, button_no, light_indexes
FROM day_10.button_wirings;
ALTER TABLE button_wirings ADD PRIMARY KEY (machine_no, button_no);
ANALYZE button_wirings;

-- Retain each machine's targets and button count for subset generation.
CREATE TEMP TABLE machine_targets AS
SELECT
    machine.machine_no,
    machine.joltage_requirements,
    COUNT(wiring.button_no) AS button_count
FROM day_10.machines AS machine
JOIN button_wirings AS wiring USING (machine_no)
GROUP BY machine.machine_no, machine.joltage_requirements;
ALTER TABLE machine_targets ADD PRIMARY KEY (machine_no);
ANALYZE machine_targets;

CREATE TEMP TABLE parity_options AS
WITH RECURSIVE
-- Enumerate zero-or-one button subsets, carrying their contribution arrays.
-- The recursive step advances one button, so it stops after the last button.
button_subsets(machine_no, button_no, joltage, press_count) AS (
    SELECT
        machine.machine_no,
        0::bigint,
        array_fill(0, ARRAY[cardinality(machine.joltage_requirements)]),
        0
    FROM machine_targets AS machine

    UNION ALL

    SELECT
        subsets.machine_no,
        wiring.button_no,
        ARRAY(
            SELECT
                counter.joltage + choices.press
                    * CASE
                        WHEN counter.counter_no - 1 = ANY(wiring.light_indexes)
                            THEN 1
                        ELSE 0
                      END
            FROM unnest(subsets.joltage) WITH ORDINALITY
                AS counter(joltage, counter_no)
            ORDER BY counter.counter_no
        ),
        subsets.press_count + choices.press
    FROM button_subsets AS subsets
    JOIN button_wirings AS wiring
        ON wiring.machine_no = subsets.machine_no
       AND wiring.button_no = subsets.button_no + 1
    -- CROSS JOIN branches each state into skipping or pressing this button.
    CROSS JOIN (VALUES (0), (1)) AS choices(press)
),
-- Identical contributions leave identical future targets; retain only the
-- cheapest subset producing each contribution. Keep different contributions
-- even when their parity matches, since they leave different future targets.
distinct_contributions AS (
    SELECT
        subsets.machine_no,
        subsets.joltage,
        MIN(subsets.press_count) AS press_count
    FROM button_subsets AS subsets
    JOIN machine_targets AS machine
        ON machine.machine_no = subsets.machine_no
       AND machine.button_count = subsets.button_no
    GROUP BY subsets.machine_no, subsets.joltage
)
SELECT
    contributions.machine_no,
    contributions.joltage,
    contributions.press_count,
    ARRAY(
        SELECT counter.joltage % 2
        FROM unnest(contributions.joltage) WITH ORDINALITY
            AS counter(joltage, counter_no)
        ORDER BY counter.counter_no
    ) AS parity
FROM distinct_contributions AS contributions;
CREATE INDEX ON parity_options (machine_no, parity);
ANALYZE parity_options;

WITH RECURSIVE
-- Each recursive level resolves one binary digit of every button's count.
-- digit_weight accounts for that digit's true number of presses (1, 2, 4...).
remaining_states(machine_no, digit_weight, remaining, total_presses) AS (
    SELECT
        machine.machine_no,
        1::bigint,
        machine.joltage_requirements,
        0::bigint
    FROM machine_targets AS machine

    UNION ALL

    SELECT DISTINCT
        states.machine_no,
        states.digit_weight * 2,
        next_state.remaining,
        -- This window function compares all paths reaching the same target
        -- at this level. Only the cheapest accumulated cost is needed because
        -- every such path has the same remaining choices. DISTINCT collapses
        -- the rows that now share that minimum cost.
        MIN(states.total_presses + options.press_count * states.digit_weight)
            OVER (
                PARTITION BY
                    states.machine_no,
                    states.digit_weight,
                    next_state.remaining
            )
    FROM remaining_states AS states
    JOIN parity_options AS options
        ON options.machine_no = states.machine_no
       AND options.parity = ARRAY(
           SELECT counter.joltage % 2
           FROM unnest(states.remaining) WITH ORDINALITY
               AS counter(joltage, counter_no)
           ORDER BY counter.counter_no
       )
    -- CROSS JOIN LATERAL calculates a new target for each state/option pair.
    CROSS JOIN LATERAL (
        SELECT
            array_agg(
                (counter.joltage - options.joltage[counter.counter_no]) / 2
                ORDER BY counter.counter_no
            ) AS remaining,
            bool_and(
                counter.joltage >= options.joltage[counter.counter_no]
            ) AS fits
        FROM unnest(states.remaining) WITH ORDINALITY
            AS counter(joltage, counter_no)
    ) AS next_state
    WHERE next_state.fits
      -- Do not expand solved targets. Every other target strictly shrinks,
      -- bounding recursion by the number of binary digits in the input.
      AND states.remaining <> array_fill(0, ARRAY[cardinality(states.remaining)])
),
-- A zero remaining target is a completed solution; select each machine's
-- cheapest completion across all binary levels.
machine_minimums AS (
    SELECT machine_no, MIN(total_presses) AS minimum_presses
    FROM remaining_states
    WHERE remaining = array_fill(0, ARRAY[cardinality(remaining)])
    GROUP BY machine_no
)
SELECT SUM(minimum_presses) AS answer
FROM machine_minimums;
