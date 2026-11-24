-- Day 11, Part 2: count paths from svr to out that visit both dac and fft.
--
-- The puzzle's device graph is acyclic. Each recursive iteration advances
-- one connection, eventually exhausting every route without visited arrays.
WITH RECURSIVE
-- Count arrivals at each device and required-device state for this iteration.
-- Numeric counts avoid overflow even when the number of routes is very large.
path_counts(device_name, visited_dac, visited_fft, path_count) AS (
    SELECT
        'svr'::text,
        false,
        false,
        1::numeric

    UNION ALL

    SELECT DISTINCT
        connections.output_device,
        counts.visited_dac OR connections.output_device = 'dac',
        counts.visited_fft OR connections.output_device = 'fft',
        -- The window sums all arrivals with the same resulting state in this
        -- iteration. DISTINCT then retains one row carrying that total.
        -- Arrivals in later iterations remain separate, preserving paths
        -- of different lengths that eventually reach the same device.
        SUM(counts.path_count) OVER (
            PARTITION BY
                connections.output_device,
                counts.visited_dac OR connections.output_device = 'dac',
                counts.visited_fft OR connections.output_device = 'fft'
        )
    FROM path_counts AS counts
    JOIN day_11.connections AS connections
        ON connections.device_name = counts.device_name
    WHERE counts.device_name <> 'out'
),
-- Keep successful arrivals at every path length, in either required order.
qualifying_counts AS (
    SELECT path_count
    FROM path_counts
    WHERE device_name = 'out'
      AND visited_dac
      AND visited_fft
)
SELECT COALESCE(SUM(path_count), 0) AS answer
FROM qualifying_counts;
