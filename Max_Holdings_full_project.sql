-- =============================================================
-- Creation of Database for the project
-- =============================================================
CREATE DATABASE Max_Holdings;
USE Max_Holdings;

-- =============================================================
-- SHOW ALL TABLE DATA
-- =============================================================
SELECT * FROM employee_info;
SELECT * FROM salary;
SELECT * FROM departments;
SELECT * FROM division;

-- =============================================================
-- Description of the tables
-- =============================================================
DESCRIBE employee_info;
DESCRIBE salary;
DESCRIBE departments;
DESCRIBE division;


-- =============================================================
-- Change data types of columns with wrong data type
-- (All text data types should be converted to VARCHAR)
-- =============================================================
-- EMPLOYEE_INFO TABLE
ALTER TABLE employee_info
MODIFY COLUMN First_Name VARCHAR(30),
MODIFY COLUMN Last_Name VARCHAR(30),
MODIFY COLUMN Gender VARCHAR(10),
MODIFY COLUMN Date_of_Birth DATE,
MODIFY COLUMN Join_Date DATE,
MODIFY COLUMN Role VARCHAR(100),
MODIFY COLUMN Email_address VARCHAR(50);

-- SALARY TABLE
ALTER TABLE salary
MODIFY COLUMN Designation VARCHAR(100),
MODIFY COLUMN Deduction_percentage DECIMAL(5, 2);

-- DEPARTMENTS TABLE
ALTER TABLE departments
MODIFY COLUMN Department VARCHAR(50),
MODIFY COLUMN Dept_Resumption_Time TIME,
MODIFY COLUMN Dept_Closing_Time TIME;

-- DIVISION TABLE
ALTER TABLE division
MODIFY COLUMN Division VARCHAR(50);


-- =============================================================
-- CREATE FULL VIEW FOR INSIGHTS & TO SHOW TABLE RELATIONSHIPS
-- =============================================================

CREATE VIEW raw_view AS
SELECT 	ID, First_Name, Last_Name, Gender, Date_of_Birth, Age, Join_Date, Role, 
		Designation, Tenure_in_org_in_months, Gross_Pay, Net_Pay, Deduction_percentage,
		Division,
		Department, HOD_ID, Dept_Resumption_Time, Dept_Closing_Time  
FROM employee_info e
JOIN salary s ON e.ID = s.EmpID
JOIN division v ON s.Division_ID = v.Division_ID 
JOIN departments d ON v.Dept_ID = d.Dept_ID;

SELECT * FROM raw_view;


-- =============================================================
-- HANDLE DUPLICATE RECORDS
-- =============================================================

-- _____________________________________________________________
-- Show employees with Duplicate records:
-- _____________________________________________________________

-- Employee_info Table
SELECT ID, First_Name, Last_Name, COUNT(ID) AS no_of_entries
FROM employee_info
GROUP BY ID, First_Name, Last_Name
HAVING COUNT(ID) > 1
ORDER BY 4 DESC;

-- Salary Table
SELECT EmpID, COUNT(EmpID) AS no_of_entries
FROM salary
GROUP BY EmpID
HAVING COUNT(EmpID) > 1;

-- Only Employee_info has duplicate records

-- _____________________________________________________________
-- Show duplicate entries in the order they appear in the table:
-- _____________________________________________________________

WITH Duplicate_emp AS (
						SELECT 	emp_unique_id, ID, First_Name, Last_Name, 
								ROW_NUMBER() OVER(PARTITION BY ID ORDER BY ID) AS entry_no
						FROM employee_info)

SELECT * 
FROM Duplicate_emp WHERE entry_no >1
ORDER BY ID;

-- _____________________________________________________________
-- Add AUTO INCREMENT COLUMN TO Employee_info Table for Easy and Safe Deletion of Duplicate Records
-- This is to prevent total deletion of records that have the same ID
-- _____________________________________________________________

ALTER TABLE employee_info 
ADD COLUMN emp_unique_id INT AUTO_INCREMENT PRIMARY KEY;

-- _____________________________________________________________
-- Show duplicate entries with emp_unique_id:
-- _____________________________________________________________

WITH Duplicate_emp AS (
						SELECT 	emp_unique_id, ID, First_Name, Last_Name, 
								ROW_NUMBER() OVER(PARTITION BY ID ORDER BY ID) AS entry_no
						FROM employee_info)

SELECT * 
FROM Duplicate_emp WHERE entry_no >1
ORDER BY ID;

-- _____________________________________________________________
-- Delete duplicate entries:
-- _____________________________________________________________

WITH Duplicate_emp AS (
						SELECT 	emp_unique_id,
								ROW_NUMBER() OVER (PARTITION BY ID ORDER BY emp_unique_id) AS entry_no
						FROM employee_info)
                        
DELETE FROM employee_info
WHERE emp_unique_id IN (
						SELECT emp_unique_id 
                        FROM Duplicate_emp WHERE entry_no > 1)
;

-- _____________________________________________________________
-- Confirm Total No. of Records after removal of duplicates:
-- _____________________________________________________________
SELECT COUNT(*)
FROM employee_info;

ALTER TABLE employee_info
DROP COLUMN emp_unique_id;


-- =============================================================
-- HANDLE NULL & MISSING VALUES
-- =============================================================


-- NULL Value Check in Employee_info Table:

SELECT COUNT(*) AS Null_Records 
FROM Employee_info 
WHERE ID IS NULL OR Date_of_Birth IS NULL OR Age IS NULL OR Join_Date IS NULL OR Role IS NULL;


-- NULL Value Check in salary Table:

SELECT COUNT(*) 
FROM Salary 
WHERE EmpID IS NULL OR Division_ID IS NULL OR Tenure_in_org_in_months IS NULL 
OR Gross_Pay IS NULL OR Net_Pay IS NULL OR Deduction IS NULL;

-- _____________________________________________________________
-- Missing Value Check (Zero Age is not valid, so it is regarded as missing value):

SELECT * FROM Employee_info 
WHERE Age = 0;



-- =============================================================
-- REPLACEMENT OF MISSING VALUES
-- =============================================================

-- _____________________________________________________________
-- We have to first find the period the records ended
-- _____________________________________________________________
WITH audit_interval AS (
						SELECT 	ID, Join_Date, 
								DATE_ADD(Join_Date, INTERVAL Tenure_in_org_in_months MONTH) AS End_date
						FROM employee_info e
						JOIN salary s
						ON e.ID = s.EmpID)

