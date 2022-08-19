USE magist;

#################################################################################
################################ questions ######################################
#################################################################################
# Find the average review score by state of the customer
SELECT s.name, AVG(review_score) AS mean_review
FROM order_reviews orr
LEFT JOIN orders o using(order_id)
LEFT JOIN customers c using(customer_id)
LEFT JOIN geo g ON c.customer_zip_code_prefix=g.zip_code_prefix
LEFT JOIN states s ON g.state=s.subdivision
GROUP BY g.state;


# Do reviews containing positive words have a better score? Some Portuguese positive words are:
# “bom”, “otimo”, “gostei”, “recomendo” and “excelente”
SELECT *, positive_mean - overall_mean AS diff
FROM (
    SELECT s.name , AVG(review_score) AS overall_mean
	FROM order_reviews
	LEFT JOIN orders o using(order_id)
	LEFT JOIN customers c using(customer_id)
	LEFT JOIN geo g ON c.customer_zip_code_prefix=g.zip_code_prefix
	LEFT JOIN states s ON g.state=s.subdivision
	GROUP BY g.state) overall
LEFT JOIN (
	SELECT s.name , AVG(review_score) AS positive_mean
	FROM order_reviews
	LEFT JOIN orders o using(order_id)
	LEFT JOIN customers c using(customer_id)
	LEFT JOIN geo g ON c.customer_zip_code_prefix=g.zip_code_prefix
	LEFT JOIN states s ON g.state=s.subdivision
    WHERE review_comment_message REGEXP 'bom|otimo|gostei|recomendo|excelente' OR
		review_comment_title REGEXP 'bom|otimo|gostei|recomendo|excelente'
	GROUP BY g.state) positives using(name);

# Considering only states having at least 30 reviews containing these words, what is the state with the highest score?
SELECT *, positive_mean - overall_mean AS diff
FROM (
    SELECT s.name , AVG(review_score) AS overall_mean
	FROM order_reviews
	LEFT JOIN orders o using(order_id)
	LEFT JOIN customers c using(customer_id)
	LEFT JOIN geo g ON c.customer_zip_code_prefix=g.zip_code_prefix
	LEFT JOIN states s ON g.state=s.subdivision
	GROUP BY g.state) overall
RIGHT JOIN (
	SELECT s.name , AVG(review_score) AS positive_mean, COUNT(review_score) AS n_reviews
	FROM order_reviews
	LEFT JOIN orders o using(order_id)
	LEFT JOIN customers c using(customer_id)
	LEFT JOIN geo g ON c.customer_zip_code_prefix=g.zip_code_prefix
	LEFT JOIN states s ON g.state=s.subdivision
    WHERE review_comment_message REGEXP 'bom|otimo|gostei|recomendo|excelente' OR
		review_comment_title REGEXP 'bom|otimo|gostei|recomendo|excelente'
	GROUP BY g.state) positives using(name)
WHERE n_reviews>30
#ORDER BY overall_mean DESC;
ORDER BY positive_mean DESC;
# Paranai with highest overall_mean
# Rio Grande do Norte with highest positive_mean

#What is the state where there is a greater score change between all reviews and reviews containing positive words?
SELECT *, positive_mean - overall_mean AS diff
FROM (
    SELECT s.name , AVG(review_score) AS overall_mean
	FROM order_reviews
	LEFT JOIN orders o using(order_id)
	LEFT JOIN customers c using(customer_id)
	LEFT JOIN geo g ON c.customer_zip_code_prefix=g.zip_code_prefix
	LEFT JOIN states s ON g.state=s.subdivision
	GROUP BY g.state) overall
RIGHT JOIN (
	SELECT s.name , AVG(review_score) AS positive_mean, COUNT(review_score) AS n_reviews
	FROM order_reviews
	LEFT JOIN orders o using(order_id)
	LEFT JOIN customers c using(customer_id)
	LEFT JOIN geo g ON c.customer_zip_code_prefix=g.zip_code_prefix
	LEFT JOIN states s ON g.state=s.subdivision
    WHERE review_comment_message REGEXP 'bom|otimo|gostei|recomendo|excelente' OR
		review_comment_title REGEXP 'bom|otimo|gostei|recomendo|excelente'
	GROUP BY g.state) positives using(name)
WHERE n_reviews>30
ORDER BY diff DESC;
#Sergipe

###################################################
# Create a stored procedure that gets as input:
#    - The name of a state (the full name from the table you imported).
#    - The name of a product category (in English).
#    - A year
#	And outputs the average score for reviews left by customers from the given state for orders with
#	the status “delivered, containing at least a product in the given category, and placed on the given year.

DROP PROCEDURE IF EXISTS average_review;
DELIMITER $$
CREATE PROCEDURE average_review( IN cust_state VARCHAR(10), IN cat VARCHAR(10), IN y INT)
BEGIN
SELECT AVG(review_score) AS avg_review
FROM order_reviews
WHERE order_id IN (
	SELECT order_id
    FROM orders
    WHERE order_status='delivered' AND
		YEAR(order_purchase_timestamp)=y AND
        order_id IN
			(SELECT order_id
            FROM order_items
            WHERE product_id IN
				(SELECT product_id
                FROM products
                WHERE product_category_name IN 
					(SELECT product_category_name
                    FROM product_category_name_translation
                    WHERE product_category_name_english=cat))) AND
		customer_id IN
            (SELECT customer_id
            FROM customers
            WHERE customer_zip_code_prefix IN
				(SELECT zip_code_prefix
                FROM geo
                WHERE state IN
					(SELECT subdivision
                    FROM states
                    WHERE name=cust_state))));
END $$
DELIMITER ;

CALL average_review('Acre','perfumery', 2017);
# avg. review score 4.67

#########################################################
##################### to compare ########################
#########################################################
# for state 'Acre' and year 2017 and category 'perfumery':
# average review score 4.67

SELECT AVG(review_score) AS avg_review
FROM order_reviews
WHERE order_id IN (
	SELECT order_id
    FROM orders
    WHERE order_status='delivered' AND
		YEAR(order_purchase_timestamp)=2017 AND
        order_id IN
			(SELECT order_id
            FROM order_items
            WHERE product_id IN
				(SELECT product_id
                FROM products
                WHERE product_category_name IN 
					(SELECT product_category_name
                    FROM product_category_name_translation
                    WHERE product_category_name_english='perfumery'))) AND
		customer_id IN
            (SELECT customer_id
            FROM customers
            WHERE customer_zip_code_prefix IN
				(SELECT zip_code_prefix
                FROM geo
                WHERE state IN
					(SELECT subdivision
                    FROM states
                    WHERE name='Acre'))));
