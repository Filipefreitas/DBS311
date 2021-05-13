-- ***********************
-- Student Name: Filipe da Cunha de Freitas
-- Student1 ID: 155737190
-- Date: 2021-02-19
-- Purpose: Assignment 1 - DBS311
-- ***********************

-- Q1: Display the employee number, full employee name, job title, and hire date of all employees hired in September with the most recently hired employees displayed first.
-- Q1 SOLUTION --
SELECT
    employee_id AS "Employee Number"
    , last_name || ' ,' || first_name AS "Full name"
    , job_title AS "Job Title"
    , ' [' || TO_CHAR(hire_date, 'Month ddth" of "yyyy') || ' ]' AS "Start date"
FROM employees
WHERE EXTRACT(MONTH FROM hire_date) = 9
ORDER BY hire_date DESC;

-- Q2: The company wants to see the total sale amount per sales person (salesman) for all orders. Assume that online orders do not have any sales representative. 
-- For online ders (orders with no salesman ID), consider the salesman ID as 0. 
-- Display the salesman ID and the total sale amount for each employee.
-- Sort the result according to employee number.
-- Q2 SOLUTION --
SELECT
    COALESCE(o.salesman_id, 0) AS "Employee Number" 
    , TO_CHAR(SUM(i.quantity * i.unit_price), '$999,999,999.99') AS "Total Sale"
FROM order_items i
LEFT JOIN orders o
ON i.order_id = o.order_id
GROUP BY COALESCE(o.salesman_id, 0)
ORDER BY COALESCE(o.salesman_id, 0) ASC;

-- Q3: Display customer Id, customer name and total number of orders for customers that the value of their customer ID is in values from 35 to 45. 
-- Include the customers with no orders in your report if their customer ID falls in the range 35 and 45.
-- Sort the result by the value of total orders.
-- Q3 SOLUTION --
SELECT
    c.customer_id AS "Customer Id"
    , c.name AS "Name"
    , COUNT(o.order_id) AS "Total orders"
FROM customers c
LEFT JOIN orders o
ON c.customer_id = o.customer_id
WHERE c.customer_id BETWEEN 35 AND 45
GROUP BY c.customer_id, c.name
ORDER BY COUNT(o.order_id);

-- Q4: Display customer ID, customer name, and the order ID and the order date of all orders for customer whose ID is 44.
-- a. Show also the total quantity and the total amount of each customer’s order.
-- b. Sort the result from the highest to lowest total order amount.
-- Q4 SOLUTION --
SELECT
    c.customer_id AS "Customer Id"
    , c.name AS "Name" 
    , o.order_id AS "Order Id"
    , TO_CHAR(o.order_date, 'DD-MON-YYYY') AS "Order Date"
    , SUM(i.quantity) AS "Total Items"
    , TO_CHAR(SUM(i.quantity * i.unit_price), '$999,999,999.99') AS "Total Amount"
FROM customers c
LEFT JOIN orders o
ON c.customer_id = o.customer_id
LEFT JOIN order_items i
ON o.order_id = i.order_id
WHERE c.customer_id = 44
GROUP BY c.customer_id, c.name, o.order_id, TO_CHAR(o.order_date, 'DD-MON-YYYY')
ORDER BY SUM(quantity * unit_price) DESC;

-- Q5: Display customer Id, name, total number of orders, the total number of items ordered, and the total order amount for customers who have more than 30 orders.
-- Sort the result based on the total number of orders.
-- Q5 SOLUTION --
SELECT
    c.customer_id AS "Customer Id"
    , c.name AS "Name"
    , COUNT(o.customer_id) AS "Total Number of ORrers"
    , SUM(i.quantity) AS "Total Items"
    , TO_CHAR(SUM(i.quantity * i.unit_price), '$999,999,999.99') AS "Total Amount"
FROM customers c
LEFT JOIN orders o
ON c.customer_id = o.customer_id
LEFT JOIN order_items i
ON o.order_id = i.order_id
GROUP BY c.customer_id, c.name
HAVING COUNT(o.customer_id) > 30
ORDER BY COUNT(o.customer_id) ASC;

-- Q6: Display Warehouse Id, warehouse name, product category Id, product category name, and the lowest product standard cost for this combination.
-- In your result, include the rows that the lowest standard cost is less then $200.
-- Also, include the rows that the lowest cost is more than $500.
-- Sort the output according to Warehouse Id, warehouse name and then product, category Id, and product category name.
-- Q6 SOLUTION --
SELECT 
    w.warehouse_id AS "Warehouse ID"
    , w.warehouse_name AS "Warehouse Name"
    , p.category_id AS "Category ID" 
    , pc.category_name AS "Category Name"
    , TO_CHAR(MIN(standard_cost), '$999,999,999.99') AS "Lowest Cost"
