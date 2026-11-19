# Data Dictionary

Source: [Brazilian E-Commerce Public Dataset by Olist](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce) (Kaggle, CC BY-NC-SA 4.0). The geolocation table (1M rows, 61 MB) is not used.

## Raw tables (`Data/Raw/`)

| Table | Rows | Grain | Key columns |
|---|---:|---|---|
| `olist_orders_dataset` | 99,441 | one order | `order_id`, `customer_id`, `order_status`, purchase / approved / carrier / delivered / estimated timestamps |
| `olist_customers_dataset` | 99,441 | one order's customer record | `customer_id` (per order), `customer_unique_id` (per person), city, state |
| `olist_order_items_dataset` | 112,650 | one item in an order | `order_id`, `order_item_id`, `product_id`, `seller_id`, `price`, `freight_value` |
| `olist_order_payments_dataset` | 103,886 | one payment for an order | `order_id`, `payment_sequential`, `payment_type`, `payment_installments`, `payment_value` |
| `olist_order_reviews_dataset` | 99,224 | one review | `review_id` (not unique), `order_id`, `review_score` 1–5, comments, timestamps |
| `olist_products_dataset` | 32,951 | one product | `product_id`, `product_category_name` (Portuguese), size and weight |
| `olist_sellers_dataset` | 3,095 | one seller | `seller_id`, city, state |
| `product_category_name_translation` | 71 | one category | Portuguese → English name (2 missing, added during cleaning) |

### Relationships

```text
customers 1──* orders 1──* order_items *──1 products ──1 category_translation
                  │               └────*──1 sellers
                  ├──* order_payments
                  └──* order_reviews
```

## Processed tables (`Data/Processed/`, created by the notebook)

### `orders_clean.csv`: one row per delivered order (96,203 rows)

| Column | Description |
|---|---|
| `order_id` | Order key |
| `customer_unique_id` | The real customer (use this for retention) |
| `customer_state`, `customer_city` | Delivery location |
| `order_purchase_timestamp`, `purchase_month` | When the order was placed |
| `order_estimated_delivery_date`, `order_delivered_customer_date` | Promised vs actual delivery |
| `items`, `sellers` | Number of items and distinct sellers in the order |
| `product_value`, `freight_value`, `order_value` | R$; `order_value` = product + freight |
| `main_category` | English category of the most expensive item (`unknown` if missing) |
| `delivery_days` | Days from purchase to delivery (decimal) |
| `delay_days` | Delivered date − estimated date in calendar days (negative = early) |
| `is_late` | 1 if delivered after the estimated date |
| `review_score` | Latest review score for the order (blank if none) |
| `payment_type` | Method of the largest payment |
| `installments` | Maximum instalments used |

### `customers_rfm.csv`: one row per customer (93,096 rows)

| Column | Description |
|---|---|
| `frequency` | Delivered orders in the period |
| `monetary` | Total spend (R$) |
| `recency_days` | Days since the last order (snapshot = last order date + 1 day) |
| `r_score`, `m_score` | Quintile scores 1–5 (5 = most recent / highest spend) |
| `segment` | Loyal repeat, Lapsed repeat, New high-value, New low-value, Cooling, At-risk high-value, Hibernating |

### `cohort_retention.csv`

`first_month`, `months_since_first`, `retention_pct`, `cohort_size`: the cohort retention matrix in long format.
