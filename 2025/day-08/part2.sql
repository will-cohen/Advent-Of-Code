-- Day 8, Part 2: keep connecting the closest pairs until every box is in one
-- circuit, then multiply the X coordinates of the last pair that was joined.
-- Rank every unordered pair once, closest first, into an indexed temp table so
-- each recursion step below is a cheap key lookup instead of a re-sort.
-- The self CROSS JOIN pairs each box with every other box; a.box_no < b.box_no
-- keeps one copy of each pair. Squared distance keeps the same ordering without
-- floating point. ROW_NUMBER() is a window function: it numbers rows in the
-- given ORDER BY, giving the recursion a simple "next edge" key.
CREATE TEMP TABLE ranked_pairs AS
SELECT
    a.box_no AS box_a,
    b.box_no AS box_b,
    a.x AS x_a,
    b.x AS x_b,
    ROW_NUMBER() OVER (
        ORDER BY (a.x - b.x) ^ 2 + (a.y - b.y) ^ 2 + (a.z - b.z) ^ 2,
                 a.box_no, b.box_no
    ) AS pair_rank
FROM day_08.boxes AS a
CROSS JOIN day_08.boxes AS b
WHERE a.box_no < b.box_no;

ALTER TABLE ranked_pairs ADD PRIMARY KEY (pair_rank);
ANALYZE ranked_pairs;

WITH RECURSIVE
box_count AS (
    SELECT COUNT(*) AS total FROM day_08.boxes
),
merge_process (pair_rank, labels, circuits, x_a, x_b) AS (
    -- Recursive CTE. Each row is the state after considering one pair:
    --   labels   - array where labels[n] is the circuit label of box n
    --   circuits - how many circuits remain
    -- Start with every box in its own circuit (label = box number).
    SELECT
        0::bigint,
        ARRAY(SELECT box_no FROM day_08.boxes ORDER BY box_no),
        (SELECT total FROM box_count),
        NULL::bigint,
        NULL::bigint

    UNION ALL

    -- Consider the next-closest pair. If its boxes already share a label
    -- nothing changes; otherwise relabel one circuit to the other's label.
    -- The LATERAL subquery rebuilds the label array for this row (unnest ...
    -- WITH ORDINALITY yields each element with its position).
    SELECT
        pair.pair_rank,
        CASE WHEN state.labels[pair.box_a] = state.labels[pair.box_b]
             THEN state.labels
             ELSE relabeled.labels
        END,
        state.circuits
            - CASE WHEN state.labels[pair.box_a] = state.labels[pair.box_b]
                   THEN 0 ELSE 1 END,
        pair.x_a,
        pair.x_b
    FROM merge_process AS state
    JOIN ranked_pairs AS pair
        ON pair.pair_rank = state.pair_rank + 1
    -- "relabeled" is the label array after merging the two circuits.
    -- Example: labels = {1,2,3,2,5}, joining box 1 (label 1) with box 2
    -- (label 2). Every box labeled 2 (boxes 2 and 4) takes label 1, giving
    -- {1,1,3,1,5}. Steps:
    --   1. unnest(...) WITH ORDINALITY turns the array into rows of
    --      (label, position), e.g. (1,1) (2,2) (3,3) (2,4) (5,5).
    --   2. The CASE rewrites each label equal to box_b's label to box_a's
    --      label and leaves all others alone.
    --   3. array_agg(... ORDER BY position) rebuilds the array in the original
    --      order, so labels[n] still belongs to box n.
    -- LATERAL lets this subquery see the current row's state and pair columns.
    CROSS JOIN LATERAL (
        SELECT array_agg(
                   CASE WHEN old.label = state.labels[pair.box_b]
                        THEN state.labels[pair.box_a]
                        ELSE old.label
                   END
                   ORDER BY old.position
               ) AS labels
        FROM unnest(state.labels) WITH ORDINALITY AS old(label, position)
    ) AS relabeled
    WHERE state.circuits > 1
)
-- The first state with a single circuit is reached by the last needed pair.
SELECT x_a * x_b AS answer
FROM merge_process
WHERE circuits = 1
ORDER BY pair_rank
LIMIT 1;
