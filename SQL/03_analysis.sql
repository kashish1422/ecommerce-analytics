-- =====================================================================
-- Olist E-commerce Analytics | 03_analysis.sql  (MySQL 8.0+)
-- Business questions on delivery performance, satisfaction, retention,
-- customer segments and payments. Requires 01 and 02 to have run.
-- =====================================================================

USE olist_analytics;

-- =====================================================================
-- 0. CLEAN ORDER-LEVEL VIEW
-- One row per delivered order (Jan 2017 - Aug 2018) with value, main
-- category, delivery timing, latest review and payment summary.
-- Mirrors the cleaning rules in Python/olist_analysis.ipynb.
-- =====================================================================
CREATE OR REPLACE VIEW v_orders AS
WITH item_totals AS (
    SELECT order_id,
           COUNT(*)           AS items,
           SUM(price)         AS product_value,
           SUM(freight_value) AS freight_value
    FROM order_items
    GROUP BY order_id
),
ranked_items AS (                       -- main category = most expensive item
    SELECT oi.order_id,
           COALESCE(t.product_category_name_english, 'unknown') AS main_category,
           ROW_NUMBER() OVER (PARTITION BY oi.order_id ORDER BY oi.price DESC, oi.order_item_id) AS rn
    FROM order_items oi
    JOIN products p                   ON p.product_id = oi.product_id
    LEFT JOIN category_translation t  ON t.product_category_name = p.product_category_name
),
ranked_reviews AS (                     -- some orders have several reviews: keep the latest
    SELECT order_id, review_score,
           ROW_NUMBER() OVER (PARTITION BY order_id ORDER BY review_answer_timestamp DESC) AS rn
    FROM order_reviews
),
ranked_payments AS (                    -- payment type of the largest payment
    SELECT order_id, payment_type,
           MAX(payment_installments) OVER (PARTITION BY order_id) AS installments,
           ROW_NUMBER() OVER (PARTITION BY order_id ORDER BY payment_value DESC) AS rn
    FROM order_payments
)
SELECT o.order_id,
       c.customer_unique_id,
       c.customer_state,
       o.order_purchase_timestamp,
       DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m')                                  AS purchase_month,
       o.order_estimated_delivery_date,
       o.order_delivered_customer_date,
       it.items,
       it.product_value,
       it.freight_value,
       it.product_value + it.freight_value                                               AS order_value,
       ri.main_category,
       TIMESTAMPDIFF(SECOND, o.order_purchase_timestamp, o.order_delivered_customer_date) / 86400.0 AS delivery_days,
       DATEDIFF(o.order_delivered_customer_date, o.order_estimated_delivery_date)        AS delay_days,
       CASE WHEN DATE(o.order_delivered_customer_date) > DATE(o.order_estimated_delivery_date)
            THEN 1 ELSE 0 END                                                            AS is_late,
       rr.review_score,
       rp.payment_type,
       rp.installments
FROM orders o
JOIN customers c          ON c.customer_id = o.customer_id
JOIN item_totals it       ON it.order_id = o.order_id
JOIN ranked_items ri      ON ri.order_id = o.order_id AND ri.rn = 1
LEFT JOIN ranked_reviews rr  ON rr.order_id = o.order_id AND rr.rn = 1
LEFT JOIN ranked_payments rp ON rp.order_id = o.order_id AND rp.rn = 1
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL
  AND o.order_purchase_timestamp >= '2017-01-01'
  AND o.order_purchase_timestamp <  '2018-09-01';


-- =====================================================================
-- 1. BUSINESS OVERVIEW
-- =====================================================================

-- 1.1 Headline KPIs
SELECT COUNT(*)                                AS delivered_orders,
       COUNT(DISTINCT customer_unique_id)      AS customers,
       ROUND(SUM(order_value), 2)              AS revenue,
       ROUND(AVG(order_value), 2)              AS avg_order_value,
       ROUND(AVG(delivery_days), 2)            AS avg_delivery_days,
       ROUND(AVG(is_late) * 100, 2)            AS late_rate_pct,
       ROUND(AVG(review_score), 2)             AS avg_review_score
FROM v_orders;

