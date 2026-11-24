-- Day 11, Part 1: count directed paths from you to out.
WITH RECURSIVE
-- Start at you and extend every discovered path by one outgoing connection.
-- Keep visited devices so malformed cyclic input cannot recurse forever.
device_paths(device_name, visited_devices) AS (
    SELECT
        'you'::text,
        ARRAY['you']::text[]

    UNION ALL

    SELECT
        connections.output_device,
        paths.visited_devices || connections.output_device
    FROM device_paths AS paths
    JOIN day_11.connections AS connections
        ON connections.device_name = paths.device_name
    WHERE paths.device_name <> 'out'
      AND connections.output_device <> ALL (paths.visited_devices)
),
-- Retain each completed path; duplicate endpoint rows represent distinct paths.
completed_paths AS (
    SELECT device_name
    FROM device_paths
    WHERE device_name = 'out'
)
SELECT COUNT(*) AS answer
FROM completed_paths;
