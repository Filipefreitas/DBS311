SET SQLBLANKLINES ON;
SET SERVEROUTPUT ON;

--Question 1
--Write a query which lists the employee (from EMPLOYEE table) with the highest total compensation (includes SALARY, BONUS and COMMISSION) by department and job type.
-- The result set should have department, job type, employee number, total compensation.
-- The result set should be ordered by department, then, job type within the department.
--Q1 Solution--
SELECT
    emp.empno
    , emp.job
    , emp.workdept
    , COALESCE(emp.salary, 0) + COALESCE(emp.bonus, 0) + COALESCE(emp.comm, 0) AS total_compensation
FROM employee emp
WHERE COALESCE(emp.salary, 0) + COALESCE(emp.bonus, 0) + COALESCE(emp.comm, 0) IN
                (SELECT
                    MAX(COALESCE(emp.salary, 0) + COALESCE(emp.bonus, 0) + COALESCE(emp.comm, 0)) AS total_compensation
                FROM employee emp
                GROUP BY emp.workdept)
ORDER BY emp.workdept, emp.job;

--Question 2
--Write a query which shows the complete list of last names from both the EMPLOYEE table and STAFF table. Make sure your query is case insensitive (ie SMITH = Smith = smith).
-- Make sure names are not duplicated. We only want to see each name once in the result set.
-- Display the names with the initial character as a capital (ie: Smith, Jones, etc).
-- Output should be in ascending order (alphabetical order)
--Q2 Solution--

WITH base_all_names AS
(
    SELECT DISTINCT INITCAP(TRIM(lastname)) AS emp_name
    FROM employee
    UNION
    SELECT DISTINCT INITCAP(TRIM(name))
    FROM staff
)

SELECT DISTINCT emp_name
FROM base_all_names
ORDER BY emp_name ASC;

--Qeustion 3
-- Write a query which shows where we have two employees assigned to the same employee number, when looking across both EMPLOYEE table and STAFF table.
-- The output should be ordered first by employee number, then by last name
--Q3 Solution--

SELECT 
    CAST(empno AS NUMBER) AS empno
    , lastname
    , COUNT(*) OVER(PARTITION BY empno) AS countId
FROM 
    (SELECT 
        CAST(empno AS NUMBER) AS empno 
        , lastname
    FROM employee
    UNION ALL
    SELECT 
        id 
        , name
    FROM staff)
ORDER BY empno, lastname;


--Question 4
-- Write a query which lists all employees across both the STAFF and EMPLOYEE table, which have an ‘oo’ OR a ‘z’ in their last name.
-- This query should be case insensitive, meaning both a ‘Z’ and a ‘z’ count for the condition, as an example.
-- The output should be ordered by lastname.
--Q4 Solution--

SELECT DISTINCT * FROM 
    (SELECT
        emp.lastname
    FROM employee emp
    UNION ALL
    SELECT name
    FROM staff)
WHERE TRIM(UPPER(lastname)) like '%OO%'
    OR TRIM(lastname) like '%Z%'
ORDER BY lastname;

--Question 5
--Write a query which looks at the EMPLOYEE table and, for each department, compares the manager’s total compensation (SALARY, BONUS and COMMISSION) to the top paid employee’s total compensation 
    --and displays output if the top paid employee in that department makes within $10,000 in total compensation as compared to their manage
-- The output should include department, manager’s total compensation and top paid employee’s total compensation
-- If a department has no non-managers – OR – has no manager, assume total compensation is 0
--Q5 Solution--

WITH base_max_mgr AS
(
    SELECT 
        emp.workdept AS dept
        , COALESCE(emp.salary, 0) + COALESCE(emp.bonus, 0) + COALESCE(emp.comm, 0) AS total_compensation_mgr
    FROM employee emp
    WHERE TRIM(UPPER(emp.job)) = 'MANAGER'
),

base_top_employee AS
(
    SELECT 
        emp.workdept AS dept
        , MAX(COALESCE(emp.salary, 0) + COALESCE(emp.bonus, 0) + COALESCE(emp.comm, 0)) AS total_compensation_top_emp
    FROM employee emp
    WHERE TRIM(UPPER(emp.job)) <> 'MANAGER'
    GROUP BY emp.workdept
)

SELECT 
    emp.dept
    , emp.total_compensation_top_emp
    , CASE WHEN mgr.total_compensation_mgr IS NULL THEN 0 ELSE mgr.total_compensation_mgr END AS total_compensation_mgr
    , COALESCE(emp.total_compensation_top_emp, 0) - COALESCE(mgr.total_compensation_mgr, 0) AS diff_top_emp_mgt
FROM base_top_employee emp
LEFT JOIN base_max_mgr mgr
    ON emp.dept = mgr.dept 
WHERE (COALESCE(emp.total_compensation_top_emp, 0) - COALESCE(mgr.total_compensation_mgr, 0)) BETWEEN -10000 AND 10000
ORDER BY emp.dept;

