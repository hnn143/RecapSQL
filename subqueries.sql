USE magist;

#Select all the products from the health_beauty or perfumery categories that
#have been paid by credit card with a payment amount of more than 1000$,
#from orders that were purchased during 2018 and have a ‘delivered’ status?
CREATE TEMPORARY TABLE temp_quest
SELECT *
FROM products
WHERE product_category_name IN
	(SELECT product_category_name
		FROM product_category_name_translation
        WHERE product_category_name_english='health_beauty' OR  product_category_name_english='perfumery' )
	AND product_id in
        (SELECT oi.product_id
        FROM order_items oi
        WHERE oi.order_id IN
			(SELECT order_id
            FROM order_payments op
            WHERE op.payment_type='credit_card' AND op.payment_value>1000)
            AND
            oi.order_id IN
            (SELECT order_id
            FROM orders o
            WHERE o.order_status='delivered' AND YEAR(order_purchase_timestamp)=2018));
        
SELECT *
FROM temp_quest;
        
#For the products that you selected, get the following information:
# The average weight of those products
SELECT ROUND(AVG(product_weight_g),2) as avg_weight_g
FROM temp_quest; # 7952.56 g

#The cities where there are sellers that sell those products
SELECT DISTINCT city
FROM geo
WHERE zip_code_prefix IN
	(SELECT zip_code_prefix
	FROM sellers
    WHERE seller_id IN
		(SELECT seller_id
        FROM order_items
        WHERE product_id IN 
			(SELECT product_id
            FROM temp_quest)));

#The cities where there are customers who bought products
SELECT DISTINCT city
FROM geo
WHERE zip_code_prefix IN
	(SELECT zip_code_prefix
    FROM customers
    WHERE customer_id IN
		(SELECT customer_id
        FROM orders
        WHERE order_id IN
			(SELECT order_id
            FROM order_items
            WHERE product_id IN
				(SELECT product_id
                FROM temp_quest))));


SELECT * FROM temp_quest;