USE magist;

#With a query that includes window functions, select all orders with their corresponding products in order_items.
#We want only the orders with a shipping_limit_date before midnight 2016-10-09. Add a column called total_order_price
#with a sum of the price of all products belonging to the same order. And add another column showing how many products
#were in each order. The output should look like the example below.
SELECT order_id, product_id, price,
	SUM(price) OVER(PARTITION BY order_id) AS total_order_price ,
    COUNT(product_id) OVER(PARTITION BY order_id) AS no_of_products
FROM order_items
LEFT JOIN orders using(order_id) 
WHERE DATE(shipping_limit_date)<'2016-10-10';

#Select purchased items from order_items that meet these conditions:
#Their order_purchase_timestamp date is 2016-10-09
SELECT product_id , product_category_name_english, price,
	ROUND(AVG(price) OVER(PARTITION BY product_category_name_english),2) AS avg_category_payment,
    ROUND(SUM(price) OVER(PARTITION BY product_category_name_english),2) AS category_total_sales
FROM order_items oi
LEFT JOIN orders o using(order_id) 
LEFT JOIN products p using(product_id)
LEFT JOIN product_category_name_translation using(product_category_name)
WHERE DATE(order_purchase_timestamp)='2016-10-09' 
	AND order_status='delivered'
ORDER BY category_total_sales DESC;

select * from orders;