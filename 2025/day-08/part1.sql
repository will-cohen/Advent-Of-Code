-- Day 8, Part 1: connect the closest pairs of junction boxes, then multiply
-- the sizes of the three largest circuits.
WITH RECURSIVE
connection_budget AS (
    -- The puzzle uses 10 connections for the 20-box example and 1000 for the
    -- real input.
    SELECT CASE WHEN COUNT(*) = 20 THEN 10 ELSE 1000 END AS connection_count
    FROM day_08.boxes
),
box_pairs AS (
    -- Every unordered pair of boxes. The self CROSS JOIN pairs each box with
    -- every other box; a.box_no < b.box_no keeps one copy of each pair.
    -- Squared distance preserves the ordering and avoids floating point.
    SELECT
        a.box_no AS box_a,
        b.box_no AS box_b,
        (a.x - b.x) ^ 2 + (a.y - b.y) ^ 2 + (a.z - b.z) ^ 2 AS squared_distance
    FROM day_08.boxes AS a
    CROSS JOIN day_08.boxes AS b
    WHERE a.box_no < b.box_no
),
shortest_pairs AS (
    -- The closest pairs, in order. Pairs already in the same circuit are
    -- harmless: they add no new reachability below.
    SELECT box_a, box_b
    FROM box_pairs
    ORDER BY squared_distance, box_a, box_b
    LIMIT (SELECT connection_count FROM connection_budget)
),
links AS (
    -- Treat each connection as usable in both directions.
    SELECT box_a AS from_box, box_b AS to_box FROM shortest_pairs
    UNION ALL
    SELECT box_b, box_a FROM shortest_pairs
),
reachable (start_box, box_no) AS (
    -- Recursive CTE: begin with every box reaching itself, then follow links
    -- outward. UNION (not UNION ALL) discards repeats so cycles terminate.
    SELECT box_no, box_no
    FROM day_08.boxes

    UNION

    SELECT reachable.start_box, links.to_box
    FROM reachable
    JOIN links
        ON links.from_box = reachable.box_no
),
circuits AS (
    -- A box's circuit id is the smallest box number it can reach; all boxes in
    -- one circuit share it.
    SELECT
        start_box AS box_no,
        MIN(box_no) AS circuit_id
    FROM reachable
    GROUP BY start_box
),
circuit_sizes AS (
    SELECT circuit_id, COUNT(*) AS size
    FROM circuits
    GROUP BY circuit_id
),
largest_three AS (
    SELECT size
    FROM circuit_sizes
    ORDER BY size DESC
    LIMIT 3
)
-- PostgreSQL has no product aggregate, so collect the three sizes into an
-- array (ordered largest first) and multiply its elements exactly.
SELECT
    sizes[1]::bigint * sizes[2] * sizes[3] AS answer
FROM (
    SELECT array_agg(size ORDER BY size DESC) AS sizes
    FROM largest_three
) AS packed;
