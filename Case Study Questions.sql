/* --------------------
   Case Study Questions
   --------------------*/

-- 1. What is the total amount each customer spent at the restaurant?
SELECT 
    sales.customer_id as Customer, 
    SUM(menu.price) Total
FROM
    sales
        LEFT JOIN
    menu ON sales.product_id = menu.product_id
GROUP BY sales.customer_id;
/*
############ Answer ############
Customer A spent a total of $76
Customer B spent a total of $74
Customer C spent a total of $36
############ Answer ############
*/

-- 2. How many days has each customer visited the restaurant?
SELECT 
    customer_id as Customer,
    count(DISTINCT(order_date)) as Visit
FROM
    sales
GROUP BY
	Customer;
/*
############ Answer ############
Customer A has visited the restaurant 4 times
Customer B has visited the restaurant 6 times
Customer C has visited the restaurant 2 times
############ Answer ############
*/

-- 3. What was the first item from the menu purchased by each customer?
WITH FirstPurchaseItem AS (
    SELECT 
		sales.customer_id, 
		menu.product_name, 
        sales.order_date,
		DENSE_RANK () OVER (PARTITION BY sales.customer_id ORDER BY sales.order_date) AS OrderRank
	FROM 
		sales  
			LEFT JOIN 
		menu ON sales.product_id = menu.product_id
)
SELECT 
    customer_id, 
    MIN(product_name) AS first_purchased_item
FROM 
    FirstPurchaseItem	
WHERE 
    OrderRank = 1
GROUP BY 
    customer_id;
/*
############ Answer ############
The first item purchased by A was sushi or curry
The first item purchased by b was curry
The first item purchased by A was ramen
############ Answer ############
*/

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
SELECT 
    menu.product_name AS Product,
    COUNT(sales.product_id) AS 'Times Purchased'
FROM
    sales
        LEFT JOIN
    menu ON sales.product_id = menu.product_id
GROUP BY 
	menu.product_name
ORDER BY 
	COUNT(sales.product_id) DESC
LIMIT 
	1;
/*
############ Answer ############
The most purchased item was Ramen with a total of 8 purchases
############ Answer ############
*/

-- 5. Which item was the most popular for each customer?
WITH MostPopular AS(
		SELECT
		sales.customer_id,
        menu.product_name,
        COUNT(sales.product_id) as TimesPurchased,
        RANK() OVER (PARTITION BY sales.customer_id ORDER BY COUNT(sales.product_id) DESC) as ItemRank
	FROM
		sales
			LEFT JOIN
		menu ON sales.product_id = menu.product_id
	GROUP BY sales.customer_id,sales.product_id,menu.product_name
)
select
	customer_id,
    product_name,
    TimesPurchased
FROM
	MostPopular
WHERE ItemRank = 1
ORDER BY customer_id, TimesPurchased;

/*
############ Answer ############
Customer A has the ramen product as the most popular, being purchased 3 times
Customer B has curry, sushi and ramen as the most popular products, each being purchased twice
Customer C has the ramen product as the most popular, being purchased 3 times
############ Answer ############
*/

-- 6. Which item was purchased first by the customer after they became a member?
WITH FirstPurchaseMember AS (
	SELECT 
		sales.customer_id, 
        sales.order_date, 
        menu.product_name,
		DENSE_RANK () OVER (PARTITION BY sales.customer_id ORDER BY sales.order_date) AS RankOrder
	FROM 
		sales
			LEFT JOIN 
		members ON sales.customer_id = members.customer_id
			LEFT JOIN 
		menu ON sales.product_id = menu.product_id
	WHERE 
		sales.order_date >= members.join_date
)
SELECT 
	customer_id, 
    product_name
FROM 
	FirstPurchaseMember
WHERE 
	RankOrder = 1;
/*
############ Answer ############
The first product purchased by A after becoming a member was curry
The first product purchased by B after becoming a member was sushi.
Customer C has not yet become a member
############ Answer ############
*/

-- 7. Which item was purchased just before the customer became a member?
WITH NotMemberPurchase AS (
	SELECT 
		sales.customer_id, 
		sales.order_date, 
        menu.product_name,
		DENSE_RANK () OVER (PARTITION BY sales.customer_id ORDER BY sales.order_date DESC) AS RankOrderDate
	FROM 
		sales
			LEFT JOIN 
		members ON sales.customer_id = members.customer_id
			LEFT JOIN 
		menu ON sales.product_id = menu.product_id
	WHERE 
		sales.order_date < members.join_date
)
SELECT 
	customer_id, 
    product_name
FROM 
	NotMemberPurchase
WHERE 
	RankOrderDate = 1;
/*
############ Answer ############
The last product purchased by A before becoming a member was sushi or curry
The last product purchased by B before becoming a member was sushi.
Customer C has not yet become a member
############ Answer ############
*/

-- 8. What is the total items and amount spent for each member before they became a member?
# Total Amount
SELECT 
    sales.customer_id AS Customer,
    SUM(menu.price) AS 'Total Amount'
FROM 
    sales
	JOIN 
		members ON sales.customer_id = members.customer_id 
	JOIN 
		menu ON sales.product_id = menu.product_id
WHERE 
	sales.order_date < members.join_date
GROUP BY 
	sales.customer_id
ORDER BY 
	SUM(menu.price) desc;
/*
############ Answer ############
The total amount spent by customer A before becoming a member was 25$
The total amount spent by customer B, before becoming a member was 40$
Customer C has not yet become a member
############ Answer ############
*/

# Total Itens
SELECT 
    sales.customer_id AS Customer,
    Count(menu.product_id) as 'Total Itens'
FROM 
    sales
	JOIN 
		members ON sales.customer_id = members.customer_id 
	JOIN 
		menu ON sales.product_id = menu.product_id
WHERE 
	sales.order_date < members.join_date
GROUP BY
	sales.customer_id
ORDER BY 
	Count(menu.product_id) desc;
/*
############ Answer ############
The total number of items purchased by customer A before becoming a member was 2 items
The total number of items purchased by customer B before becoming a member was 3 items
Customer C has not yet become a member
############ Answer ############
*/

-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
select 
	sales.customer_id,
    SUM(CASE
		WHEN product_name = 'sushi' THEN 20 * price
        ELSE 10 * price
        END) as Points
from
	sales
	LEFT JOIN
		menu ON sales.product_id = menu.product_id
GROUP BY 
	sales.customer_id
ORDER BY 
	Points desc;
/*
############ Answer ############
Customer A would have 860 points
Customer B would have 940 points
Customer C would have 360 points
############ Answer ############
*/

-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
SELECT 
	sales.customer_id, 
	SUM(CASE 
			WHEN sales.order_date BETWEEN members.join_date AND members.join_date + 6 THEN menu.price * 20
			WHEN menu.product_name = 'sushi' THEN menu.price * 20
		ELSE menu.price*10
		END) AS total_points
FROM members
      LEFT JOIN 
	sales USING (customer_id)
      LEFT JOIN 
	menu USING (product_id)
GROUP BY 
	sales.customer_id
ORDER BY 
	sales.customer_id;
/*
############ Answer ############
Customer A would have 1370 points
Customer B would have 940 points
############ Answer ############
*/