SELECT order_status, COUNT(*) AS orders, ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS pct
FROM orders
GROUP BY order_status
ORDER BY orders DESC;

SELECT MIN(order_purchase_timestamp) AS first_order, MAX(order_purchase_timestamp) AS last_order
FROM orders;

SELECT DATE_TRUNC('month', order_purchase_timestamp)::date AS month, COUNT(*) AS orders
FROM orders
GROUP BY 1
ORDER BY 1;

SELECT
    COUNT(*) FILTER (WHERE order_approved_at IS NULL) AS no_approved,
    COUNT(*) FILTER (WHERE order_delivered_carrier_date IS NULL) AS no_carrier,
    COUNT(*) FILTER (WHERE order_delivered_customer_date IS NULL) AS no_delivered,
    COUNT(*) FILTER (WHERE order_status = 'delivered' AND order_delivered_customer_date IS NULL) AS delivered_no_date
FROM orders;

SELECT
    COUNT(*) FILTER (WHERE order_approved_at < order_purchase_timestamp) AS approved_before_purchase,
    COUNT(*) FILTER (WHERE order_delivered_carrier_date < order_approved_at) AS carrier_before_approved,
    COUNT(*) FILTER (WHERE order_delivered_customer_date < order_delivered_carrier_date) AS customer_before_carrier,
    COUNT(*) FILTER (WHERE order_delivered_customer_date < order_purchase_timestamp) AS delivered_before_purchase
FROM orders;

SELECT
    COUNT(*) FILTER (WHERE oi.order_id IS NULL) AS no_items,
    COUNT(*) FILTER (WHERE op.order_id IS NULL) AS no_payments,
    COUNT(*) FILTER (WHERE r.order_id IS NULL) AS no_reviews
FROM orders o
LEFT JOIN (SELECT DISTINCT order_id FROM order_items) oi ON oi.order_id = o.order_id
LEFT JOIN (SELECT DISTINCT order_id FROM order_payments) op ON op.order_id = o.order_id
LEFT JOIN (SELECT DISTINCT order_id FROM order_reviews) r ON r.order_id = o.order_id;

SELECT COUNT(*) AS review_rows, COUNT(DISTINCT review_id) AS unique_reviews, COUNT(DISTINCT order_id) AS unique_orders
FROM order_reviews;

SELECT
    COUNT(*) AS orders_checked,
    COUNT(*) FILTER (WHERE ABS(i.items_total - p.paid) > 1) AS mismatch_over_1
FROM (SELECT order_id, SUM(price + freight_value) AS items_total FROM order_items GROUP BY order_id) i
JOIN (SELECT order_id, SUM(payment_value) AS paid FROM order_payments GROUP BY order_id) p ON p.order_id = i.order_id;

SELECT MIN(price) AS min_price, MAX(price) AS max_price, COUNT(*) FILTER (WHERE price <= 0) AS non_positive_price
FROM order_items;

SELECT COUNT(*) AS customer_ids, COUNT(DISTINCT customer_unique_id) AS unique_customers
FROM customers;

WITH c AS (
    SELECT cu.customer_unique_id, COUNT(*) AS n
    FROM orders o
    JOIN customers cu ON cu.customer_id = o.customer_id
    WHERE o.order_status <> 'canceled'
    GROUP BY 1
)
SELECT
    COUNT(*) AS customers,
    COUNT(*) FILTER (WHERE n > 1) AS repeat_customers,
    ROUND(100.0 * COUNT(*) FILTER (WHERE n > 1) / COUNT(*), 2) AS repeat_pct
FROM c;

SELECT
    COUNT(*) FILTER (WHERE p.product_category_name IS NULL) AS no_category,
    COUNT(*) FILTER (WHERE p.product_category_name IS NOT NULL AND t.product_category_name IS NULL) AS no_translation
FROM products p
LEFT JOIN product_category_name_translation t ON t.product_category_name = p.product_category_name;