SELECT MAX(End_date) AS Audit_Date from audit_interval;


-- Assumed End date = 2020/07/15


-- _____________________________________________________________
-- Calculate Age For Employees with missing values
-- We deduct Date_of_Birth from Audit_Date
-- _____________________________________________________________

UPDATE employee_info
SET age = TIMESTAMPDIFF(YEAR, Date_of_Birth, '2020/07/15')
WHERE age = 0;


-- =============================================================
-- CHECKING FOR ERRORS AND INCONSISTENCIES
-- =============================================================

-- Confirm if Net salary = Gross salary - Deduction (within margin of error):

SELECT * FROM salary
WHERE Gross_Pay - Deduction != Net_Pay;

-- _____________________________________________________________

-- Confirm any significant difference between calculated deduction and original salary table deduction
-- Check in ascending & descending order of difference:

SELECT 	EmpID, Tenure_in_org_in_months, Gross_Pay,  
		Deduction_percentage,
		Deduction, 
		ROUND(Gross_Pay * Deduction_percentage/100) AS calculated_deduction,
		Deduction - ROUND(Gross_Pay * Deduction_percentage/100) AS difference,
		Net_Pay
FROM salary;


-- =========================================================
-- CLEANING RECORDS WITH STRING FUNCTIONS
-- =========================================================

-- Replace dots with space in Role column of employee_info table:

UPDATE employee_info
SET Role = REPLACE(Role, '.', ' ');
-- _____________________________________________________________

-- Trim out white spaces in First_Name & Last_Name columns of employee_info table:

UPDATE employee_info
SET First_Name = TRIM(First_Name),
Last_Name = TRIM(Last_Name);
-- _____________________________________________________________

-- Change First_Name & Last_Name to proper form:

UPDATE employee_info
SET First_Name = CONCAT(UPPER(SUBSTRING(First_Name, 1, 1)),LOWER(SUBSTRING(First_Name, 2))),
Last_Name = CONCAT(UPPER(SUBSTRING(Last_Name, 1, 1)),LOWER(SUBSTRING(Last_Name, 2)));

-- _____________________________________________________________

-- Standardize the Gender values (F for Female, M for Male):

UPDATE employee_info
SET Gender =
			CASE WHEN Gender = 'F' THEN 'Female'
								ELSE 'Male'
            END;

-- ================================================================
-- ================================================================


-- =============================================================
-- 1. STRUCTURAL INSIGHTS
-- =============================================================

-- A. ORGANISATION STRUCTURAL DISTRIBUTION
-- Give a breakdown of the organisation's structure:

SELECT 	COUNT(DISTINCT Department) AS No_of_Departments, 
		COUNT(DISTINCT Division) AS No_of_Divisions,
		COUNT(DISTINCT Role) AS No_of_Roles,
        COUNT(DISTINCT e.ID) AS No_of_Employees
FROM employee_info e
JOIN salary s ON e.ID = s.EmpID
JOIN division v ON s.Division_ID = v.Division_ID
JOIN departments d ON v.Dept_ID = d.Dept_ID;
-- _____________________________________________________________
-- Departments => 13
-- Divisions => 154
-- Roles => 390
-- Employees => 1,802
-- =============================================================

-- B. Number of divisions in each department:

SELECT 	Department, 
		COUNT(division) AS No_of_divisions
FROM departments d
JOIN division v ON d.Dept_ID = v.Dept_ID
GROUP BY Department
ORDER BY No_of_divisions DESC;
-- _____________________________________________________________
-- Highest no. of divisions => Sales & marketing (37 Divisions)
-- Lowest no. of divisions => Legal & Compliance (1)
-- =============================================================


-- C. Number of Roles in each department:

SELECT 	Department, 
		COUNT(DISTINCT Role) AS No_of_roles
FROM employee_info e
JOIN salary s ON e.ID = s.EmpID
JOIN division v ON s.Division_ID = v.Division_ID
JOIN departments d ON v.Dept_ID = d.Dept_ID
GROUP BY Department 
ORDER BY No_of_roles DESC;
-- _____________________________________________________________
-- Highest no. of Roles => Operations & Infrastructure (120 Roles)
-- Lowest no. of Roles => Legal & Compliance (2)
-- =============================================================


-- D. Employee distribution by Department:

SELECT 	Department, 
		COUNT(*) AS No_of_employees
FROM employee_info e
JOIN salary s ON e.ID = s.EmpID
JOIN division v ON s.Division_ID = v.Division_ID
JOIN departments d ON v.Dept_ID = d.Dept_ID
GROUP BY Department
ORDER BY No_of_employees DESC;
-- _____________________________________________________________

-- E. Employee distribution by Division:

SELECT 	Division, 
		COUNT(*) AS No_of_employees
FROM employee_info e
JOIN salary s ON e.ID = s.EmpID
JOIN division v ON s.Division_ID = v.Division_ID
JOIN departments d ON v.Dept_ID = d.Dept_ID
GROUP BY Division
ORDER BY No_of_employees DESC;
-- _____________________________________________________________

-- F. Employee distribution by Role:

SELECT 	Role, 
		COUNT(*) AS No_of_employees
FROM employee_info 
GROUP BY Role
ORDER BY No_of_employees DESC;
-- _____________________________________________________________

-- G. Heads of Departments and number of employees they lead:

WITH Dept_lead AS ( 
				SELECT Dept_ID, Department, HOD_ID, CONCAT(First_Name, ' ', Last_Name) AS HOD
				FROM departments AS d
				JOIN employee_info AS e ON ID = HOD_ID),
                
  Staff AS      (SELECT ID, Department
                FROM employee_info e
                JOIN salary s ON e.ID = s.EmpID
                JOIN division v ON s.Division_ID = v.Division_ID
                JOIN departments d ON v.Dept_ID = d.Dept_ID)
                
SELECT 	dl.Department, HOD, 
		COUNT(st.ID) - 1 AS no_of_subordinates
FROM dept_lead dl
JOIN Staff st ON dl.department = st.department
GROUP BY dl.Department, HOD_ID, HOD;
-- _____________________________________________________________

-- H. Number of employees who are managers:

SELECT COUNT(*) AS "No. of Managers"
FROM employee_info e
JOIN salary s ON ID = EmpID
WHERE Role LIKE '%manager%';
-- _____________________________________________________________
-- 403 employees are managers
-- =============================================================


