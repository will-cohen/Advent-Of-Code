-- Day 5, Part 2: count IDs covered by the fresh ranges, without double-counting overlaps.
WITH ordered_ranges AS (
    -- In start order, find the furthest endpoint covered by any earlier range.
    -- The running maximum handles nested ranges, unlike checking only LAG(last_id).
    SELECT
        first_id,
        last_id,
        max(last_id) OVER (
            ORDER BY first_id, last_id
            ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING
        ) AS previous_max_id
    FROM day_05.ranges
),
range_groups AS (
    -- A range starts a new group only when it begins beyond all previous ranges.
    -- The cumulative sum labels overlapping ranges with the same group number.
    SELECT
        first_id,
        last_id,
        sum(
            CASE
                WHEN previous_max_id IS NULL OR first_id > previous_max_id THEN 1
                ELSE 0
            END
        ) OVER (ORDER BY first_id, last_id) AS group_no
    FROM ordered_ranges
),
merged_ranges AS (
    -- Collapse each group into its combined inclusive range.
    SELECT
        min(first_id) AS first_id,
        max(last_id) AS last_id
    FROM range_groups
    GROUP BY group_no
)
SELECT COALESCE(
    sum(last_id::numeric - first_id::numeric + 1),
    0
) AS fresh_ingredient_ids
FROM merged_ranges;