--Question 6
--Write a query which looks across both the EMPLOYEE and STAFF table and returns the total “variable pay” (COMMISSION + BONUS) for each employee.
-- If an employee does not make either, the output should be 0
-- The output should include the employee’s last name and total variable pay
-- The output should be ordered by a case insensitive view of their last name in alphabetical order
--Q6 Solution--

--Not sure if I understand the question. Should I consider both tables, since Staff tables does not have the Bonus attribute in it?
SELECT
    INITCAP(emp.lastname) lastname
    , CASE 
        WHEN emp.comm IS NULL THEN 0
        WHEN emp.bonus IS NULL THEN 0
        ELSE emp.comm + emp.bonus 
    END AS variable_pay
FROM employee emp

UNION 

    SELECT 
        INITCAP(name)
        , CASE WHEN comm IS NOT NULL THEN comm ELSE 0 END AS variable_pay
    FROM staff

ORDER BY lastname;

--Question 7
--Write a stored procedure for the EMPLOYEE table which takes, as input, an employee number and a rating of either 1, 2 or 3.
--The stored procedure should perform the following changes:
-- If the employee was rated a 1 – they receive a $10,000 salary increase, additional $300 in bonus and an additional 5% of salary as commission
-- If the employee was rated a 2 – they receive a $5,000 salary increase, additional $200 in bonus and an additional 2% of salary as commission
-- If the employee was rated a 3 – they receive a $2,000 salary increase with no change to their variable pay
-- Make sure you handle two types of errors: (1) A non-existent employee – and – (2) A nonvalid rating. Both should have an appropriate message.
-- The stored procedure should return the employee number, previous compensation and new compensation (all three compensation components showed separately)
-- EMP OLD SALARY OLD BONUS OLD COMM NEW SALARY NEW BONUS NEW COMM
-- Demonstrate that your stored procedure works correctly by running it 5 times: 
    --Three times with a valid employee number and a 1 rating, 2 rating and 3 rating. 
    --Once with an invalid employee number. 
    --Once with an invalid rating level.
--Q7 Solution--
SET SERVEROUTPUT ON;

CREATE OR REPLACE PROCEDURE update_salary_by_rating (empId IN NUMBER, empRating IN NUMBER)

AS
    OUT_OF_RANGE EXCEPTION;
    empSalary employee.salary%TYPE;
    empBonus employee.bonus%TYPE;
    empComm employee.comm%TYPE;
    newSalary employee.salary%TYPE;
    newBonus employee.bonus%TYPE;
    newComm employee.comm%TYPE;
    
BEGIN     
    SELECT 
        salary
        , bonus
        , comm
    
    INTO
        empSalary
        , empBonus
        , empComm
    
    FROM employee
    WHERE CAST(empno AS NUMBER) = empId;

    IF empRating NOT IN (1, 2, 3) THEN
        RAISE OUT_OF_RANGE;
    
    ELSE   
        IF empRating = 1 THEN
            newSalary:= empSalary + 10000;
            newBonus:= empBonus + 300;
            newComm:= empComm * 1.05;

        ELSIF empRating = 2 THEN 
            newSalary:= empSalary + 5000;
            newBonus:= empBonus + 200;
            newComm:= empComm * 1.02;

        ELSE 
            newSalary:= empSalary + 2000;
            newBonus:= empBonus;
            newComm:= empComm;
                
        END IF;
        
        DBMS_OUTPUT.PUT_LINE ('EMP ID: ' || empId);
        DBMS_OUTPUT.PUT_LINE ('OLD SALARY: ' || empSalary);
        DBMS_OUTPUT.PUT_LINE ('OLD BONUS: ' || empBonus);   
        DBMS_OUTPUT.PUT_LINE ('OLD COMM: ' || empComm);     
        
        DBMS_OUTPUT.PUT_LINE ('NEW SALARY: ' || newSalary);
        DBMS_OUTPUT.PUT_LINE ('NEW BONUS: ' || newBonus);    
        DBMS_OUTPUT.PUT_LINE ('NEW COMM: ' || newComm);
    
    END IF;
    
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE ('Employee ID not found!');
        WHEN OUT_OF_RANGE THEN
            DBMS_OUTPUT.PUT_LINE('Invalid rating');

END update_salary_by_rating;  
/
DECLARE
    empId NUMBER:= &empId;
    empRating NUMBER:= &empRating; 
BEGIN
    update_salary_by_rating (empId, empRating);
END update_salary_by_rating;
/

--Question 8
--Write a stored procedure for the EMPLOYEE table which takes employee number and education level upgrade as input - and - increases the education level of the employee based on the input. Valid input is:
-- “H” (for high school diploma) – and – this will update the edlevel to 16
-- “C” (for college diploma) – and – this will update the edlevel to 19
-- “U” (for university degree) – and – this will update the edlevel to 20
-- “M” (for masters) – and – this will update the edlevel to 23
-- “P” (for PhD) – and – this will update the edlevel to 25
-- Make sure you handle the error condition of incorrect education level input – and – nonexistent employee number
-- Also make sure you never reduce the existing education level of the employee. They can only stay the same or go up.
-- A message should be provided for all three error cases.
-- When no errors occur, the output should look like:
-- EMP OLD EDUCATION NEW EDUCATION
--Q8 Solution--
SET SERVEROUTPUT ON;

