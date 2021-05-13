-- ***********************
-- Name: Filipe da Cunha de Freitas
-- ID: 155737190
-- Date: 2021-02-18
-- Purpose: Lab 5 DBS311
-- ***********************

--Q1. Write a store procedure that get an integer number and prints The number is even.
--If a number is divisible by 2.
--Otherwise, it prints
---The number is odd.
-- Q1 SOLUTION --
SET SERVEROUTPUT ON;

CREATE OR REPLACE PROCEDURE odd_or_even(inputInt IN NUMBER)
AS 

BEGIN 
   IF MOD(inputInt ,2) = 0 THEN
       DBMS_OUTPUT.PUT_LINE('The number is even.'); 
    ELSE
       DBMS_OUTPUT.PUT_LINE('The number is odd.'); 
    END IF;   
END; 
/
DECLARE
    inputInt NUMBER:= &inputInt;
BEGIN 
   odd_or_even(inputInt); 
END odd_or_even; 
/

--Q2. Create a stored procedure named find_employee. This procedure gets an employee number and prints the following employee information:
--    First name
--    Last name
--    Email
--    Phone
--    Hire date
--    Job title
--
--    The procedure gets a value as the employee ID of type NUMBER.
--    See the following example for employee ID 107:
--    First name: Summer
--    Last name: Payn
--    Email: summer.payne@example.com
--    Phone: 515.123.8181
--    Hire date: 07-JUN-16
--    Job title: Public Accountant
--    The procedure display a proper error message if any error accours.
-- Q2 SOLUTION --
DECLARE
    empID NUMBER:= &empID;
    firstName VARCHAR2(255);
    lastName VARCHAR2(255);
    emailAddress  VARCHAR2(255);
    phoneNumber VARCHAR2(50);
    hireDate DATE;
    jobTitle VARCHAR2(255);
BEGIN 
   SELECT 
        first_name
        , last_name
        , email
        , phone
        , hire_date
        , job_title
    INTO
        firstName
        , lastName
        , emailAddress
        , phoneNumber
        , hireDate
        , jobTitle
    FROM employees
    WHERE employee_id = empID;
    DBMS_OUTPUT.PUT_LINE ('First name: ' || firstName);
    DBMS_OUTPUT.PUT_LINE ('Last name: ' || lastName);
    DBMS_OUTPUT.PUT_LINE ('Email: ' || emailAddress);
    DBMS_OUTPUT.PUT_LINE ('Phone: ' || phoneNumber);
    DBMS_OUTPUT.PUT_LINE ('Hire Date: ' || TO_CHAR(hireDate, 'DD-MON-YYYY'));
    DBMS_OUTPUT.PUT_LINE ('Job Title: ' || jobTitle);
    
EXCEPTION
WHEN NO_DATA_FOUND
    THEN
        DBMS_OUTPUT.PUT_LINE ('Employee ID not found!');        
WHEN TOO_MANY_ROWS
    THEN
    DBMS_OUTPUT.PUT_LINE ('Error: more than one employee registered with this ID!');
END; 
/

--Q3: Every year, the company increases the price of all products in one category. For example, the company wants to increase the price (list_price) of products in category 1 by $5. 
--Write a procedure named update_price_by_cat to update the price of all products in a given category and the given amount to be added to the current price if the price is greater than 0. 
--The procedure shows the number of updated rows if the update is successful.
--The procedure gets two parameters:
--    • category_id IN NUMBER
--    • amount NUMBER(9,2)
--To define the type of variables that store values of a table’ column, you can also write:
--    vriable_name table_name.column_name%type;
--The above statement defines a variable of the same type as the type of the table’ column. 
--    category_id products.category_id%type;
--Or you need to see the table definition to find the type of the category_id column. Make sure the type of your variable is compatible with the value that is stored in your variable.
--To show the number of affected rows the update query, declare a variable named rows_updated of type NUMBER and use the SQL variable sql%rowcount to set your variable. 
--Then, print its value in your stored procedure.
--    Rows_updated := sql%rowcount;
--    SQL%ROWCOUNT stores the number of rows affected by an INSERT, UPDATE, or DELETE.
-- Q3 SOLUTION --
CREATE OR REPLACE PROCEDURE update_price_by_cat (categoryID IN NUMBER, amount IN NUMBER) 
AS
  category_id products.category_id%type;
  listPrice products.list_price%type;
    Rows_updated NUMBER; 
  
BEGIN
    UPDATE products
    SET products.list_price = products.list_price + amount
    WHERE category_id = categoryID 
        AND list_price > 0;
    Rows_updated := sql%rowcount;
    DBMS_OUTPUT.PUT_LINE(Rows_updated || ' rows updated'); 
  
