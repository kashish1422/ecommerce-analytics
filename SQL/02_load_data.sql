-- =====================================================================
-- Olist E-commerce Analytics | 02_load_data.sql
-- Loads the raw CSVs from Data/Raw/ into the tables (MySQL 8.0+).
--
-- Before running:
--   1. Enable local file loading:  SET GLOBAL local_infile = 1;
--      and connect with it on:      mysql --local-infile=1 -u root -p
--   2. Run this script from the repository root, or replace 'Data/Raw/'
--      with the absolute path to the folder on your machine.
-- Empty strings in the CSVs are converted to NULL with NULLIF.
-- =====================================================================

USE olist_analytics;
SET FOREIGN_KEY_CHECKS = 0;

LOAD DATA LOCAL INFILE 'Data/Raw/olist_customers_dataset.csv'
INTO TABLE customers
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

LOAD DATA LOCAL INFILE 'Data/Raw/olist_sellers_dataset.csv'
INTO TABLE sellers
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

-- This file uses Windows line endings and starts with a byte-order mark
-- (the BOM sits in the header row, which is skipped).
LOAD DATA LOCAL INFILE 'Data/Raw/product_category_name_translation.csv'
INTO TABLE category_translation
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES;

-- Two categories are missing from the translation file.
INSERT INTO category_translation VALUES
    ('pc_gamer', 'pc_gamer'),
    ('portateis_cozinha_e_preparadores_de_alimentos', 'kitchen_portables_and_food_preparers');

LOAD DATA LOCAL INFILE 'Data/Raw/olist_products_dataset.csv'
INTO TABLE products
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(product_id, @category, @name_len, @desc_len, @photos, @weight, @length, @height, @width)
SET product_category_name      = NULLIF(@category, ''),
    product_name_length        = NULLIF(@name_len, ''),
    product_description_length = NULLIF(@desc_len, ''),
    product_photos_qty         = NULLIF(@photos, ''),
    product_weight_g           = NULLIF(@weight, ''),
    product_length_cm          = NULLIF(@length, ''),
    product_height_cm          = NULLIF(@height, ''),
    product_width_cm           = NULLIF(@width, '');

LOAD DATA LOCAL INFILE 'Data/Raw/olist_orders_dataset.csv'
INTO TABLE orders
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(order_id, customer_id, order_status, order_purchase_timestamp, @approved, @carrier, @delivered, order_estimated_delivery_date)
SET order_approved_at             = NULLIF(@approved, ''),
    order_delivered_carrier_date  = NULLIF(@carrier, ''),
    order_delivered_customer_date = NULLIF(@delivered, '');

LOAD DATA LOCAL INFILE 'Data/Raw/olist_order_items_dataset.csv'
INTO TABLE order_items
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

LOAD DATA LOCAL INFILE 'Data/Raw/olist_order_payments_dataset.csv'
INTO TABLE order_payments
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

-- Review comments contain commas and line breaks inside quotes.
LOAD DATA LOCAL INFILE 'Data/Raw/olist_order_reviews_dataset.csv'
INTO TABLE order_reviews
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(review_id, order_id, review_score, @title, @message, review_creation_date, review_answer_timestamp)
SET review_comment_title   = NULLIF(@title, ''),
    review_comment_message = NULLIF(@message, '');

SET FOREIGN_KEY_CHECKS = 1;

-- ---------------------------------------------------------------------
-- Validation: these counts must match the source files.
-- Expected: customers 99441 | sellers 3095 | category_translation 73
--           products 32951 | orders 99441 | order_items 112650
--           order_payments 103886 | order_reviews 99224
-- ---------------------------------------------------------------------
SELECT 'customers' AS table_name, COUNT(*) AS row_count FROM customers
UNION ALL SELECT 'sellers', COUNT(*) FROM sellers
UNION ALL SELECT 'category_translation', COUNT(*) FROM category_translation
UNION ALL SELECT 'products', COUNT(*) FROM products
UNION ALL SELECT 'orders', COUNT(*) FROM orders
UNION ALL SELECT 'order_items', COUNT(*) FROM order_items
UNION ALL SELECT 'order_payments', COUNT(*) FROM order_payments
UNION ALL SELECT 'order_reviews', COUNT(*) FROM order_reviews;