-- =============================================================
-- 2. DEMOGRAPHIC INSIGHTS
-- =============================================================

-- A.i. GENDER DISTRIBUTION:

SELECT 	Gender, COUNT(*) AS Total_Employees, 
		CONCAT(ROUND(COUNT(*)/1802 * 100), '%') AS "%"
FROM employee_info
GROUP BY Gender;
-- _____________________________________________________________
-- Male => 1303 (72%)
-- Female => 499 (28%)
-- =============================================================

-- ii. DISTRIBUTION OF GENDER BY DEPARTMENT:

SELECT 	Department, Gender, 
		Count(ID) AS gender_count, total_dept_staff,
		CONCAT(ROUND(COUNT(ID)/total_dept_staff * 100),'%') AS "%"
FROM 
	(SELECT ID, First_Name, Last_Name, Gender, d.Department,
	COUNT(Gender) OVER (PARTITION BY Department ) AS total_dept_staff
	FROM employee_info e 
	JOIN salary s ON e.ID = s.EmpID
	JOIN division v ON s.Division_ID = v.Division_ID
	JOIN departments d ON v.Dept_ID = d.Dept_ID
	) AS staff_dept
GROUP BY Department, Gender
ORDER BY Department, Gender;
-- _____________________________________________________________

-- iii. DEPARTMENTAL FEMALE REPRESENTATION: Departments with at least 30% female employees
SELECT 	Department, Gender, 
		Count(ID) AS gender_count, total_dept_staff,
		ROUND(COUNT(ID)/total_dept_staff * 100) AS "%"
FROM 
	(SELECT ID, First_Name, Last_Name, Gender, d.Department,
	COUNT(Gender) OVER (PARTITION BY Department ) AS total_dept_staff
	FROM employee_info e 
	JOIN salary s ON e.ID = s.EmpID
	JOIN division v ON s.Division_ID = v.Division_ID
	JOIN departments d ON v.Dept_ID = d.Dept_ID
	) AS staff_dept
WHERE Gender = 'F'
GROUP BY Department, Gender
HAVING `%` >= 30
ORDER BY Department, Gender;
-- _____________________________________________________________
-- 7 Departments have at least 30% Female Employee Population
-- =============================================================

-- iv. Departments with less than 30% female employees:
SELECT 	Department, Gender, Count(ID) AS gender_count, total_dept_staff,
		ROUND(COUNT(ID)/total_dept_staff * 100) AS "%"
FROM 
	(SELECT ID, First_Name, Last_Name, Gender, d.Department,
	COUNT(Gender) OVER (PARTITION BY Department ) AS total_dept_staff
	FROM employee_info e 
	JOIN salary s ON e.ID = s.EmpID
	JOIN division v ON s.Division_ID = v.Division_ID
	JOIN departments d ON v.Dept_ID = d.Dept_ID
	) AS staff_dept
WHERE Gender = 'F'
GROUP BY Department, Gender
HAVING `%` < 30
ORDER BY Department, Gender;
-- _____________________________________________________________
-- 6 Departments have less than 30% Female Employee Population
-- =============================================================


-- =============================================================
-- B. AGE DISTRIBUTION
-- =============================================================

-- i. Age Summary:

SELECT 	MIN(Age) AS youngest_age, 
		MAX(Age) AS oldest_age, 
		ROUND(AVG(Age)) AS average_age
FROM employee_info;
-- _____________________________________________________________
-- Youngest Age => 21
-- Oldest Age => 56
-- Average Age => 32
-- =============================================================

-- ii. Modal/Most common age:

SELECT Age, COUNT(Age) AS no_of_employees
FROM employee_info
GROUP BY Age
ORDER BY no_of_employees DESC
LIMIT 1;
-- _____________________________________________________________
-- Modal Age => 29 (170 Employees)
-- =============================================================


-- iii. Distribution of Employees by Age groups/buckets:

SELECT 
  CASE 
		WHEN Age BETWEEN 21 AND 25 THEN '21-25'
		WHEN Age BETWEEN 26 AND 30 THEN '26-30'
		WHEN Age BETWEEN 31 AND 35 THEN '31-35'
		WHEN Age BETWEEN 36 AND 40 THEN '36-40'
		WHEN Age BETWEEN 41 AND 45 THEN '41-45'
		WHEN Age BETWEEN 46 AND 50 THEN '46-50'
		ELSE 'Above 50'
  END AS Age_Group,
		COUNT(*) AS no_of_employees
FROM employee_info
GROUP BY Age_Group;
-- _____________________________________________________________
-- a. 21-25 => 192 Employees
-- b. 26-30 => 672 Employees
-- c. 31-35 => 550 Employees
-- d. 36-40 => 282 Employees
-- e. 41-45 => 82 Employees
-- f. 46-50 => 20 Employees
-- g. Above 50 => 4 Employees
-- =============================================================


-- =============================================================
-- C. TENURE DISTRIBUTION
-- =============================================================

-- i. Tenure Summary in years:

WITH tenure_in_years AS
					(SELECT ROUND(Tenure_in_org_in_months/12,2) AS tenure
					FROM salary)

SELECT 	MIN(tenure) AS Lowest_Tenure, 
		MAX(tenure) AS Highest_Tenure, 
        ROUND(AVG(tenure),2) AS Average_Tenure 
FROM tenure_in_years;
-- _____________________________________________________________
-- Lowest Tenure = 0.5 years
-- Highest Tenure = 15.83 years
-- Average Tenure = 4.03 years
-- =============================================================



-- ii. Employee Tenure in Years:

SELECT  ID, First_Name, Last_Name, Gender, Age, Tenure_in_org_in_months, 
		ROUND(Tenure_in_org_in_months/12,2) AS Tenure_in_years
FROM salary s
JOIN employee_info e ON s.EmpID = e.ID
ORDER BY Tenure_in_years DESC;
-- _____________________________________________________________

-- iii. Average Tenure in years by Department:

SELECT 	Department, 
		ROUND(AVG(Tenure_in_org_in_months/12),2) AS Average_Tenure_in_Years  
FROM departments d
JOIN division v ON d.Dept_ID = v.Dept_ID
JOIN salary s ON v.Division_ID = s.Division_ID
GROUP BY Department
ORDER BY Average_Tenure_in_Years DESC;
-- _____________________________________________________________

