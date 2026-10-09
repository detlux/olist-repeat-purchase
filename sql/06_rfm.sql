DROP TABLE IF EXISTS rfm;

CREATE TABLE rfm AS
WITH base AS (
    SELECT
        customer_unique_id,
        TIMESTAMP '2018-09-01' - MAX(purchased_at) AS recency_interval,
        COUNT(*) AS frequency,
        SUM(revenue) AS monetary
    FROM v_orders
    GROUP BY 1
),
scored AS (
    SELECT
        customer_unique_id,
        EXTRACT(DAY FROM recency_interval)::int AS recency_days,
        frequency,
        monetary,
        NTILE(5) OVER (ORDER BY recency_interval DESC) AS r,
        NTILE(5) OVER (ORDER BY monetary) AS m
    FROM base
)
SELECT
    *,
    CASE
        WHEN frequency >= 2 AND r >= 4 THEN 'Champions'
        WHEN frequency >= 2 THEN 'Loyal'
        WHEN r = 5 AND m >= 4 THEN 'Promising high value'
        WHEN r = 5 THEN 'New'
        WHEN r >= 3 AND m >= 4 THEN 'At risk high value'
        WHEN r >= 3 THEN 'Need attention'
        ELSE 'Lost'
    END AS segment
FROM scored;

CREATE INDEX idx_rfm_customer ON rfm (customer_unique_id);

SELECT
    segment,
    COUNT(*) AS customers,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS pct,
    ROUND(AVG(recency_days), 0) AS avg_recency,
    ROUND(AVG(frequency), 2) AS avg_freq,
    ROUND(AVG(monetary), 2) AS avg_monetary,
    ROUND(SUM(monetary), 0) AS total_revenue
FROM rfm
GROUP BY segment
ORDER BY customers DESC;