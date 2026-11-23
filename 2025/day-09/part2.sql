-- Day 9, Part 2: find the largest rectangle contained in the red/green loop.
WITH
polygon_vertices AS (
    -- Preserve input order: consecutive red tiles are connected, and the
    -- polygon type implicitly connects the final vertex back to the first.
    SELECT string_agg(
        format('(%s,%s)', x, y),
        ',' ORDER BY tile_no
    ) AS vertices
    FROM day_09.red_tiles
),
theater_polygon AS MATERIALIZED (
    -- Build the loop once. PostgreSQL's polygon containment includes its
    -- boundary and checks concave edges, not just the polygon's bounding box.
    SELECT ('(' || vertices || ')')::polygon AS shape
    FROM polygon_vertices
),
candidate_rectangles AS (
    -- Pair each red tile with each later tile, then form the axis-aligned
    -- rectangle they define. +1 counts both endpoint tiles in its area.
    SELECT
        (ABS(first_tile.x - second_tile.x) + 1)
        * (ABS(first_tile.y - second_tile.y) + 1) AS area,
        polygon(format(
            '((%s,%s),(%s,%s),(%s,%s),(%s,%s))',
            LEAST(first_tile.x, second_tile.x),
            LEAST(first_tile.y, second_tile.y),
            GREATEST(first_tile.x, second_tile.x),
            LEAST(first_tile.y, second_tile.y),
            GREATEST(first_tile.x, second_tile.x),
            GREATEST(first_tile.y, second_tile.y),
            LEAST(first_tile.x, second_tile.x),
            GREATEST(first_tile.y, second_tile.y)
        )) AS shape
    FROM day_09.red_tiles AS first_tile
    CROSS JOIN day_09.red_tiles AS second_tile
    WHERE first_tile.tile_no < second_tile.tile_no
),
valid_rectangles AS (
    -- Keep only rectangles wholly inside or on the red/green polygon.
    SELECT candidate_rectangles.area
    FROM candidate_rectangles
    CROSS JOIN theater_polygon
    WHERE theater_polygon.shape @> candidate_rectangles.shape
)
SELECT MAX(area) AS answer
FROM valid_rectangles;