EXCEPTION
    WHEN TOO_MANY_ROWS THEN
        DBMS_OUTPUT.PUT_LINE('Error: SELECT returned too manny lines');
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('Error: no data found');
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('An error has occured');
END update_price_by_cat;  
/
BEGIN
    update_price_by_cat (1,5);
END;
/

--Q4: Every year, the company increase the price of products whose price is less than the average price of all products by 1%. (list_price * 1.01). 
--Write a stored procedure named update_price_under_avg. This procedure do not have any parameters. 
--You need to find the average price of all products and store it into a variable of the same type. 
--If the average price is less than or equal to $1000, update products’ price by 2% if the price of the product is less than the calculated average. 
--If the average price is greater than $1000, update products’ price by 1% if the price of the product is less than the calculated average. 
--The query displays an error message if any error occurs. Otherwise, it displays the number of updated rows.
-- Q4 SOLUTION --
CREATE OR REPLACE PROCEDURE update_price_under_avg
AS
    avgPrice products.list_price%type;
    rows_updated NUMBER;

BEGIN
    SELECT 
        AVG(list_price)
    INTO 
        avgPrice
    FROM products;

    IF avgPrice <= 1000 THEN 
        UPDATE products
        SET products.list_price = products.list_price * 1.02
        WHERE  products.list_price < avgPrice;
        Rows_updated := sql%rowcount;
        DBMS_OUTPUT.PUT_LINE(rows_updated || ' rows updated'); 
    ELSE
        UPDATE products
        SET products.list_price = products.list_price * 1.01
        WHERE  products.list_price < avgPrice;
        Rows_updated := sql%rowcount;
        DBMS_OUTPUT.PUT_LINE(rows_updated || ' rows updated'); 
    END IF;
            
EXCEPTION
WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE ('Error: No data found!');        
WHEN TOO_MANY_ROWS THEN
        DBMS_OUTPUT.PUT_LINE ('Error: SELECT returned too many lines');
WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE ('An error has occured');
END update_price_under_avg;
/
BEGIN
    update_price_under_avg;    
END;
/

--Q5: company needs a report that shows three category of products based their prices. The company needs to know if the product price is cheap, fair, or expensive. Let’s assume that
--? If the list price is less than
--    o (avg_price - min_price) / 2
--    The product’s price is cheap.
--? If the list price is greater than
--    o (max_price - avg_price) / 2
--    The product’ price is expensive.
--? If the list price is between
--    o (avg_price - min_price) / 2
--    o and
--    o (max_price - avg_price) / 2
--    o the end values included
--    The product’s price is fair.
--Write a procedure named product_price_report to show the number of products in each price category:
--The following is a sample output of the procedure if no error occurs:
--Cheap: 10
--Fair: 50
--Expensive: 18
--The values in the above examples are just random values and may not match the real numbers in your result.
--The procedure has no parameter. First, you need to find the average, minimum, and maximum prices (list_price) in your database and store them into varibles avg_price, min_price, and max_price.
--*/
-- Q5 SOLUTION --
CREATE OR REPLACE PROCEDURE product_price_report 
AS  
    listPrice products.list_price%type;
    avgPrice products.list_price%type;
    maxPrice products.list_price%type;
    minPrice products.list_price%type;
    cheap_count NUMBER;
    fair_count NUMBER;
    exp_count NUMBER;
  
BEGIN
    SELECT 
        AVG(list_price)
        , MAX(list_price)
        , MIN(list_price)
    INTO 
        avgPrice
        , maxPrice
        , minPrice
    FROM products;

    UPDATE products 
    SET products.list_price = products.list_price   
    WHERE products.list_price < (avgPrice - minPrice)/2;
    cheap_count := sql%rowcount;
    DBMS_OUTPUT.PUT_LINE ('Cheap: ' || cheap_count);
    
    UPDATE products 
    SET products.list_price = products.list_price   
    WHERE products.list_price <= (maxPrice - avgPrice)/2 AND products.list_price >= (avgPrice - minPrice)/2;
    fair_count:= sql%rowcount;
    DBMS_OUTPUT.PUT_LINE ('Fair: ' || fair_count);

    UPDATE products 
    SET products.list_price = products.list_price   
    WHERE products.list_price >= (avgPrice - minPrice)/2;
    exp_count := sql%rowcount;
    DBMS_OUTPUT.PUT_LINE ('Expensive: ' || exp_count); 

EXCEPTION
    WHEN TOO_MANY_ROWS THEN
        DBMS_OUTPUT.PUT_LINE('Error: trying to SELECT too many rows');
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('Error: no data found');
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('An Error has occured');
END product_price_report;  
/

BEGIN
    product_price_report;
END;
/