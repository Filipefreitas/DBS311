-- DBS311 - MIDTERM TEST
-- NAME:  Les King
--
--
select count(*) from staff;
select count(*) from employee;
--
-- QUESTION 1:
-- Write a query which shows the common last names of any individuals in both tables.  Make sure you ignore case (Smith=SMITH=smith).  Make sure duplicates are removed.  Alphabetically order the results.
--
-- select lower(lastname) from employee intersect select lower(name) from staff order by 1;
-- OR
select distinct(lastname) from employee, staff where lower(lastname) = lower(name) order by lastname;
--
-- QUESTION 2:
-- Write a query which shows the employee IDs that are unique to the employee table.  Order the employee IDs in descending order.  An employee ID Is the same in both tables if the integer value of the ID matches.
--
select cast(empno as integer) from employee except select id from staff order by 1 desc;
--
-- QUESTION 3:
-- We want to add a new column to the employee table.  We want to provide a new column with a more complete phone number.  Right now the PHONENO column only shows the last 4 digits.
-- We want a new column which is called PHONE and consists of ###-###-####.  The last 4-digits are already in the PHONENO column.  The first three digits should be 416 and the next three should be 123.
-- To improve clarity in the table, we also want to rename the PHONENO column to PHONEEXT.
-- Show all the commands used to accomplish this, then, select all data for employees who have the last name of 'smith' (case insensitive).
--
ALTER TABLE employee ADD PHONE CHAR(15);
REORG TABLE employee;
UPDATE employee SET PHONE = concat('416-123-',phoneno);
ALTER TABLE employee RENAME COLUMN phoneno to phoneext;
REORG TABLE employee;
SELECT * FROM employee WHERE LOWER(lastname) = 'smith';
--
-- QUESTION 4:
-- Show a list of employee id, names, department, years and job of any employee in the staff table who makes a total amount more than their manager or has more years of service than their manager.
-- Make sure to include both salary and commission when calculating the total amount someone makes.
-- Exclude staff in department 10 from the query.
-- Order the results by department then name
--
select id, name, dept, years, job from staff s where (s.salary+nvl(s.comm,0) > (select salary+nvl(comm,0) from staff where job = 'Mgr' and s.dept = dept and s.dept != 10)) or (s.years > (select years from staff where job = 'Mgr' and s.dept = dept and s.dept !=10)) order by dept, name;
--
-- QUESTION 5:
-- Show a list of all employees, their department and their jobs, from the staff table, that are in the same department as 'Graham'
-- Order by name alphabetically.  Exclude 'Graham' from the result set.
-- 
select name, dept, job from staff where dept = (select dept from staff where name = 'Graham') and name != 'Graham' order by name;
--
-- QUESTION 6:
-- Show the list of employee names, job and variable pay, from the employee table, who have the lowest and highest variable pay (includes commission and bonus) by job category.
-- The name should be formatted:  lastname, firstname with the first character capitalized and all other characters in lower case.  (ie: King, Les).  The title of the column should be "Name".
-- The variable pay column should be called “Variable Pay”.
-- Order the results by highest variable pay to lowest variable pay.
--
select initcap(lastname) ||', '|| initcap(firstname) as "Name", job, bonus+comm as "Variable Pay" from employee where ((job, bonus+comm) in (select job, min(bonus+comm) from employee group by job)) or ((job, bonus+comm) in (select job, max(bonus+comm) from employee group by job)) order by 3 desc;
--
-- QUESTION 7:
-- Using the staff table, show all employees who have an 'il' in their name - or - their name ends with an 's'.  Make sure your query is case insensitive.
-- You just need to display the name of the employee in your output.  Order them alphabetically.
--
select name from staff where lower(name) like '%il%' OR lower(name) like '%s' order by name;
-- 
-- QUESTION 8:
--
-- Using the staff table, display the employee name, job, salary and commission for all employees with a salary less than the salary of all people with a manager job or full compensation less than the full compensation of all the people with a sales job.
-- Full compensation is the sum of both salary and commission.
-- Exclude people with a sales job from the output.
--
select name, job, salary, comm from staff where ((salary < ALL (select salary from staff where job = 'Mgr')) or (salary+comm < ALL (select salary+comm from staff where job = 'Sales'))) and (job != 'Sales');
--
-- QUESTION 9:
-- From the employee table, calculate the average compensation for each job category where the employee has 16 or more years of education.
-- Display the job and average compensation in the result set.
-- Exclude people who are clerks
-- Make sure to include salary, commission and bonus when looking at employee compensation
-- Order the output by the average salary in ascending order
--
select job, cast(avg(salary+comm+bonus) as decimal(9,2)) from employee where edlevel >=16 group by job having job != 'CLERK' order by 2 asc;
--
-- QUESTION 10:
-- Show the first name, last name, hire date, birth date, education level and years of service for employees who are both in the staff table and the employee table
-- An individual is the same individual if a case insensitive comparison of last name matches.
--  
select firstname, lastname, hiredate, birthdate, edlevel, years from employee, staff where lower(lastname) = lower(name);
--
-- STEP 7:  What to hand in
-- Hand in your completed .sql script (this file with your queries)
-- Hand in an output file called dbs311-test-output-lastname-firstname which contains all the output from executing your .sql script
-- I should receive two files from you in an email, for example:  dbs311-test-king-les.sql and dbs311-test-output-king-les
--