-- iv. Average Tenure in years by Role:

SELECT 	Role, 
		ROUND(AVG(Tenure_in_org_in_months/12),2) AS Average_Tenure_in_Years  
FROM employee_info e
JOIN salary s ON e.ID = s.EmpID
GROUP BY Role
ORDER BY Average_Tenure_in_Years  DESC;
-- _____________________________________________________________

-- v. Tenure Distribution in Years by Tenure Bucket:

SELECT 
  CASE 
		WHEN ROUND(Tenure_in_org_in_months/12,2) < 1 THEN 'a. Less than 1 Year'
		WHEN ROUND(Tenure_in_org_in_months/12,2) BETWEEN 1 AND 2.99 THEN 'b. 1.00-2.99 Years'
		WHEN ROUND(Tenure_in_org_in_months/12,2) BETWEEN 3 AND 4.99 THEN 'c. 3.00-4.99 Years'
		WHEN ROUND(Tenure_in_org_in_months/12,2) BETWEEN 5 AND 6.99 THEN 'd. 5.00-6.99 Years'
		WHEN ROUND(Tenure_in_org_in_months/12,2) BETWEEN 7 AND 8.99 THEN 'e. 7.00-8.99 Years'
		WHEN ROUND(Tenure_in_org_in_months/12,2) BETWEEN 9 AND 10.99 THEN 'f. 9.00-10.99 Years'
		WHEN ROUND(Tenure_in_org_in_months/12,2) BETWEEN 11 AND 12.99 THEN 'g. 11.00-12.99 Years'
		WHEN ROUND(Tenure_in_org_in_months/12,2) BETWEEN 13 AND 14.99 THEN 'h. 13.00-14.99 Years'
		ELSE 'i. >= 15 Years'
	END AS Tenure,
		COUNT(*) AS No_of_employees
FROM Salary
GROUP BY Tenure
ORDER BY Tenure;
-- _____________________________________________________________
-- a. Less than 1 Year => 212 employees
-- b. 1.00-2.99 Years => 574
-- c. 3.00-4.99 Years => 470
-- d. 5.00-6.99 Years => 265
-- e. 7.00-8.99 Years => 144
-- f. 9.00-10.99 Years => 67
-- g. 11.00-12.99 Years => 49
-- h. 13.00-14.99 Years => 14
-- i. >= 15 Years => 7
-- =============================================================


-- vi. Average Tenure in Years by Age Group:

SELECT 
	CASE 
		WHEN Age BETWEEN 21 AND 25 THEN '21-25'
		WHEN Age BETWEEN 26 AND 30 THEN '26-30'
		WHEN Age BETWEEN 31 AND 35 THEN '31-35'
		WHEN Age BETWEEN 36 AND 40 THEN '36-40'
		WHEN Age BETWEEN 41 AND 45 THEN '41-45'
		WHEN Age BETWEEN 46 AND 50 THEN '46-50'
		ELSE 'Above 50'
	END AS Age_Group,
		COUNT(*) AS no_of_employees,
		ROUND(AVG(Tenure_in_org_in_months/12),2) AS Avg_Tenure_in_Years
FROM employee_info e
JOIN salary s ON e.ID = s.EmpID
GROUP BY Age_Group
ORDER BY Avg_Tenure_in_Years DESC;
-- _____________________________________________________________
-- a. 21-25 => 1.64 years
-- b. 26-30 => 2.91 years
-- c. 31-35 => 4.44 years
-- d. 36-40 => 6.33 years
-- e. 41-45 => 7..48 years
-- f. 46-50 => 6.06 years
-- g. Above 50 => 8.46 years
-- =============================================================


-- =============================================================
-- 3. HIRING TRENDS
-- =============================================================

-- A. Number of employees joined per year & cumulative number of employees:

SELECT 	YEAR(Join_Date) AS Year, 
		COUNT(*) AS employees_hired,
        SUM(COUNT(*)) OVER (ORDER BY YEAR(Join_Date)) AS Agg_staff_population
FROM Employee_info
GROUP BY YEAR(Join_Date);
-- _____________________________________________________________
-- 2020 => 24 employees
-- 2019 => 367 (highest)
-- 2018 => 226
-- 2017 => 352 (2nd highest)
-- 2016 => 208
-- 2015 => 175
-- 2014 => 133
-- 2013 => 102
-- 2012 =>55
-- 2011 => 42
-- 2010 => 34
-- 2009 => 29
-- 2008 => 25
-- 2007 => 12
-- 2006 => 9
-- 2005 => 2
-- 2004 => 7 
-- =============================================================


-- B. Overall Monthly recruitmment trend:

SELECT 	Date, Month, 
		COUNT(joined) AS employees_hired 
FROM
	(SELECT DATE_FORMAT(Join_Date, '%m/%Y') AS Date, 
			CONCAT(MONTHNAME(Join_Date), ' ', YEAR(Join_Date)) AS Month, 
			COUNT(*) OVER (PARTITION BY (Join_Date)) AS joined
	FROM employee_info) AS joined
GROUP BY Date, Month;
-- _____________________________________________________________


-- C. Top Hiring Month_Year:

SELECT Date, Month_Year, COUNT(joined) AS employees_hired 
FROM
	(SELECT DATE_FORMAT(Join_Date, '%m/%Y') AS Date, 
			CONCAT(MONTHNAME(Join_Date), ' ', YEAR(Join_Date)) AS Month_Year, 
			COUNT(*) OVER (PARTITION BY (Join_Date)) AS joined
	FROM employee_info) AS joined
GROUP BY Date, Month_Year
ORDER BY employees_hired DESC;
-- _____________________________________________________________
-- July 2019 experienced the highest recruitment with 79 employees
-- =============================================================

--  D. Monthly join trend (last whole year) including January 2020:

SELECT 	Date, Month, 
		COUNT(joined) AS employees_hired, 
        SUM(COUNT(joined)) OVER (ORDER BY Date) AS cumulative_hired
FROM
	(SELECT DATE_FORMAT(Join_Date, '%m/%Y') AS Date, 
			CONCAT(MONTHNAME(Join_Date), ' ', YEAR(Join_Date)) AS Month, 
			COUNT(*) OVER (PARTITION BY (Join_Date)) AS joined
	FROM employee_info
	WHERE YEAR(Join_Date) >= 2019) AS last_year_recruits
