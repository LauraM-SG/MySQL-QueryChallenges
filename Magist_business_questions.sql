-- EXPLORING TABLES 
Use magist;

-- 1. How many orders are there in the dataset? / Total Orders
Select count(order_id) as order_count FROM magist.orders;
-- option 2
Select count(*) as order_count FROM magist.orders;

-- 2. Are orders actually delivered? / Delivered orders 
Select count(order_status) as total_status, order_status FROM magist.orders 
group by order_status;
-- option 2
SELECT order_status, COUNT(*) AS orders FROM    magist.orders 
GROUP BY order_status;

-- 3. Is Magist having user growth? / User behavior
Select year(order_purchase_timestamp) as year_ordered,month(order_purchase_timestamp) as month_ordered, count(order_id) from magist.orders
 group by year_ordered, month_ordered
 order by year_ordered;
 
 -- Option 2
 SELECT 
    YEAR(order_purchase_timestamp) AS year_,
    MONTH(order_purchase_timestamp) AS month_,
    COUNT(customer_id)
FROM     orders
GROUP BY year_ , month_
ORDER BY year_ , month_;
 
 -- 4. How many products are there on the products table? / Total products
 Select count(distinct product_id) as total_products from magist.products;
 
 -- 5. Which are the categories with the most products? 
 Select count(distinct product_id) as total_products, product_category_name from magist.products 
 group by product_category_name 
 order by total_products desc;
 
 -- 6. How many of those products were present in actual transactions?
  Select count(distinct product_id) as total_products from magist.order_items where order_item_id > 0;
  -- as an additional idea: I join the tables Order and Order items to check the actual transactions and then chect if all orders involved products 
 Select  order_item_id as total_order_items, o.order_id as total_orders_id, oi.product_id from magist.orders as o 
 left join magist.order_items as oi on o.order_id=oi.order_id;
  
  -- 7. What’s the price for the most expensive and cheapest products?
  Select max(price) as most_expensive, min(price) as cheapest from order_items;
  
  -- 8. What are the highest and lowest payment values?
   Select max(payment_value) as highest_payment, min(payment_value) as lowest_payment from order_payments;
-- Maximum someone has paid for an order:
Select sum(payment_value) as highest_payment_order from order_payments 
group by order_id
order by highest_payment_order desc limit 1;

-- ****************************************************************************

/*****  ANSWER BUSINESS QUESTIONS 

In relation to the products:
*****/
-- How many products of these tech categories have been sold? 
SELECT COUNT(DISTINCT(oi.product_id)) AS tech_products_sold
FROM order_items oi
LEFT JOIN products p 
	USING (product_id)
LEFT JOIN product_category_name_translation pt
	USING (product_category_name)
WHERE product_category_name_english = "audio"
OR product_category_name_english =  "electronics"
OR product_category_name_english =  "computers_accessories"
OR product_category_name_english =  "computers"
OR product_category_name_english =  "pc_gamer"
OR product_category_name_english =  "tablets_printing_image"
OR product_category_name_english =  "telephony";

-- What percentage does that represent from the overall number of products sold?
SELECT COUNT(DISTINCT(product_id)) AS products_sold
FROM order_items;
-- percentage
SELECT 3390 / 32951; 

-- What’s the average price of the products being sold?
Select round(avg(price),2) from order_items;

-- Are expensive tech products popular? 
Select count(distinct oi.product_id) as Total_products,
CASE
	when price > 1000 then "Expensive"
    when price > 100 then "Mid-range"
    else "Cheap"
END AS "Price_range"   
FROM magist.order_items oi
LEFT JOIN magist.products p
	USING (product_id)
LEFT JOIN magist.product_category_name_translation pcnt
	USING (product_category_name)
WHERE pcnt.product_category_name_english 
	in ("audio", "electronics", "computers_accessories", "pc_gamer", "computers", "tablets_printing_image")
GROUP BY Price_range
Order by 1 Desc;

/****************************
In relation to the sellers:
*****/

-- How many months of data are included in the magist database?
SELECT 
    TIMESTAMPDIFF(MONTH,
        MIN(order_purchase_timestamp),
        MAX(order_purchase_timestamp))
FROM
    orders;
	-- 25 months
    
-- How many sellers are there?
SELECT 
    COUNT(DISTINCT seller_id)
FROM
    sellers;
	-- 3095
    
-- How many Tech sellers are there? 
SELECT 
    COUNT(DISTINCT seller_id) as Total_sellers
