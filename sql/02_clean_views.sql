DROP VIEW IF EXISTS v_reviews, v_products;
DROP VIEW IF EXISTS v_orders;
DROP TABLE IF EXISTS v_orders;

CREATE TABLE v_orders AS
SELECT
    o.order_id,
    cu.customer_unique_id,
    cu.customer_state,
    o.order_purchase_timestamp AS purchased_at,
    o.order_delivered_customer_date AS delivered_at,
    o.order_estimated_delivery_date AS estimated_at,
    r.items_price,
    r.freight,
    r.items_price + r.freight AS revenue
FROM orders o
JOIN customers cu ON cu.customer_id = o.customer_id
JOIN (
    SELECT order_id, SUM(price) AS items_price, SUM(freight_value) AS freight
    FROM order_items
    GROUP BY order_id
) r ON r.order_id = o.order_id
WHERE o.order_status = 'delivered'
  AND o.order_purchase_timestamp >= TIMESTAMP '2017-01-01'
  AND o.order_purchase_timestamp < TIMESTAMP '2018-09-01';

CREATE INDEX idx_v_orders_customer ON v_orders (customer_unique_id, purchased_at);
ANALYZE v_orders;

CREATE VIEW v_reviews AS
SELECT DISTINCT ON (order_id) order_id, review_score
FROM order_reviews
ORDER BY order_id, review_creation_date DESC, review_answer_timestamp DESC;

CREATE VIEW v_products AS
SELECT
    p.product_id,
    COALESCE(t.product_category_name_english, p.product_category_name, 'unknown') AS category
FROM products p
LEFT JOIN product_category_name_translation t ON t.product_category_name = p.product_category_name;