CREATE OR REPLACE PROCEDURE update_education_by_level (empId IN NUMBER, educUpgrade IN CHAR)

AS
       DOWNGRADE_NOT_ALLOWED EXCEPTION;
       empEdLevel employee.edlevel%TYPE;
       targetNewEdLevel employee.edlevel%TYPE;
       newEdLevel employee.edlevel%TYPE;
 
BEGIN     
    SELECT 
        edlevel
    
    INTO
        empEdLevel
    
    FROM employee
    WHERE CAST(empno AS NUMBER) = empId;
    
    CASE UPPER(educUpgrade)
            WHEN 'H' THEN targetNewEdLevel:= 16;
            WHEN 'C' THEN targetNewEdLevel:= 19;
            WHEN 'U' THEN targetNewEdLevel:= 20;
            WHEN 'M' THEN targetNewEdLevel:= 23;
            WHEN 'P' THEN targetNewEdLevel:= 25;
            ELSE DBMS_OUTPUT.PUT_LINE('Wrong education level input');
        END CASE;
    
    IF targetNewEdLevel < empEdLevel THEN
        RAISE DOWNGRADE_NOT_ALLOWED;
        
        ELSE
        newEdLevel:= targetNewEdLevel;
    
    END IF;
    
    DBMS_OUTPUT.PUT_LINE ('EMP ID: ' || empId);
    DBMS_OUTPUT.PUT_LINE ('OLD EDUCATION: ' || empEdLevel);
    DBMS_OUTPUT.PUT_LINE ('NEW EDUCATION: ' || newEdLevel);
          
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE ('Employee ID not found!');
        WHEN DOWNGRADE_NOT_ALLOWED THEN
            DBMS_OUTPUT.PUT_LINE('Downgrade now allowed');


END update_education_by_level;  
/
DECLARE
    empId NUMBER:= &empId;
    educUpgrade CHAR(1):= '&educUpgrade'; 
BEGIN
    update_education_by_level (empId, educUpgrade);
END update_education_by_level;
/

--Question 9
--Write a function called PHONE which takes an employee number as input and displays a full phone number for that employee, using the PHONENO value as part of the function.
-- PHONE(100) should run for employee 100
-- This function should convert the existing PHONENO value into a full phone number which looks like “(416) 123-xxxx” where xxxx is the existing PHONENO value.
-- This function will return the full phone number.
--Q9 Solution--

ALTER TABLE employee MODIFY phoneno varchar(14);
SET SERVEROUTPUT ON;

CREATE OR REPLACE FUNCTION phone(empId IN NUMBER) 
RETURN VARCHAR2
IS 
fullPhoneNo VARCHAR2(14);

BEGIN 

    SELECT 
        CONCAT(CONCAT('(416) 123','-'), phoneno)
    
    INTO 
        fullPhoneNo
    
    FROM employee 
    WHERE empno = empId;
    
    DBMS_OUTPUT.PUT_LINE ('PHONE NUMBER: ' || fullPhoneNo);
    RETURN fullPhoneNo;

 END;
 /
DECLARE
    phone_ret varchar2(100); 
BEGIN
  phone_ret:=phone(100); 
END;

--Question 10
-- Execute an UPDATE command which adds a new column to your EMPLOYEE table called PHONENUM as CHAR(14)
-- Write a stored procedure which calls your PHONE function.
--This stored procedure should go through a loop for all records where the department number begins with a E and updates the value of PHONENUM with the output of the PHONE function
-- For each row, as it is updated the following should be printed
-- DEPT EMP PHONENO PHONENUM
--Q10 Solution--
ALTER TABLE employee ADD phonenum VARCHAR(14);

CREATE OR REPLACE PROCEDURE Updatephone

AS
    Eempid employee.empno%TYPE; 
    Edept employee.workdept%TYPE;
    Ename employee.firstname%TYPE;  
    Ephone employee.phoneno%TYPE; 
    Ephonenum employee.phoneno%TYPE; 
        
CURSOR c1 IS

SELECT 
    empno
    , workdept
    , firstname
    , phoneno
    , phone(empno)
FROM employee emp
WHERE workdept like 'E%';

BEGIN
    
    OPEN c1;  
    
    LOOP
        FETCH c1 
        INTO 
            Eempid
            , Edept
            , Ename
            , Ephone
            , Ephonenum;
        EXIT WHEN c1%NOTFOUND;
        UPDATE employee 
            SET phonenum = Ephonenum 
            WHERE empno = Eempid;  
        DBMS_OUTPUT.PUT_LINE(Edept || ' '||Ename||' ' || Ephone || ' ' || Ephonenum);
        END LOOP;
        CLOSE c1;
        
END;
/
EXECUTE Updatephone;