FROM
    sellers
        LEFT JOIN
    order_items USING (seller_id)
        LEFT JOIN
    products p USING (product_id)
        LEFT JOIN
    product_category_name_translation pt USING (product_category_name)
WHERE
    pt.product_category_name_english IN ('audio' , 'electronics',
        'computers_accessories',
        'pc_gamer',
        'computers',
        'tablets_printing_image',
        'telephony');
	-- 454

-- What percentage of overall sellers are Tech sellers?
SELECT (454 / 3095) * 100;
	-- 14.67%
    
 -- What is the total amount earned by all sellers?
	-- we use price from order_items and not payment_value from order_payments as an order may contain tech and non tech product. With payment_value we can't distinguish between items in an order
SELECT 
    SUM(oi.price) AS total
FROM
    order_items oi
        LEFT JOIN
    orders o USING (order_id)
WHERE
    o.order_status NOT IN ('unavailable' , 'canceled');
    -- 13494400.74
    
-- the average monthly income of all sellers?
SELECT 13494400.74/ 3095 / 25;
	-- 174.40

-- What is the total amount earned by all Tech sellers?
SELECT 
    SUM(oi.price) AS total
FROM
    order_items oi
        LEFT JOIN
    orders o USING (order_id)
        LEFT JOIN
    products p USING (product_id)
        LEFT JOIN
    product_category_name_translation pt USING (product_category_name)
WHERE
    o.order_status NOT IN ('unavailable' , 'canceled')
        AND pt.product_category_name_english IN ('audio' , 'electronics',
        'computers_accessories',
        'pc_gamer',
        'computers',
        'tablets_printing_image',
        'telephony');
	-- 1666211.28
    
-- the average monthly income of Tech sellers?
SELECT 1666211.28 / 454 / 25;
	-- 146.80

/*********************************
In relation to the delivery time:
*****/

-- What’s the average time between the order being placed and the product being delivered?
SELECT AVG(DATEDIFF(order_delivered_customer_date, order_purchase_timestamp))
FROM orders;
	-- 12.5035

-- How many orders are delivered on time vs orders delivered with a delay?
SELECT 
    CASE 
        WHEN DATEDIFF(order_estimated_delivery_date, order_delivered_customer_date) > 0 THEN 'Delayed' 
        ELSE 'On time'
    END AS delivery_status, 
COUNT(DISTINCT order_id) AS orders_count
FROM orders
WHERE order_status = 'delivered'
AND order_estimated_delivery_date IS NOT NULL
AND order_delivered_customer_date IS NOT NULL
GROUP BY delivery_status;
	-- on time 7999
    -- delayed 88471

-- Is there any pattern for delayed orders, e.g. big products being delayed more often?
SELECT
    CASE 
        WHEN DATEDIFF(order_estimated_delivery_date, order_delivered_customer_date) >= 100 THEN "> 100 day Delay"
        WHEN DATEDIFF(order_estimated_delivery_date, order_delivered_customer_date) >= 7 AND DATEDIFF(order_estimated_delivery_date, order_delivered_customer_date) < 100 THEN "1 week to 100 day delay"
        WHEN DATEDIFF(order_estimated_delivery_date, order_delivered_customer_date) > 3 AND DATEDIFF(order_estimated_delivery_date, order_delivered_customer_date) < 7 THEN "4-7 day delay"
        WHEN DATEDIFF(order_estimated_delivery_date, order_delivered_customer_date) >= 1  AND DATEDIFF(order_estimated_delivery_date, order_delivered_customer_date) <= 3 THEN "1-3 day delay"
        WHEN DATEDIFF(order_estimated_delivery_date, order_delivered_customer_date) > 0  AND DATEDIFF(order_estimated_delivery_date, order_delivered_customer_date) < 1 THEN "less than 1 day delay"
        WHEN DATEDIFF(order_estimated_delivery_date, order_delivered_customer_date) <= 0 THEN 'On time' 
    END AS "delay_range", 
    AVG(product_weight_g) AS weight_avg,
    MAX(product_weight_g) AS max_weight,
    MIN(product_weight_g) AS min_weight,
    SUM(product_weight_g) AS sum_weight,
    COUNT(DISTINCT a.order_id) AS orders_count
FROM orders a
LEFT JOIN order_items b
    USING (order_id)
LEFT JOIN products c
    USING (product_id)
WHERE order_estimated_delivery_date IS NOT NULL
AND order_delivered_customer_date IS NOT NULL
AND order_status = 'delivered'
GROUP BY delay_range;