-- 1.2 Monthly revenue with month-over-month growth and running total
WITH monthly AS (
    SELECT purchase_month,
           COUNT(*)         AS orders,
           SUM(order_value) AS revenue
    FROM v_orders
    GROUP BY purchase_month
)
SELECT purchase_month,
       orders,
       ROUND(revenue, 2)                                                        AS revenue,
       ROUND(revenue / orders, 2)                                               AS avg_order_value,
       ROUND((revenue - LAG(revenue) OVER (ORDER BY purchase_month)) * 100.0
             / LAG(revenue) OVER (ORDER BY purchase_month), 1)                  AS mom_growth_pct,
       ROUND(SUM(revenue) OVER (ORDER BY purchase_month), 2)                    AS cumulative_revenue
FROM monthly
ORDER BY purchase_month;

-- 1.3 Top 10 categories by revenue, with share of total
WITH category AS (
    SELECT main_category,
           COUNT(*)            AS orders,
           SUM(order_value)    AS revenue,
           AVG(review_score)   AS avg_review,
           AVG(is_late)        AS late_rate
    FROM v_orders
    GROUP BY main_category
)
SELECT RANK() OVER (ORDER BY revenue DESC)                     AS revenue_rank,
       main_category,
       orders,
       ROUND(revenue, 2)                                       AS revenue,
       ROUND(revenue * 100.0 / SUM(revenue) OVER (), 1)        AS pct_of_revenue,
       ROUND(avg_review, 2)                                    AS avg_review,
       ROUND(late_rate * 100, 1)                               AS late_rate_pct
FROM category
ORDER BY revenue DESC
LIMIT 10;


-- =====================================================================
-- 2. DELIVERY PERFORMANCE
-- =====================================================================

-- 2.1 How accurate are the delivery estimates?
SELECT CASE WHEN delay_days < 0 THEN 'early'
            WHEN delay_days = 0 THEN 'on estimated day'
            ELSE 'late' END                                     AS delivery_vs_estimate,
       COUNT(*)                                                 AS orders,
       ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 1)       AS pct_orders,
       ROUND(AVG(delay_days), 1)                                AS avg_delay_days
FROM v_orders
GROUP BY delivery_vs_estimate
ORDER BY orders DESC;

-- 2.2 Late delivery rate by month (spikes around Black Friday and Feb-Mar 2018)
SELECT purchase_month,
       COUNT(*)                         AS orders,
       ROUND(AVG(is_late) * 100, 1)     AS late_rate_pct,
       ROUND(AVG(delivery_days), 1)     AS avg_delivery_days
FROM v_orders
GROUP BY purchase_month
ORDER BY purchase_month;

-- 2.3 States ranked by delivery speed
SELECT RANK() OVER (ORDER BY AVG(delivery_days) DESC)   AS slowest_rank,
       customer_state,
       COUNT(*)                                         AS orders,
       ROUND(AVG(delivery_days), 1)                     AS avg_delivery_days,
       ROUND(AVG(is_late) * 100, 1)                     AS late_rate_pct,
       ROUND(AVG(review_score), 2)                      AS avg_review
FROM v_orders
GROUP BY customer_state
ORDER BY slowest_rank;

-- 2.4 Sellers with the worst late rate (minimum 50 delivered orders)
WITH seller_orders AS (
    SELECT DISTINCT oi.seller_id, v.order_id, v.is_late, v.review_score
    FROM order_items oi
    JOIN v_orders v ON v.order_id = oi.order_id
)
SELECT so.seller_id,
       s.seller_state,
       COUNT(*)                           AS orders,
       ROUND(AVG(so.is_late) * 100, 1)    AS late_rate_pct,
       ROUND(AVG(so.review_score), 2)     AS avg_review
FROM seller_orders so
JOIN sellers s ON s.seller_id = so.seller_id
GROUP BY so.seller_id, s.seller_state
HAVING COUNT(*) >= 50
ORDER BY late_rate_pct DESC
LIMIT 10;


-- =====================================================================
-- 3. DELIVERY vs CUSTOMER SATISFACTION
-- =====================================================================

