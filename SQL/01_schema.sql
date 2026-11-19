-- =====================================================================
-- Olist E-commerce Analytics | 01_schema.sql
-- Creates the database and the 8 raw tables (MySQL 8.0+).
-- Run order: 01_schema.sql -> 02_load_data.sql -> 03_analysis.sql
-- =====================================================================

CREATE DATABASE IF NOT EXISTS olist_analytics;
USE olist_analytics;

DROP TABLE IF EXISTS order_reviews, order_payments, order_items, orders,
                     products, sellers, customers, category_translation;

CREATE TABLE customers (
    customer_id              CHAR(32)     NOT NULL PRIMARY KEY,  -- one per ORDER, not per person
    customer_unique_id       CHAR(32)     NOT NULL,              -- the real customer
    customer_zip_code_prefix CHAR(5)      NOT NULL,
    customer_city            VARCHAR(60)  NOT NULL,
    customer_state           CHAR(2)      NOT NULL,
    INDEX idx_customers_unique (customer_unique_id)
);

CREATE TABLE sellers (
    seller_id              CHAR(32)    NOT NULL PRIMARY KEY,
    seller_zip_code_prefix CHAR(5)     NOT NULL,
    seller_city            VARCHAR(60) NOT NULL,
    seller_state           CHAR(2)     NOT NULL
);

CREATE TABLE category_translation (
    product_category_name         VARCHAR(60) NOT NULL PRIMARY KEY,
    product_category_name_english VARCHAR(60) NOT NULL
);

CREATE TABLE products (
    product_id                 CHAR(32)    NOT NULL PRIMARY KEY,
    product_category_name      VARCHAR(60) NULL,
    product_name_length        INT         NULL,
    product_description_length INT         NULL,
    product_photos_qty         INT         NULL,
    product_weight_g           INT         NULL,
    product_length_cm          INT         NULL,
    product_height_cm          INT         NULL,
    product_width_cm           INT         NULL
);

CREATE TABLE orders (
    order_id                      CHAR(32)    NOT NULL PRIMARY KEY,
    customer_id                   CHAR(32)    NOT NULL,
    order_status                  VARCHAR(15) NOT NULL,
    order_purchase_timestamp      DATETIME    NOT NULL,
    order_approved_at             DATETIME    NULL,
    order_delivered_carrier_date  DATETIME    NULL,
    order_delivered_customer_date DATETIME    NULL,
    order_estimated_delivery_date DATETIME    NOT NULL,
    INDEX idx_orders_customer (customer_id),
    INDEX idx_orders_purchase (order_purchase_timestamp),
    CONSTRAINT fk_orders_customer FOREIGN KEY (customer_id) REFERENCES customers (customer_id)
);

CREATE TABLE order_items (
    order_id            CHAR(32)      NOT NULL,
    order_item_id       INT           NOT NULL,
    product_id          CHAR(32)      NOT NULL,
    seller_id           CHAR(32)      NOT NULL,
    shipping_limit_date DATETIME      NOT NULL,
    price               DECIMAL(10,2) NOT NULL,
    freight_value       DECIMAL(10,2) NOT NULL,
    PRIMARY KEY (order_id, order_item_id),
    CONSTRAINT fk_items_order   FOREIGN KEY (order_id)   REFERENCES orders (order_id),
    CONSTRAINT fk_items_product FOREIGN KEY (product_id) REFERENCES products (product_id),
    CONSTRAINT fk_items_seller  FOREIGN KEY (seller_id)  REFERENCES sellers (seller_id)
);

CREATE TABLE order_payments (
    order_id             CHAR(32)      NOT NULL,
    payment_sequential   INT           NOT NULL,
    payment_type         VARCHAR(20)   NOT NULL,
    payment_installments INT           NOT NULL,
    payment_value        DECIMAL(10,2) NOT NULL,
    PRIMARY KEY (order_id, payment_sequential),
    CONSTRAINT fk_payments_order FOREIGN KEY (order_id) REFERENCES orders (order_id)
);

-- review_id is NOT unique in the source data, so a surrogate key is used.
CREATE TABLE order_reviews (
    review_row_id           INT          NOT NULL AUTO_INCREMENT PRIMARY KEY,
    review_id               CHAR(32)     NOT NULL,
    order_id                CHAR(32)     NOT NULL,
    review_score            TINYINT      NOT NULL,
    review_comment_title    VARCHAR(255) NULL,
    review_comment_message  TEXT         NULL,
    review_creation_date    DATETIME     NOT NULL,
    review_answer_timestamp DATETIME     NOT NULL,
    INDEX idx_reviews_order (order_id),
    CONSTRAINT fk_reviews_order FOREIGN KEY (order_id) REFERENCES orders (order_id)
);
