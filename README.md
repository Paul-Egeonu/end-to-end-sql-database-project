
![6470813](https://github.com/user-attachments/assets/64d02023-f727-45f5-865a-fdac1c71ce4a)

# 🏢 Max Holdings — Full SQL Project  

![SQL](https://img.shields.io/badge/SQL-MySQL-blue)  
![Database](https://img.shields.io/badge/Database-MySQL-orange)  
![Status](https://img.shields.io/badge/Project-Complete-brightgreen)  

---

## 📘 Project Overview  

This project demonstrates advanced **SQL (MySQL)** techniques for end-to-end data management and analytics on **HR and payroll data** from **Max Holdings**.  

It covers:  
- 🧱 Database creation and schema design  
- 🧹 Data cleaning and transformation  
- 🧩 CTEs, Window Functions, and Views  
- 📈 Business insights and analytics  

The goal is to showcase both **technical SQL proficiency** and **strategic business thinking** through actionable insights.  

---

## 📂 Project Structure  

```plaintext
Max_Holdings_SQL_Project/
│── Max_Holdings_full_project.sql    # Main SQL script (original)
│── README.md                        # Documentation (this file)
│── Max_Holdings_ERD.png             # Entity Relationship Diagram
│── data/
│   ├── employee_info.csv
│   ├── salary.csv
│   ├── departments.csv
│   └── division.csv
```

---

## 🧭 Database Schema  

The database contains four key tables:  

| Table | Description |
|:------|:-------------|
| **employee_info** | Employee demographics, IDs, and roles |
| **salary** | Payroll details (gross, net, deductions, tenure) |
| **departments** | Department info (HOD, resumption/closing times) |
| **division** | Business divisions linked to departments |

📊 **Entity Relationship Diagram (ERD)**  

Below is the visual schema representation:  


<img width="2047" height="582" alt="Max_Holdings_ERD" src="https://github.com/user-attachments/assets/484d1e32-4f8a-4c5b-b72a-d54ae0b5f836" />

---

## 🛠 SQL Expertise Demonstrated  

This project showcases a wide range of SQL capabilities:  

✅ Database setup & normalization  
✅ Data cleaning: handling duplicates, nulls, and incorrect types  
✅ Data transformation using analytic views  
✅ Modular analysis with CTEs  
✅ Advanced analytics with Window Functions (ROW_NUMBER, RANK, DENSE_RANK)  
✅ Aggregations & joins for performance insights  

---

## 🔍 Highlighted Queries & Insights  

### 1️⃣ Duplicate Records Detection & Deletion with CTE + Window Function  

```sql
WITH Duplicate_emp AS (
						SELECT 	emp_unique_id,
								ROW_NUMBER() OVER (PARTITION BY ID ORDER BY emp_unique_id) AS entry_no
						FROM employee_info)
                        
DELETE FROM employee_info
WHERE emp_unique_id IN (
						SELECT emp_unique_id 
                        FROM Duplicate_emp WHERE entry_no > 1);
```

**Insight:**  
Duplicate employee entries were detected and removed to ensure data integrity.  

---

### 2️⃣ Gender Balance Analysis  

```sql
SELECT 	Gender, COUNT(*) AS Total_Employees, 
		CONCAT(ROUND(COUNT(*)/1802 * 100), '%') AS "%"
FROM employee_info
GROUP BY Gender;
```

**Insight:**  
Workforce distribution shows **72% Male** vs **28% Female**, indicating a gender imbalance.  

---

### 3️⃣ Salary Disparities Across Departments  

```sql
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
```

**Insight:**  
| Department | Avg. Net Salary ($) | Observation |
|-------------|----------------------|--------------|
| Legal & Compliance | $11,287 | 💰 Highest |
| Finance | $2,500 | ⚠️ Lowest |  
Significant pay gaps across departments highlight internal inequality.  

---

### 4️⃣ Tenure vs Salary Correlation  

```sql
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
```

**Insight:**  
Short-tenured employees earn disproportionately high salaries — possibly due to executive hires or pay misalignment.  

---

### 5️⃣ Age Distribution of Workforce  

```sql
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
```

**Insight:**  
The majority of employees are **26–35 years old**, confirming a young, mid-career workforce.  

---

## 📈 Key Business Insights  

| # | Insight |
|:-:|:--------|
| 1 | Workforce is young (avg ~32 years) but **gender-imbalanced** (72% male). |
| 2 | **Salary disparities** exist across departments. |
| 3 | **Succession risk** due to aging leaders in key roles. |
| 4 | **Tenure-pay inversion** – new hires earn more than long-tenured staff. |
| 5 | **Payroll anomalies** suggest data entry or structural inconsistencies. |

---

## 🚀 Business Recommendations  

1. 👩‍💼 **Gender Equity** → Implement targeted female hiring and mentorship programs.  
2. 👨‍🏫 **Succession Planning** → Groom younger employees for leadership roles.  
3. 💵 **Compensation Review** → Standardize pay bands to address disparities.  
4. 🔄 **Retention Strategy** → Introduce bonuses and recognition for tenure.  
5. 🧹 **Data Quality Improvements** → Deploy validation checks on payroll data.  

---

## 🧾 Tools & Technologies  

| Category | Tools |
|-----------|-------|
| Database | MySQL |
| Language | SQL |
| Visualization | ERD (draw.io / dbdiagram.io) |
| Data Source | CSV (Employee, Salary, Departments, Division) |

---

## 🏆 Author  

**Paul Egeonu**  
_Data Analyst | Data Scientist_  
 

---

### ⭐ How to Use  

1. Import the `.sql` file into your MySQL environment.  
2. Load the CSV files into corresponding tables.  
3. Run the queries to reproduce the results and insights.  
4. Review the ERD for schema understanding.  

---

### 📌 Status: **Complete**  
This project demonstrates strong SQL fundamentals, business acumen, and analytical storytelling.  
