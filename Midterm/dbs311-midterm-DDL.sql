--
-- Create the EMPLOYEE table
--
create table employee (EMPNO char(6), FIRSTNAME varchar(12), MIDINIT char(1), LASTNAME varchar(15), WORKDEPT char(3), PHONENO char(4), HIREDATE date, JOB char(8), EDLEVEL smallint, SEX char(1), BIRTHDATE date, SALARY decimal(9,2), BONUS decimal(9,2), COMM decimal(9,2));
--
-- Create the STAFF table
--
create table staff (ID smallint, NAME varchar(9), DEPT smallint, JOB char(5), YEARS smallint, SALARY decimal(7,2), COMM decimal(7,2));
