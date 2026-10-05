SELECT
    DATE_TRUNC('month', purchased_at)::date AS month,
    COUNT(*) AS orders,
    COUNT(DISTINCT customer_unique_id) AS customers,
    ROUND(SUM(revenue), 0) AS gmv,
    ROUND(AVG(revenue), 2) AS aov
FROM v_orders
GROUP BY 1
ORDER BY 1;

WITH f AS (
    SELECT customer_unique_id, MIN(purchased_at) AS first_at
    FROM v_orders
    GROUP BY 1
)
SELECT
    DATE_TRUNC('month', o.purchased_at)::date AS month,
    COUNT(*) FILTER (WHERE o.purchased_at = f.first_at) AS new_orders,
    COUNT(*) FILTER (WHERE o.purchased_at > f.first_at) AS repeat_orders,
    ROUND(100.0 * COUNT(*) FILTER (WHERE o.purchased_at > f.first_at) / COUNT(*), 2) AS repeat_order_pct
FROM v_orders o
JOIN f ON f.customer_unique_id = o.customer_unique_id
GROUP BY 1
ORDER BY 1;

WITH c AS (
    SELECT customer_unique_id, COUNT(*) AS n
    FROM v_orders
    GROUP BY 1
)
SELECT
    COUNT(*) AS customers,
    COUNT(*) FILTER (WHERE n > 1) AS repeat_customers,
    ROUND(100.0 * COUNT(*) FILTER (WHERE n > 1) / COUNT(*), 2) AS repeat_pct
FROM c;

WITH f AS (
    SELECT customer_unique_id, MIN(purchased_at) AS first_at
    FROM v_orders
    GROUP BY 1
    HAVING MIN(purchased_at) <= TIMESTAMP '2018-09-01' - INTERVAL '90 days'
)
SELECT
    COUNT(*) AS eligible_customers,
    COUNT(*) FILTER (WHERE x.customer_unique_id IS NOT NULL) AS converted_90d,
    ROUND(100.0 * COUNT(*) FILTER (WHERE x.customer_unique_id IS NOT NULL) / COUNT(*), 2) AS conv_90d_pct
FROM f
LEFT JOIN (
    SELECT DISTINCT o.customer_unique_id
    FROM v_orders o
    JOIN f f2 ON f2.customer_unique_id = o.customer_unique_id
    WHERE o.purchased_at > f2.first_at
      AND o.purchased_at <= f2.first_at + INTERVAL '90 days'
) x ON x.customer_unique_id = f.customer_unique_id;