-- Day 5, Part 1: count available ingredient IDs included in any fresh range.
WITH fresh_ingredients AS (
    -- EXISTS treats overlapping ranges as one freshness match per ingredient.
    SELECT available.ingredient_id
    FROM day_05.available_ingredients AS available
    WHERE EXISTS (
        SELECT 1
        FROM day_05.ranges AS fresh_range
        WHERE available.ingredient_id BETWEEN fresh_range.first_id
                                          AND fresh_range.last_id
    )
)
SELECT COUNT(*) AS fresh_ingredients
FROM fresh_ingredients;