GROUP BY Date, Month;
-- _____________________________________________________________


-- E. Recruitment trend of female employees in the final period:

WITH final_hire AS (SELECT 	DATE_FORMAT(Join_Date, '%m/%Y') AS Date, 
							CONCAT(MONTHNAME(Join_Date), ' ', 
							YEAR(Join_Date)) AS Month, Gender, 
							COUNT(*) OVER (PARTITION BY (Join_Date)) AS joined
					FROM employee_info
					WHERE YEAR(Join_Date) >= 2019),
                    
 Last_recruits AS   (SELECT Date, Month, 
							COUNT(joined) AS Staff_hired 
					FROM Final_hire
                    GROUP BY Date, Month),
                    
   Female_Hires As  (SELECT Date, Month, 
							COUNT(joined) AS Females_hired 
					FROM Final_hire 
                    WHERE Gender = "F"
                    GROUP BY Date, Month)
                    
SELECT 	f.Date, f.Month, Staff_hired, Females_hired,
		CONCAT(ROUND(Females_hired/staff_hired *100),"%") As "Female_%"
FROM Last_recruits l
JOIN Female_Hires f ON l.Date = f.Date;


-- =============================================================
-- 4. SALARY INSIGHTS
-- =============================================================

-- A. DESCRIPTIVE STATISTICS FOR SALARY
-- =============================================================

-- i. Summary Statistics for Monthly Gross salary:

WITH Monthly_Gross_salary AS 
							(SELECT  Gross_Pay / Tenure_in_org_in_months AS Monthly_Gross_pay
							FROM salary
							WHERE Tenure_in_org_in_months IS NOT NULL
							  AND Tenure_in_org_in_months > 0),
                             
Ordered_Salaries AS 
					(SELECT Monthly_gross_pay,
							ROW_NUMBER() OVER (ORDER BY Monthly_Gross_pay) AS RowNum,
							COUNT(*) OVER () AS TotalRows
					FROM Monthly_Gross_salary),
                    
Median_Rows AS 
				(SELECT Monthly_Gross_pay
				 FROM Ordered_Salaries
				 WHERE RowNum = FLOOR((TotalRows + 1) / 2)
					OR RowNum = CEIL((TotalRows + 1) / 2))
                    
SELECT
    ROUND(AVG(mg.Monthly_Gross_pay), 0) AS Avg_Gross_salary,
    ROUND(MIN(mg.Monthly_Gross_pay),0) AS Lowest_Gross_salary,
    ROUND(MAX(mg.Monthly_Gross_pay),0) AS Highest_Gross_salary,
    ROUND((MAX(mg.Monthly_Gross_pay) - MIN(mg.Monthly_Gross_pay)),0) AS Range_Gross_Salary,
    ROUND(STDDEV(mg.Monthly_Gross_pay), 0) AS StdDev_Gross_salary,
    ROUND(VARIANCE(mg.Monthly_Gross_pay), 0) AS Variance_Gross_salary,
    ROUND(AVG(mr.Monthly_Gross_pay), 0) AS Median_Gross_salary
FROM Monthly_Gross_salary mg
CROSS JOIN Median_Rows mr;
-- _____________________________________________________________
-- Average Gross Salary => $5,916
-- Median Gross Salary => $3,726
-- Highest Gross Salary => $74,179
-- Lowest Gross Salary => $11
-- =============================================================


-- ii. Summary Statistics for Monthly Net salary:

WITH Monthly_Net_salary AS 
							(SELECT  Net_Pay / Tenure_in_org_in_months AS Monthly_Net_pay
							FROM salary
							WHERE Tenure_in_org_in_months IS NOT NULL
							  AND Tenure_in_org_in_months > 0),
                             
Ordered_Salaries AS 
					(SELECT Monthly_Net_pay,
							ROW_NUMBER() OVER (ORDER BY Monthly_Net_pay) AS RowNum,
							COUNT(*) OVER () AS TotalRows
					FROM Monthly_Net_salary),
                    
Median_Rows AS 
				(SELECT Monthly_Net_pay
				 FROM Ordered_Salaries
				 WHERE RowNum = FLOOR((TotalRows + 1) / 2)
					OR RowNum = CEIL((TotalRows + 1) / 2))
                    
SELECT
    ROUND(AVG(mn.Monthly_Net_pay), 0) AS Avg_Net_salary,
    ROUND(MIN(mn.Monthly_Net_pay),0) AS Lowest_Net_salary,
    ROUND(MAX(mn.Monthly_Net_pay),0) AS Highest_Net_salary,
    ROUND((MAX(mn.Monthly_Net_pay) - MIN(mn.Monthly_Net_pay)),0) AS Range_Net_Salary,
    ROUND(STDDEV(mn.Monthly_Net_pay), 0) AS StdDev_Net_salary,
    ROUND(VARIANCE(mn.Monthly_Net_pay), 0) AS Variance_Net_salary,
    ROUND(AVG(mr.Monthly_Net_pay), 0) AS Median_Net_salary
FROM Monthly_Net_salary mn
CROSS JOIN Median_Rows mr;
-- _____________________________________________________________
-- Average Net Salary => $4,446
-- Median Net Salary => $2,684
-- Highest Net Salary => $71,955
-- Lowest Net Salary => $11
-- =============================================================


-- =============================================================
-- B. NET MONTHLY SALARY DISTRIBUTION
-- =============================================================

SELECT 
  CASE 
		WHEN ROUND(Net_Pay/Tenure_in_org_in_months) < 1000 THEN 'a. < $1K'
		WHEN ROUND(Net_Pay/Tenure_in_org_in_months) BETWEEN 1000 AND 3000 THEN 'b. $1K-$3K'
		WHEN ROUND(Net_Pay/Tenure_in_org_in_months) BETWEEN 3001 AND 5000 THEN 'c. >$3K-$5K'
		WHEN ROUND(Net_Pay/Tenure_in_org_in_months) BETWEEN 5001 AND 10000 THEN 'd. >$5K-$10K'
		WHEN ROUND(Net_Pay/Tenure_in_org_in_months) BETWEEN 10001 AND 15000 THEN 'e. >$10K-$15K'
		WHEN ROUND(Net_Pay/Tenure_in_org_in_months) BETWEEN 15001 AND 20000 THEN 'f. >$15K-$20K'
		WHEN ROUND(Net_Pay/Tenure_in_org_in_months) BETWEEN 20001 AND 40000 THEN 'g. >$20K-$40K'
		ELSE 'h. > $40K'
	END AS Net_Salary_Range,
		COUNT(*) AS No_of_employees
