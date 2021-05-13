--NAME: Filipe da Cunha de Freitas

-- QUESTION 1:
-- Write a query which shows the common last names of any individuals in both tables. 
-- Make sure you ignore case (Smith=SMITH=smith). Make sure duplicates are removed. Alphabetically order the results.
-- Q1 SOLUTION --
SELECT DISTINCT TRIM(UPPER(e.lastname)) AS "LAST NAME"
FROM employee e
WHERE e.lastname IN
(
    SELECT TRIM(UPPER(name))
    FROM staff
)
ORDER BY "LAST NAME";

-- QUESTION 2:
-- Write a query which shows the employee IDs that are unique to the employee table. Order the employee IDs in descending order. 
-- An employee ID Is the same in both tables if the integer value of the ID matches.
-- Q2 SOLUTION --
SELECT DISTINCT CAST(empno AS NUMBER)
FROM EMPLOYEE
WHERE CAST(empno AS NUMBER) NOT IN
    (SELECT CAST(id AS NUMBER)
        FROM staff)
ORDER BY CAST(empno AS NUMBER) DESC;

--QUESTION 3:
-- We want to add a new column to the employee table. We want to provide a new column with a more complete phone number. 
-- Right now the PHONENO column only shows the last 4 digits.
-- We want a new column which is called PHONE and consists of ###-###-####. 
-- The last 4-digits are already in the PHONENO column. The first three digits should be 416 and the next three should be 123. 
-- To improve clarity in the table, we also want to rename the PHONENO column to PHONEEXT.
-- Show all the commands used to accomplish this, then, select all data for employees who have the last name of 'smith' (case insensitive).
-- Q3 SOLUTION --

ALTER TABLE employee
ADD(phone char(12));

UPDATE employee
SET PHONE = '416-123-' || phoneno;

ALTER TABLE employee
RENAME COLUMN phoneno TO phoneext;

SELECT * FROM employee
WHERE TRIM(UPPER(lastname)) = 'SMITH';

-- QUESTION 4:
-- Show a list of employee id, names, department, years and job of any employee in the staff table who makes a total amount more than their manager or has more years of service than their manager.
-- Make sure to include both salary and commission when calculating the total amount someone makes.
-- Exclude staff in department 10 from the query.
-- Order the results by department then name
-- Q4 SOLUTION --
SELECT DISTINCT
    s.id
    ,s.name
    ,s.dept
    ,s.years
    ,s.job
FROM staff s,
  (SELECT *
   FROM staff
   WHERE id IN
       (SELECT id
        FROM staff
        WHERE TRIM(UPPER(job)) = 'MGR')) sq
WHERE (COALESCE(s.salary,0)+COALESCE(s.comm,0) > COALESCE(sq.salary, 0)+COALESCE(sq.comm,0)
    AND s.dept = sq.dept
    AND s.job <> 'Mgr') --I am asusming that by "their manager" in the exercise outline, we are not considering a person who earns more than a manager from the same departament.
    OR (s.years > sq.years
    AND s.dept = sq.dept
    AND s.job <> 'Mgr')
    AND(s.dept <> 10)
ORDER BY s.dept, s.name;
      
-- QUESTION 5:
-- Show a list of all employees, their department and their jobs, from the staff table, that are in the same department as 'Graham'
-- Order by name alphabetically. Exclude 'Graham' from the result set.
-- Q5 SOLUTION --
SELECT 
    id
    , name
    , dept
    , job
FROM staff
WHERE dept =
    (SELECT dept
        FROM staff
        WHERE name = 'Graham')
    
MINUS
    
SELECT 
    id
    , name
    , dept
    , job
FROM staff
WHERE name = 'Graham'
ORDER BY name;

