
-- ***********************

SET SERVEROUTPUT ON

-- Qustion1 -  Write a store procedure that get an integer number and prints
-- The number is even. If a number is divisible by 2.
-- Otherwise, it prints The number is odd.
-- Q1 SOLUTION –
CREATE OR REPLACE PROCEDURE checkNum(num in NUMBER) AS

BEGIN  
    IF MOD(num,2)=0
    THEN
        DBMS_OUTPUT.PUT_LINE('The number '||num||' is even');
    ELSE
        DBMS_OUTPUT.PUT_LINE('The number '||num||' is odd');
    END IF;
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('An Error Occured!');
END checkNum;
--------------------------------------
BEGIN
    checkNum(3);
    checkNum(4);
END;

-- Question 2 - Create a stored procedure named find_employee. This procedure gets an employee number and prints the 
-- following employee information: First name, Last name, Email, Phone, Hire date, Job title
-- Q2 SOLUTION –
CREATE OR REPLACE PROCEDURE find_employee (employeeId IN number) AS
  firstname  VARCHAR2(255 BYTE);
  lastname VARCHAR2(255 BYTE);
  email VARCHAR2(255 BYTE);
  phone VARCHAR2(255 BYTE);
  hiredate date;
  jobtitle VARCHAR2(255 BYTE);
BEGIN 
  SELECT First_name, Last_name,Email,Phone,Hire_date,Job_title 
    INTO firstname,  lastname, email,phone,hiredate, jobtitle
  FROM employees
  WHERE employee_id = employeeId;
  DBMS_OUTPUT.PUT_LINE ('First name: ' || firstname);
  DBMS_OUTPUT.PUT_LINE ('Last name: ' || lastname);
  DBMS_OUTPUT.PUT_LINE ('Email: '||email);
  DBMS_OUTPUT.PUT_LINE ('Phone: ' || phone);
  DBMS_OUTPUT.PUT_LINE ('Hire date: ' || hiredate);
  DBMS_OUTPUT.PUT_LINE ('Job title: '||jobtitle);
   EXCEPTION
    WHEN TOO_MANY_ROWS THEN
        DBMS_OUTPUT.PUT_LINE('Error trying to SELECT too many rows');
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('No data found');
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('An Error Occured!');
END find_employee;  
------------------------------------------------  
BEGIN
    find_employee(107);
    find_employee(106);
END;

-- Question 3 - update the price of all products in a given category,
-- and the given amount to be added to the current price if the price is greater than 0
-- Q3 SOLUTION – 

CREATE OR REPLACE PROCEDURE update_price_by_cat (categroyId IN NUMBER,increasePrice IN NUMBER) AS
  category_id products.category_id%type;
  listprice products.list_price%type;
  Rows_updated number; 
BEGIN   
  UPDATE products set products.list_price=products.list_price+increasePrice
  WHERE category_id = categroyId and list_price>0;
        Rows_updated := sql%rowcount;
        
  DBMS_OUTPUT.PUT_LINE ('Rows_updated: ' || Rows_updated||' lines');
  
    EXCEPTION
    WHEN TOO_MANY_ROWS THEN
        DBMS_OUTPUT.PUT_LINE('Error trying to SELECT too many rows');
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('No data found');
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('An Error Occured!');
END update_price_by_cat;  
-----------------------------------  
BEGIN
    update_price_by_cat (1,5);
END;

-- Question 4 - find the average, if the average <=1000, update the price lower than the average at 1.02; 
-- if the average >1000, update the price lower than the average at 1.01 .

CREATE OR REPLACE PROCEDURE update_price_under_avg AS
  avgPrice products.list_price%type;
  rows_updated number;  
BEGIN
  SELECT avg(list_price) INTO avgPrice
  FROM products;
  IF(avgPrice<=1000) THEN
    UPDATE products SET products.list_price=products.list_price* 1.02
    WHERE list_price<avgPrice;
    Rows_updated := sql%rowcount;
    DBMS_OUTPUT.PUT_LINE ('Rows_updated: ' || rows_updated);
  ELSE 
    UPDATE products SET products.list_price=products.list_price* 1.01
    WHERE list_price<avgPrice;  
    rows_updated := sql%rowcount;
    DBMS_OUTPUT.PUT_LINE ('Rows_updated: ' || rows_updated);
  END IF;
  EXCEPTION
    WHEN TOO_MANY_ROWS THEN
        DBMS_OUTPUT.PUT_LINE('Error trying to SELECT too many rows');
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('No data found');
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('An Error Occured!');
END update_price_under_avg;  
-----------------------------------
BEGIN
    update_price_under_avg;    
END;

-- Question 5 - shows three category of products based their prices

CREATE OR REPLACE PROCEDURE product_price_report AS  
  listPrice products.list_price%type;
  avgPrice products.list_price%type;
  maxPrice products.list_price%type;
  minPrice products.list_price%type;
  rows_count NUMBER;
  
BEGIN
SELECT list_price, avg(list_price), max(list_price), min(list_price),count(product_id) 
    INTO listPrice, avgPrice, maxPrice, minPrice, rows_count
  FROM products group by list_price;  
  
  IF(listPrice<(avgPrice-minPrice)/2) THEN
    UPDATE products SET products.list_price=products.list_price;
    rows_count := sql%rowcount;
    DBMS_OUTPUT.PUT_LINE ('Cheap: ' || rows_count);
  ELSIF (listPrice<=(maxPrice-avgPrice)/2) AND (listPrice>=(avgPrice-minPrice)/2) THEN
    UPDATE products SET products.list_price=products.list_price;
    rows_count:= sql%rowcount;
    DBMS_OUTPUT.PUT_LINE ('Fair: ' || rows_count);
  ELSE 
    UPDATE products SET products.list_price=products.list_price;
    rows_count := sql%rowcount;
    DBMS_OUTPUT.PUT_LINE ('Expensive: ' || rows_count); 
  END IF;
  EXCEPTION
    WHEN TOO_MANY_ROWS THEN
        DBMS_OUTPUT.PUT_LINE('Error trying to SELECT too many rows');
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('No data found');
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('An Error Occured!');
END product_price_report;  
-----------------------------------
BEGIN
    product_price_report;    
END;