-- 3.1 Review score by delivery timing
SELECT CASE WHEN delay_days <= -15 THEN '1. 15+ days early'
            WHEN delay_days <= -8  THEN '2. 8-14 days early'
            WHEN delay_days <= -1  THEN '3. 1-7 days early'
            WHEN delay_days = 0    THEN '4. on the day'
            WHEN delay_days <= 3   THEN '5. 1-3 days late'
            WHEN delay_days <= 7   THEN '6. 4-7 days late'
            WHEN delay_days <= 14  THEN '7. 8-14 days late'
            ELSE                        '8. 15+ days late' END                 AS delivery_timing,
       COUNT(*)                                                                AS orders,
       ROUND(AVG(review_score), 2)                                             AS avg_review,
       ROUND(SUM(CASE WHEN review_score <= 2 THEN 1 ELSE 0 END) * 100.0
             / COUNT(review_score), 1)                                         AS pct_1_2_star
FROM v_orders
GROUP BY delivery_timing
ORDER BY delivery_timing;

-- 3.2 Late vs on-time: average score and share of bad reviews
SELECT CASE WHEN is_late = 1 THEN 'late' ELSE 'on time' END                    AS delivery,
       COUNT(*)                                                                AS orders,
       ROUND(AVG(review_score), 2)                                             AS avg_review,
       ROUND(SUM(CASE WHEN review_score <= 2 THEN 1 ELSE 0 END) * 100.0
             / COUNT(review_score), 1)                                         AS pct_1_2_star,
       ROUND(SUM(CASE WHEN review_score <= 2 THEN 1 ELSE 0 END) * 100.0
             / SUM(SUM(CASE WHEN review_score <= 2 THEN 1 ELSE 0 END)) OVER (), 1) AS pct_of_all_bad_reviews
FROM v_orders
GROUP BY delivery;


-- =====================================================================
-- 4. CUSTOMER RETENTION
-- =====================================================================