FROM Salary
GROUP BY Net_Salary_Range
ORDER BY Net_Salary_Range;
-- _____________________________________________________________
-- a. < $1K = 78 Employees
-- b. $1K-$3K = 925
-- c. >$3K-$5K = 350
-- d. >$5K-$10K = 287
-- e. >$10K-$15K = 97
-- f. >$15K-$20K = 32
-- g. >$20K-$40K = 27
-- h. > $40K = 6
-- =============================================================


-- =============================================================
-- C. GENDER SALARY EQUITY ANALYSIS
-- =============================================================

-- i. Average Salary Comparison by Gender:

WITH mth_pay AS
				(SELECT EmpID, 
						Gross_Pay/Tenure_in_org_in_months AS Gross_monthly_pay, 
						Net_Pay/Tenure_in_org_in_months AS Net_monthly_pay 
                FROM salary)

SELECT 	Gender, 
		ROUND(AVG(Gross_monthly_pay)) AS Gross_monthly_Salary,
		ROUND(AVG(Net_monthly_pay)) AS Net_monthly_Salary
FROM salary AS s
JOIN employee_info AS i ON EmpID = ID
JOIN mth_pay AS mp ON s.EmpID = mp.EmpID
GROUP BY Gender;
-- _____________________________________________________________
-- Gender	|	Gross_Monthly	|	Net_Monthly
-- Male		|		$6,089		|		$4,467
-- Female	|		$5,465		|		$4,393
-- =============================================================


-- ii. Average Salary Comparison by Gender in each Department:

WITH mth_pay AS
				(SELECT EmpID, 
						Gross_Pay/Tenure_in_org_in_months AS Gross_monthly_pay, 
						Net_Pay/Tenure_in_org_in_months AS Net_monthly_pay 
				FROM salary)

SELECT 	Department, Gender,
		ROUND(AVG(Gross_monthly_pay)) AS Gross_monthly_Salary, 
		ROUND(AVG(Net_monthly_pay)) AS Net_monthly_Salary
FROM salary AS s
JOIN employee_info AS i ON EmpID = ID
JOIN division AS dv ON s.Division_ID = dv.Division_ID
JOIN departments AS d ON dv.Dept_ID = d.Dept_ID
JOIN mth_pay AS mp ON s.EmpID = mp.EmpID
GROUP BY Department, Gender
ORDER BY Department, Net_monthly_Salary DESC;
-- =============================================================


-- iii. Tenure Bucket vs Net Salary Correlation:

SELECT 
  CASE 
		WHEN ROUND(Tenure_in_org_in_months/12,2) < 1 THEN 'a. Less than 1 Year'
		WHEN ROUND(Tenure_in_org_in_months/12,2) BETWEEN 1 AND 2.99 THEN 'b. 1.00-2.99 Years'
		WHEN ROUND(Tenure_in_org_in_months/12,2) BETWEEN 3 AND 4.99 THEN 'c. 3.00-4.99 Years'
		WHEN ROUND(Tenure_in_org_in_months/12,2) BETWEEN 5 AND 6.99 THEN 'd. 5.00-6.99 Years'
		WHEN ROUND(Tenure_in_org_in_months/12,2) BETWEEN 7 AND 8.99 THEN 'e. 7.00-8.99 Years'
		WHEN ROUND(Tenure_in_org_in_months/12,2) BETWEEN 9 AND 10.99 THEN 'f. 9.00-10.99 Years'
		WHEN ROUND(Tenure_in_org_in_months/12,2) BETWEEN 11 AND 12.99 THEN 'g. 11.00-12.99 Years'
		WHEN ROUND(Tenure_in_org_in_months/12,2) BETWEEN 13 AND 14.99 THEN 'h. 13.00-14.99 Years'
		ELSE 'i. >= 15 Years'
	END AS Tenure,
        ROUND(AVG(Net_Pay/Tenure_in_org_in_months)) AS Avg_Monthly_Net_Salary
FROM Salary
GROUP BY Tenure
ORDER BY Tenure;
-- _____________________________________________________________
-- a. Less than 1 Year => $14,270
-- b. 1.00-2.99 Years => $4,910
-- c. 3.00-4.99 Years => $2,647
-- d. 5.00-6.99 Years => $1,936
-- e. 7.00-8.99 Years => $1,609
-- f. 9.00-10.99 Years => $1,479
-- g. 11.00-12.99 Years => $1,211
-- h. 13.00-14.99 Years => $1,046
-- i. >= 15 Years => $1,025

-- There is a negative correlation between tenure and salary
-- More recently recruited employees earn greater than their older colleagues
-- =============================================================




-- =============================================================
-- D. GENERAL SALARY ANALYSIS
-- =============================================================

-- i. Average Salary by Department:

WITH mth_pay AS
				(SELECT EmpID, 
						Gross_Pay/Tenure_in_org_in_months AS Gross_monthly_pay, 
						Net_Pay/Tenure_in_org_in_months AS Net_monthly_pay 
				FROM salary)

SELECT 	Department, 
		ROUND(AVG(Gross_monthly_pay)) AS Gross_monthly_Salary, 
		CONCAT(ROUND(AVG(Deduction_percentage),2),'%') AS "Deduction_%",
		ROUND(AVG(Net_monthly_pay)) AS Net_monthly_Salary
FROM salary AS s
JOIN employee_info AS i ON EmpID = ID
JOIN division AS dv ON s.Division_ID = dv.Division_ID
JOIN departments AS d ON dv.Dept_ID = d.Dept_ID
JOIN mth_pay AS mp ON s.EmpID = mp.EmpID
GROUP BY Department
ORDER BY Net_monthly_Salary DESC;
-- _____________________________________________________________
-- TOP 3 NET MONTHLY SALARY
-- 1. Legal & Compliance => $11,287
-- 2. Security Engineering => $7,003
-- 3. Technology => $5,723

-- BOTTOM 3 NET MONTHLY SALARY
-- 1. Finance => $3,146
-- 2. Human Resources & Talent => $4,981
-- 3. Customer Experience & Service Delivery => $4,955

-- =============================================================


