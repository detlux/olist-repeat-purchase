WITH f AS (
    SELECT customer_unique_id, DATE_TRUNC('month', MIN(purchased_at))::date AS cohort
    FROM v_orders
    GROUP BY 1
),
act AS (
    SELECT DISTINCT
        f.cohort,
        f.customer_unique_id,
        (EXTRACT(YEAR FROM AGE(DATE_TRUNC('month', o.purchased_at), f.cohort)) * 12
         + EXTRACT(MONTH FROM AGE(DATE_TRUNC('month', o.purchased_at), f.cohort)))::int AS m
    FROM v_orders o
    JOIN f ON f.customer_unique_id = o.customer_unique_id
),
size AS (
    SELECT cohort, COUNT(*) AS cohort_size FROM f GROUP BY 1
)
SELECT
    a.cohort,
    s.cohort_size,
    a.m AS month_n,
    COUNT(*) AS active,
    ROUND(100.0 * COUNT(*) / s.cohort_size, 2) AS retention_pct
FROM act a
JOIN size s ON s.cohort = a.cohort
GROUP BY a.cohort, s.cohort_size, a.m
ORDER BY a.cohort, a.m;

SELECT
    cohort,
    COUNT(*) AS customers,
    ROUND(AVG(total_revenue), 2) AS avg_ltv,
    ROUND(AVG(orders), 3) AS avg_orders
FROM (
    SELECT
        DATE_TRUNC('month', MIN(purchased_at))::date AS cohort,
        customer_unique_id,
        SUM(revenue) AS total_revenue,
        COUNT(*) AS orders
    FROM v_orders
    GROUP BY customer_unique_id
) t
GROUP BY cohort
ORDER BY cohort;