-- 4.1 Repeat purchase rate (customer_unique_id = the real customer)
WITH customer_orders AS (
    SELECT customer_unique_id, COUNT(*) AS orders, SUM(order_value) AS spend
    FROM v_orders
    GROUP BY customer_unique_id
)
SELECT COUNT(*)                                                         AS customers,
       SUM(CASE WHEN orders > 1 THEN 1 ELSE 0 END)                      AS repeat_customers,
       ROUND(SUM(CASE WHEN orders > 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS repeat_rate_pct,
       ROUND(SUM(CASE WHEN orders > 1 THEN spend ELSE 0 END) * 100.0 / SUM(spend), 1) AS repeat_revenue_pct
FROM customer_orders;

-- 4.2 Days between a customer's first and second order
WITH numbered AS (
    SELECT customer_unique_id,
           order_purchase_timestamp,
           ROW_NUMBER() OVER (PARTITION BY customer_unique_id ORDER BY order_purchase_timestamp) AS order_number,
           LAG(order_purchase_timestamp) OVER (PARTITION BY customer_unique_id ORDER BY order_purchase_timestamp) AS previous_order
    FROM v_orders
)
SELECT CASE WHEN DATEDIFF(order_purchase_timestamp, previous_order) <= 0  THEN '1. same day'
            WHEN DATEDIFF(order_purchase_timestamp, previous_order) <= 30 THEN '2. 1-30 days'
            WHEN DATEDIFF(order_purchase_timestamp, previous_order) <= 90 THEN '3. 31-90 days'
            WHEN DATEDIFF(order_purchase_timestamp, previous_order) <= 180 THEN '4. 91-180 days'
            ELSE '5. 180+ days' END                         AS gap_to_second_order,
       COUNT(*)                                             AS customers
FROM numbered
WHERE order_number = 2
GROUP BY gap_to_second_order
ORDER BY gap_to_second_order;

-- 4.3 Monthly cohort retention: % of each first-purchase cohort ordering again N months later
WITH first_purchase AS (
    SELECT customer_unique_id,
           MIN(order_purchase_timestamp) AS first_order
    FROM v_orders
    GROUP BY customer_unique_id
),
activity AS (
    SELECT DISTINCT
           DATE_FORMAT(f.first_order, '%Y-%m')                               AS cohort_month,
           v.customer_unique_id,
           (YEAR(v.order_purchase_timestamp) - YEAR(f.first_order)) * 12
             + MONTH(v.order_purchase_timestamp) - MONTH(f.first_order)      AS months_since_first
    FROM v_orders v
    JOIN first_purchase f ON f.customer_unique_id = v.customer_unique_id
),
cohort_counts AS (
    SELECT cohort_month, months_since_first, COUNT(*) AS active_customers
    FROM activity
    GROUP BY cohort_month, months_since_first
)
SELECT cohort_month,
       months_since_first,
       active_customers,
       FIRST_VALUE(active_customers) OVER (PARTITION BY cohort_month ORDER BY months_since_first) AS cohort_size,
       ROUND(active_customers * 100.0
             / FIRST_VALUE(active_customers) OVER (PARTITION BY cohort_month ORDER BY months_since_first), 2) AS retention_pct
FROM cohort_counts
ORDER BY cohort_month, months_since_first;


-- =====================================================================
-- 5. RFM CUSTOMER SEGMENTATION
-- Frequency is almost always 1, so it is used as repeat vs one-time.
-- Recency and monetary value are scored 1-5 with NTILE (5 = best).
-- =====================================================================
WITH snapshot AS (
    SELECT MAX(order_purchase_timestamp) AS snapshot_date FROM v_orders
),
customer_rfm AS (
    SELECT v.customer_unique_id,
           DATEDIFF(s.snapshot_date, MAX(v.order_purchase_timestamp)) + 1 AS recency_days,
           COUNT(*)                                                     AS frequency,
           SUM(v.order_value)                                           AS monetary
    FROM v_orders v
    CROSS JOIN snapshot s
    GROUP BY v.customer_unique_id, s.snapshot_date
),
scored AS (
    SELECT *,
           NTILE(5) OVER (ORDER BY recency_days DESC) AS r_score,
           NTILE(5) OVER (ORDER BY monetary ASC)      AS m_score
    FROM customer_rfm
),
segmented AS (
    SELECT *,
           CASE WHEN frequency > 1 AND r_score >= 3 THEN 'Loyal repeat'
                WHEN frequency > 1                  THEN 'Lapsed repeat'
                WHEN r_score >= 4 AND m_score >= 4  THEN 'New high-value'
                WHEN r_score >= 4                   THEN 'New low-value'
                WHEN r_score = 3                    THEN 'Cooling'
                WHEN m_score >= 4                   THEN 'At-risk high-value'
                ELSE                                     'Hibernating' END AS segment
    FROM scored
)
SELECT segment,
       COUNT(*)                                                    AS customers,
       ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 1)          AS pct_customers,
       ROUND(AVG(recency_days), 0)                                 AS avg_recency_days,
       ROUND(AVG(monetary), 2)                                     AS avg_spend,
       ROUND(SUM(monetary) * 100.0 / SUM(SUM(monetary)) OVER (), 1) AS pct_revenue
FROM segmented
GROUP BY segment
ORDER BY pct_revenue DESC;


-- =====================================================================
-- 6. PAYMENTS
-- =====================================================================

-- 6.1 Payment method mix
SELECT payment_type,
       COUNT(*)                                               AS orders,
       ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 1)     AS pct_orders,
       ROUND(AVG(order_value), 2)                             AS avg_order_value
FROM v_orders
WHERE payment_type IS NOT NULL
GROUP BY payment_type
ORDER BY orders DESC;

-- 6.2 Order value by number of instalments
SELECT CASE WHEN installments <= 1  THEN '1. paid in full'
            WHEN installments <= 3  THEN '2. 2-3'
            WHEN installments <= 6  THEN '3. 4-6'
            WHEN installments <= 10 THEN '4. 7-10'
            ELSE                         '5. 11+' END     AS installment_band,
       COUNT(*)                                           AS orders,
       ROUND(AVG(order_value), 2)                         AS avg_order_value,
       ROUND(AVG(review_score), 2)                        AS avg_review
FROM v_orders
WHERE installments IS NOT NULL
GROUP BY installment_band
ORDER BY installment_band;
