-- Day 9, Part 1: find the largest rectangle with red tiles at opposite corners.
WITH rectangle_areas AS (
    -- Pair each red tile with every later tile in the input, so each
    -- unordered pair is considered once. The +1 counts both endpoint tiles.
    SELECT
        (ABS(first_tile.x - second_tile.x) + 1)
        * (ABS(first_tile.y - second_tile.y) + 1) AS area
    FROM day_09.red_tiles AS first_tile
    CROSS JOIN day_09.red_tiles AS second_tile
    WHERE first_tile.tile_no < second_tile.tile_no
)
SELECT MAX(area) AS answer
FROM rectangle_areas;