FROM inventories i
LEFT JOIN warehouses w
ON w.warehouse_id = i.warehouse_id
LEFT JOIN products p
ON p.product_id = i.product_id
LEFT JOIN product_categories pc
ON pc.category_id = p.category_id
GROUP BY w.warehouse_id, w.warehouse_name, p.category_id, pc.category_name
HAVING MIN(standard_cost) NOT BETWEEN 200 AND 500
ORDER BY w.warehouse_id, w.warehouse_name, p.category_id, pc.category_name;

-- Q7: Display the total number of orders per month. Sort the result from January to December.
-- Q7 SOLUTION --
SELECT
    TO_CHAR(order_date, 'Month') AS "Month"
    , count(*) AS "Number of Orders"
FROM orders
GROUP BY EXTRACT(MONTH FROM order_date), TO_CHAR(order_date, 'Month')
ORDER BY EXTRACT(MONTH FROM order_date);

-- Q8: Display product Id, product name for products that their list price is more than any highest product standard cost per warehouse outside Americas regions.
--(You need to find the highest standard cost for each warehouse that is located outside the Americas regions. 
-- Then you need to return all products that their list price is higher than any highest standard cost of those warehouses.)
-- Sort the result according to list price from highest value to the lowest.
SELECT
    p.product_id AS "Product Id" 
    , p.product_name AS "Product name"
    , TO_CHAR(p.list_price, '$999,999,999.99') AS "Price"
FROM products p 
WHERE p.list_price > ANY 
    (SELECT MAX(p.standard_cost) 
    FROM warehouses w, inventories i, products p 
    WHERE p.product_id = i.product_id 
        AND w.warehouse_id = i.warehouse_id 
    GROUP BY w.warehouse_id HAVING w.warehouse_id >=6) 
ORDER BY p.list_price DESC;

--Q9: Write a SQL statement to display the most expensive and the cheapest product (list price). Display product ID, product name, and the list price.
SELECT
    product_id AS "Product Id" 
    , product_name AS "Product name"
    , TO_CHAR(list_price, '$999,999,999.99') AS "Price"
FROM products
WHERE list_price =    
    (SELECT MAX(list_price)
     FROM products)

    OR list_price =    
    (SELECT MIN(list_price)
    FROM products)
ORDER BY list_price DESC;

     
--Q10: Write a SQL query to display the number of customers with total order amount over the average amount of all orders, the number of customers with total order amount under the average amount of all orders, 
-- number of customers with no orders, and the total number of customers. See the format of the following result.

--Customers with total purchase amount over average
WITH over_average AS
(
SELECT 
    o.customer_id
    , SUM(oi.quantity * oi.unit_price) AS "Total" 
FROM orders o, order_items oi 
WHERE o.order_id = oi.order_id 
GROUP BY o.customer_id 
HAVING SUM(oi.quantity * oi.unit_price) >
    (SELECT AVG(quantity * unit_price) FROM order_items) 
)

--Customers with total purchase amount below average
, below_average AS
(
    SELECT 
        o.customer_id
        , SUM(oi.quantity * oi.unit_price) AS "Total" 
    FROM orders o, order_items oi 
    WHERE o.order_id = oi.order_id 
    GROUP BY o.customer_id 
    HAVING SUM(oi.quantity * oi.unit_price) <
        (SELECT AVG(quantity * unit_price) FROM order_items)
)

--Number of customers with no orders:
, customers_with_no_orders AS
(
    SELECT * 
    FROM 
        (SELECT customer_id
        FROM customers 
        MINUS 
        SELECT customer_id 
        FROM orders)
)
    
--Total Number of Customers:
, total_customers AS
(
    SELECT DISTINCT customer_id
    FROM customers
)

SELECT 'Number of customers with total purchase amount over average: ' || COUNT(*) AS "Customer report" FROM over_average 
UNION
SELECT 'Number of customers with total purchase amount below average: ' || COUNT(*) FROM below_average
UNION
SELECT 'Number of customers with no orders: ' || COUNT(*) FROM customers_with_no_orders
UNION
SELECT 'Total number of customers: ' || COUNT(*) FROM total_customers