-- QUESTION 6:
-- Show the list of employee names, job and variable pay, from the employee table, who have the lowest and highest variable pay (includes commission and bonus) by job category.
-- The name should be formatted: lastname, firstname with the first character capitalized and all other characters in lower case. (ie: King, Les). The title of this column should be “Name”.
--- The variable pay column should be called “Variable Pay”. 
-- Order the results by highest variable pay to lowest variable pay.
-- Q6 SOLUTION --
SELECT
    INITCAP(lastname || ', ' || firstname) AS "Name"
    , job
    , COALESCE(bonus, 0) + COALESCE(comm ,0) AS "Variable Pay"
FROM employee
WHERE  (job, COALESCE(bonus, 0) + COALESCE(comm ,0)) IN 
    (SELECT
         job
         , MIN(COALESCE(bonus, 0) + COALESCE(comm ,0)) AS "Min_variable_pay"
    FROM employee
    GROUP BY job)
OR
(job, COALESCE(bonus, 0) + COALESCE(comm ,0)) IN 
    (SELECT
         job
         , MAX(COALESCE(bonus, 0) + COALESCE(comm ,0)) AS "Max_variable_pay"
    FROM employee
    GROUP BY job)

GROUP BY INITCAP(lastname || ', ' || firstname), job, COALESCE(bonus, 0) + COALESCE(comm ,0)    
ORDER BY "Variable Pay" DESC;

-- QUESTION 7:
-- Using the staff table, show all employees who have an 'il' in their name - or - their name ends with an 's'. Make sure your query is case insensitive.
-- You just need to display the name of the employee in your output. Order them alphabetically.
-- Q7 SOLUTION --
SELECT name
FROM staff
WHERE (TRIM(LOWER(name)) LIKE '%il%')
    OR (TRIM(LOWER(name)) LIKE '%s')
ORDER BY name;

-- QUESTION 8:
-- Using the staff table, display the employee name, job, salary and commission for all employees with a salary less than the salary of all people with a manager job or full compensation less than the full compensation of all the people with a sales job.
-- Full compensation is the sum of both salary and commission.
-- Exclude people with a sales job from the output.
-- Q8 SOLUTION --
SELECT
        t1.name
        , t1.job
        , t1.salary
        , COALESCE(t1.comm, 0) AS "COMMISION"
    FROM staff t1, staff t2
    WHERE 
        (TRIM(UPPER(t2.job)) <> 'SALES')
    AND
        (t1.id = t2.id 
        AND t1.salary < ALL
        (SELECT 
            (COALESCE(salary,0))
        FROM staff
        WHERE TRIM(UPPER(job)) = 'MGR'))
    OR
        (t1.id = t2.id 
        AND (t1.salary + COALESCE(t1.comm, 0)) < ALL
        (SELECT 
            (COALESCE(salary,0) + COALESCE(comm, 0))
        FROM staff
        WHERE TRIM(UPPER(job)) = 'SALES'));

-- QUESTION 9:
-- From the employee table, calculate the average compensation for each job category where the employee has 16 or more years of education.
-- Display the job and average compensation in the result set.
-- Exclude people who are clerks
-- Make sure to include salary, commission and bonus when looking at employee compensation
-- Order the output by the average salary in ascending order
-- Q9 SOLUTION --
SELECT 
    job, 
    ROUND(AVG(COALESCE(salary, 0) + COALESCE(bonus, 0) + COALESCE(comm, 0)), 2) AS "Avg_compensation_edlevel_16"
FROM employee
WHERE (TRIM(UPPER(job)) <> 'CLERK')
    AND (edlevel >= 16)
GROUP BY job
ORDER BY AVG(COALESCE(salary, 0)) ASC;

-- QUESTION 10:
-- Show the first name, last name, hire date, birth date, education level and years of service for employees who are both in the staff table and the employee table
-- An individual is the same individual if a case insensitive comparison of last name matches.
-- Q10 SOLUTION --
SELECT
    e.firstname
    , e.lastname
    , e.hiredate
    , e.birthdate
    , e.edlevel
    , s.years
FROM employee e
INNER JOIN staff s
ON TRIM(UPPER(e.lastname)) = TRIM(UPPER(s.name));