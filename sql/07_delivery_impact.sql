WITH first_order AS (
    SELECT DISTINCT ON (customer_unique_id)
        customer_unique_id, order_id, purchased_at, delivered_at, estimated_at
    FROM v_orders
    WHERE delivered_at IS NOT NULL
    ORDER BY customer_unique_id, purchased_at
),
f AS (
    SELECT
        fo.customer_unique_id,
        fo.purchased_at,
        CASE
            WHEN fo.delivered_at <= fo.estimated_at THEN 'on_time'
            WHEN fo.delivered_at <= fo.estimated_at + INTERVAL '3 days' THEN 'late_1_3d'
            ELSE 'late_3d_plus'
        END AS delivery_group,
        r.review_score
    FROM first_order fo
    LEFT JOIN v_reviews r ON r.order_id = fo.order_id
    WHERE fo.purchased_at <= TIMESTAMP '2018-09-01' - INTERVAL '90 days'
),
conv AS (
    SELECT DISTINCT f.customer_unique_id
    FROM f
    JOIN v_orders o ON o.customer_unique_id = f.customer_unique_id
    WHERE o.purchased_at > f.purchased_at
      AND o.purchased_at <= f.purchased_at + INTERVAL '90 days'
)
SELECT
    f.delivery_group,
    COUNT(*) AS customers,
    ROUND(AVG(f.review_score), 2) AS avg_review,
    ROUND(100.0 * COUNT(c.customer_unique_id) / COUNT(*), 2) AS conv_90d_pct
FROM f
LEFT JOIN conv c ON c.customer_unique_id = f.customer_unique_id
GROUP BY 1
ORDER BY 1;

WITH first_order AS (
    SELECT DISTINCT ON (customer_unique_id)
        customer_unique_id, order_id, purchased_at
    FROM v_orders
    ORDER BY customer_unique_id, purchased_at
),
f AS (
    SELECT fo.customer_unique_id, fo.purchased_at, r.review_score
    FROM first_order fo
    JOIN v_reviews r ON r.order_id = fo.order_id
    WHERE fo.purchased_at <= TIMESTAMP '2018-09-01' - INTERVAL '90 days'
),
conv AS (
    SELECT DISTINCT f.customer_unique_id
    FROM f
    JOIN v_orders o ON o.customer_unique_id = f.customer_unique_id
    WHERE o.purchased_at > f.purchased_at
      AND o.purchased_at <= f.purchased_at + INTERVAL '90 days'
)
SELECT
    f.review_score,
    COUNT(*) AS customers,
    ROUND(100.0 * COUNT(c.customer_unique_id) / COUNT(*), 2) AS conv_90d_pct
FROM f
LEFT JOIN conv c ON c.customer_unique_id = f.customer_unique_id
GROUP BY 1
ORDER BY 1;