-- ii. Average Salary by Role:

WITH mth_pay AS
				(SELECT EmpID, 
						Gross_Pay/Tenure_in_org_in_months AS Gross_monthly_pay, 
						Net_Pay/Tenure_in_org_in_months AS Net_monthly_pay 
				FROM salary)

SELECT 	Role, 
		ROUND(AVG(Gross_monthly_pay)) AS Gross_monthly_Salary, 
		CONCAT(ROUND(AVG(Deduction_percentage),2),'%') AS "Deduction_%",
		ROUND(AVG(Net_monthly_pay)) AS Net_monthly_Salary
FROM salary AS s
JOIN employee_info AS i ON EmpID = ID
JOIN mth_pay AS mp ON s.EmpID = mp.EmpID
GROUP BY Role
ORDER BY Net_monthly_Salary DESC
LIMIT 20;
-- _____________________________________________________________
-- TOP 5 NET MONTHLY SALARY
-- 1. Applications Developer II => $33,975
-- 2. Enterprise Security Architect Senior II => $24,439
-- 3. Site Reliability Engineer Senior => $23,782
-- 4. Support Delivery Manager => $22,597
-- 5. Finance Systems Analyst Senior Lead  => $20,917
-- =============================================================


-- iii. Highest Paid Employees:

WITH mth_pay AS
				(SELECT EmpID, 
						Gross_Pay/Tenure_in_org_in_months AS Gross_monthly_pay, 
						Net_Pay/Tenure_in_org_in_months AS Net_monthly_pay 
				FROM salary)
                    
SELECT 	RANK() OVER (ORDER BY ROUND(Net_monthly_pay) DESC) AS "Ranking",
		ID, First_Name, Last_Name, Gender, Department, Role,
		ROUND(Gross_monthly_pay) AS Gross_monthly_salary, 
		CONCAT(Deduction_percentage,'%') AS "Deduction_%", 
		ROUND(Net_monthly_pay) AS Net_monthly_salary
FROM salary AS s
JOIN employee_info AS i ON EmpID = ID
JOIN division AS dv ON s.Division_ID = dv.Division_ID
JOIN departments AS d ON dv.Dept_ID = d.Dept_ID
JOIN mth_pay AS mp ON s.EmpID = mp.EmpID
ORDER BY Net_monthly_salary DESC
LIMIT 20;
-- _____________________________________________________________

/* -- iv. Comparison of Employee Net Monthly salary to average Net monthly salary in the organisation,
	including the difference between employee salary and company's average salary:
*/

WITH Emp_Monthly_Net_Salary AS 
						(SELECT ID, First_Name, Last_Name, Gender, Role,
								ROUND(Tenure_in_org_in_months/12,2) AS Tenure_Yr,
								ROUND(Net_Pay/Tenure_in_org_in_months) AS Monthly_Net_pay
						FROM employee_info
                        JOIN salary ON ID = EmpID),
                        
	Avg_Monthly_Net_Salary AS 
							(SELECT ROUND(AVG(Net_Pay/Tenure_in_org_in_months)) AS Avg_Monthly_Net
							FROM salary)
	
SELECT ID, First_Name, Last_Name, Gender, Role, Tenure_Yr,
		Monthly_Net_pay,
		Avg_Monthly_Net,
		Monthly_Net_pay - Avg_Monthly_Net AS Diff_From_Avg
FROM Emp_Monthly_Net_Salary
JOIN Avg_Monthly_Net_Salary;
-- _____________________________________________________________

-- v. NO. OF EMPLOYEES WHO EARN MORE THAN THE AVERAGE MONTHLY SALARY IN THEIR RESPECTIVE DEPARTMENTS
-- Method 1:

WITH avg_dept_salary AS (SELECT Department, 
								ROUND(AVG(Net_pay/Tenure_in_org_in_months)) AS avg_net_salary
						FROM departments d
						JOIN division v ON d.Dept_ID = v.Dept_ID
						JOIN salary s ON v.Division_ID = s.Division_ID
						GROUP BY Department) 
            
SELECT 	d.Department, 
		COUNT(*) AS no_of_employees_earning_above_dept_avg_salary
FROM departments d
JOIN division v ON d.Dept_ID = v.Dept_ID
JOIN salary s ON v.Division_ID = s.Division_ID
JOIN avg_dept_salary ads ON d.Department = ads.Department
WHERE ROUND(s.Net_pay/Tenure_in_org_in_months) > avg_net_salary
GROUP BY d.Department WITH ROLLUP
ORDER BY no_of_employees_earning_above_dept_avg_salary ;


-- NO. OF EMPLOYEES WHO EARN MORE THAN THE AVERAGE MONTHLY SALARY IN THEIR RESPECTIVE DEPARTMENTS
-- Method 2:

WITH monthly_net_salary AS (SELECT 	s.EmpID, v.Division_ID, d.Department,
									ROUND(s.Net_pay / s.Tenure_in_org_in_months) AS monthly_net_pay	
							FROM salary s
							JOIN division v ON s.Division_ID = v.Division_ID
							JOIN departments d ON v.Dept_ID = d.Dept_ID ),
							
		avg_dept_salary AS (SELECT 	Department, 
									AVG(monthly_net_pay) AS avg_net_salary
							FROM monthly_net_salary
							GROUP BY Department ),

	above_avg_employees AS (SELECT mns.Department								
							FROM monthly_net_salary mns
							JOIN avg_dept_salary ads ON mns.Department = ads.Department
							WHERE mns.monthly_net_pay > ads.avg_net_salary )
							
SELECT 	Department, 
		COUNT(*) AS no_of_employees_earning_above_dept_avg_salary
FROM above_avg_employees
GROUP BY Department WITH ROLLUP
ORDER BY no_of_employees_earning_above_dept_avg_salary;
-- _____________________________________________________________


-- vi. NO. & PERCENTAGE OF EMPLOYEES WHO EARN MORE THAN THE AVERAGE MONTHLY SALARY IN THEIR RESPECTIVE DEPARTMENTS:

SELECT 	Department, tot_no_of_staff, 
		COUNT(Department) AS no_of_staff_above_avg_dept_salary,
		CONCAT(ROUND(COUNT(Department)/tot_no_of_staff * 100),'%') AS "%"
