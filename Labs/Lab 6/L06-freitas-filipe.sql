-- ***********************
-- Name: Filipe da Cunha de Freitas
-- ID: 155737190
-- Date: 2021-02-24
-- Purpose: Lab 6 DBS311
-- ***********************

SET SERVEROUTPUT ON;

--Q1. Write a store procedure that gets an integer number n and calculates and displays its factorial.
-- Q1 SOLUTION --
CREATE OR REPLACE PROCEDURE calcFactorial(num in NUMBER) AS
    fac NUMBER:=1;
    n NUMBER:=num;
    
BEGIN           
    WHILE n > 0 LOOP    
        fac:=fac*n;         
        n:=n-1;            
    END LOOP;           
    DBMS_OUTPUT.PUT_LINE(fac);  
END; 
/
BEGIN
    calcFactorial(5);
    calcFactorial(3);
END;
/
-- Q2: The company wants to calculate the employees’ annual salary:
--The first year of employment, the amount of salary is the base salary which is $10,000.
--Every year after that, the salary increases by 5%.
--Write a stored procedure named calculate_salary which gets an employee ID and for that employee calculates the salary based on the number of years the employee has been working in the company. 
--(Use a loop construct to calculate the salary).
--The procedure calculates and prints the salary.
--Sample output:
--First Name: first_name
--Last Name: last_name
--Salary: $9999,99
--If the employee does not exists, the procedure displays a proper message.

-- Q2 SOLUTION --
CREATE OR REPLACE PROCEDURE calculate_salary(employeeId IN NUMBER) AS
    salary NUMBER :=10000;
    years NUMBER :=0;
    firstname VARCHAR2(255);
    lastname VARCHAR2(255);        
    
BEGIN 
  SELECT first_name, last_name, TRUNC((months_between(CURRENT_DATE ,TO_DATE(hire_date)))/12)
        INTO firstname, lastname, years
        FROM employees 
        WHERE employee_id = employeeId;        
  FOR i IN 1..years LOOP  
        salary := salary * 1.05;
      END LOOP; 
      salary:=ROUND(salary,2);
      DBMS_OUTPUT.PUT_LINE ('First name: ' || firstname);
      DBMS_OUTPUT.PUT_LINE ('Last name: ' || lastname);
      DBMS_OUTPUT.PUT_LINE ('Salary: ' || salary);
  
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('The employee does not exist!');
END calculate_salary;
/
BEGIN
    calculate_salary(107);
END;
/

--Q3: Write a stored procedure named warehouses_report to print the warehouse ID, warehouse name, and the city where the warehouse is located in the following format for all warehouses:
--Warehouse ID:
--Warehouse name:
--City:
--State:
--If the value of state does not exist (null), display “no state”.
--The value of warehouse ID ranges from 1 to 9.
--You can use a loop to find and display the information of each warehouse inside the loop.
--(Use a loop construct to answer this question. Do not use cursors.)

CREATE OR REPLACE PROCEDURE warehouses_report AS
    warehouseid INT;
    warehousename varchar2(255);
    city varchar2(255);  
    state varchar2(255); 
    i INT;
    
BEGIN 
    FOR i IN 1..9 LOOP
    SELECT w.warehouse_id, w.warehouse_name, l.city, COALESCE(l.state,'no state')
        INTO warehouseid, warehousename, city, state
        FROM warehouses w 
        LEFT JOIN locations l 
            ON w.location_id=l.location_id
        WHERE warehouse_id=i;          
   
        DBMS_OUTPUT.PUT_LINE ('Warehouse ID: ' || warehouseid);
        DBMS_OUTPUT.PUT_LINE ('Warehouse name: ' || warehousename);
        DBMS_OUTPUT.PUT_LINE ('City: ' || city);
        DBMS_OUTPUT.PUT_LINE ('State: ' || state);  
    END LOOP;       
    
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE('No data found');
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('An Error Occured');

END warehouses_report;
/
BEGIN
    warehouses_report();
END;
/