FROM
	(SELECT ID, Gender, Department, 
			ROUND(Net_Pay/Tenure_in_org_in_months) AS Net_monthly_pay,
			AVG(ROUND(Net_Pay/Tenure_in_org_in_months)) OVER (PARTITION BY Department ) AS avg_dept_salary,
			COUNT(ROUND(Net_Pay/Tenure_in_org_in_months)) OVER (PARTITION BY Department ) AS tot_no_of_staff
	FROM employee_info e 
	JOIN salary s ON e.ID = s.EmpID
	JOIN division v ON s.Division_ID = v.Division_ID
	JOIN departments d ON v.Dept_ID = d.Dept_ID
    ) AS avg_dept
WHERE Net_monthly_pay > avg_dept_salary
GROUP BY Department, tot_no_of_staff
ORDER BY tot_no_of_staff DESC;
-- _____________________________________________________________

-- Method 2:
WITH monthly_net_salary AS (SELECT 	s.EmpID, v.Division_ID, d.Department,
									ROUND(s.Net_pay / s.Tenure_in_org_in_months) AS monthly_net_pay	
							FROM salary s
							JOIN division v ON s.Division_ID = v.Division_ID
							JOIN departments d ON v.Dept_ID = d.Dept_ID ),
                            
							
		avg_dept_salary AS (SELECT 	Department, 
									AVG(monthly_net_pay) AS avg_net_salary
							FROM monthly_net_salary
							GROUP BY Department ),

	above_avg_employees AS (SELECT mns.Department								
							FROM monthly_net_salary mns
							JOIN avg_dept_salary ads ON mns.Department = ads.Department
							WHERE mns.monthly_net_pay > ads.avg_net_salary ),
							
dept_population AS (SELECT Department, COUNT(*) AS Total_employees
					FROM monthly_net_salary
                    GROUP BY Department )
                    
SELECT 	aa.Department, Total_employees,
		COUNT(*) AS staff_above_dept_avg_salary,
        CONCAT(ROUND((COUNT(*)/Total_employees) * 100),"%") AS "% above das"
FROM above_avg_employees aa
JOIN dept_population dp ON aa.Department = dp.Department
GROUP BY aa.Department, Total_employees
ORDER BY staff_above_dept_avg_salary;
-- _____________________________________________________________
/*-- Only 2 Departments - Technology (60%),	Legal & Compliance (50%) have more than 40% of staff
	who earn above the departmental average net salary
*/
-- =============================================================

-- vii. Departmental work duration vs average net salary:

SELECT 	Department, Dept_Resumption_Time, Dept_Closing_Time,
		TIMEDIFF(Dept_Closing_Time, Dept_Resumption_Time) AS Work_duration, 
		ROUND(AVG(Gross_Pay/Tenure_in_org_in_months)) AS Avg_Gross_salary, 
		ROUND(AVG(Net_Pay/Tenure_in_org_in_months)) AS Avg_Net_salary
FROM departments d
JOIN division v ON d.Dept_ID = v.Dept_ID
JOIN salary s ON v.Division_ID = s.Division_ID
GROUP BY Department, Dept_Resumption_Time, Dept_Closing_Time
ORDER BY Work_duration DESC;
-- _____________________________________________________________
/* Some departments with shorter work duration earn way more 
than those with longer work duration
*/
-- =============================================================


-- viii. Average Deduction Percentage by Department:

SELECT 	Department, 
		ROUND(AVG(Deduction_percentage),2) AS "Avg_deduction_%"
FROM departments d
JOIN division v ON d.Dept_ID = v.Dept_ID
JOIN salary s ON v.Division_ID = s.Division_ID
GROUP BY Department
ORDER BY `Avg_deduction_%` DESC;
-- _____________________________________________________________

-- ix. Average Deduction Percentage by Role:

SELECT 	Role, 
		ROUND(AVG(Deduction_percentage),2) AS "Avg_deduction_%"
FROM employee_info e
JOIN salary s ON ID = EmpID
GROUP BY Role
ORDER BY `Avg_deduction_%` DESC;
-- _____________________________________________________________

-- x. Heads of Departments remuneration comparison:


SELECT 	Department, HOD_ID, 
		CONCAT(First_Name, ' ', Last_Name) AS HOD,
        ROUND(Net_Pay/Tenure_in_org_in_months) AS HOD_Net_Salary
FROM departments AS d
JOIN employee_info AS e ON ID = HOD_ID
JOIN salary s ON e.ID = s.EmpID;

-- =============================================================


-- =============================================================
-- 5. INSIGHTS
-- =============================================================
/*
-- 1. Gender Inequity: Imbalance in representation (72% male) may raise compliance and equity concerns.
-- 2. Pay Disparity Across Departments: Stark salary differences among departments could trigger talent attrition.
-- 3. Inverted Tenure-Pay Relationship: Highest earners are new hires. 
	Perceived Unfairness in compensation structure could lead to low morale & disengagement.
-- 4. Skewed Analytical Insights: Incorrect compensation records as a result of poor data entry may mislead analysis
	and could as well affect employee trust. 
*/


-- =============================================================
-- 5. RECOMMENDATIONS
-- =============================================================
/*
1. Improve Gender Equity
- Set up gender-balanced hiring targets. Also encourage female leadership development programs.

2. Succession Planning
- Implement succession planning programs for all strategic roles.

3. Review Compensation Strategy
- Standardize compensation bands by department & role to reduce gaps and improve fairness.

4. Employee Retention & Motivation
- Re-evaluate tenure-linked pay: Uplift long-tenured, underpaid employees and 
implement tenure-based raises to incentivize loyalty.

5. Balance Deductions & Transparency
- Simplify compensation structures or increase transparency on deductions (especially for senior roles).
- Communicate benefits clearly to avoid perception of underpayment.

6. Validation of Payroll Records
- Audit payroll data for anomalies and verify against original HR/payroll records.
- Cross-check low-salary entries with tenure and job title logic.
- Ensure all HR/payroll systems have validation checks to prevent unrealistic values.
- Create a data quality assurance process for future reports.

7. Workload & Resource Rebalancing
- Audit work hours across departments and reassign or augment teams facing high workload.
-  Investigate high-hour/low-pay departments (e.g., Finance, HR) for possible automation or 
	support solutions.

*/
-- =============================================================



SELECT * FROM employee_info;
SELECT * FROM salary;
SELECT * FROM departments;
SELECT * FROM division;
SELECT * FROM raw_view;
