# 🛒 Ecommerce Exploratory Data Analysis (EDA) with SQL

##  Project Overview

This project focuses on performing **Exploratory Data Analysis (EDA)** on an Ecommerce dataset using **SQL Server**. The goal is to uncover valuable business insights related to revenue trends, user behavior, product performance, discount effectiveness, and category-based patterns. The analysis leverages SQL techniques such as window functions, common table expressions (CTEs), aggregation, and ranking to answer critical business questions.

---
## Data Source

kaggle

##  Dataset Overview

The dataset used for this project includes records from an Ecommerce platform and contains the following columns (among others):

- `User_ID`
- `Product_ID`
- `Category`
- `Price`
- `Final_Price`
- `Discount (%)` *(renamed to `Discount`)*
- `Purchase_Date`
- `Payment_Method`

The dataset was cleaned and normalized (e.g., renaming columns, correcting data types) before analysis.

---

## ❓ Key Exploratory Questions Answered

- Who are the **top 5 spending users** each month?
- What is the **rank of each product** by total revenue within its category?
- What is the **month-over-month running total** of revenue?
- What is each user's **first and last purchase date**?
- What is the **average discount per user** compared to the overall average?
- Which purchases have a **discount above the category average**?
- Which users have purchased across **multiple categories**?
- Which products show a **decreasing average price trend** over time?
- What **payment methods consistently outperform** the monthly revenue average?
- Who are the **top 10% users by discount received**?
- What is the **month-over-month growth rate** in revenue?
- Which **day of the week generates the highest revenue**?
- What are the **categories with the highest price margins**?
- What is the **discount effectiveness ratio** per product?
- What is the **Lifetime Value (LTV)** of each user?
- What are the **top 3 categories by revenue** in each month?

---

##  SQL Concepts & Techniques Used

- **Window Functions:** `RANK()`, `LAG()`, `PERCENT_RANK()`
- **CTEs (Common Table Expressions):** For clean, modular queries
- **Aggregate Functions:** `SUM()`, `AVG()`, `MIN()`, `MAX()`
- **Filtering and Joins:** `HAVING`, `JOIN`, `WHERE`
- **Date Functions:** `DATETRUNC()`, `DATENAME()`, `GETDATE()`, `DATEADD()`
- **Data Cleaning:** Column renaming and datatype normalization
- **Subqueries and Nested Queries**

---

## Tools & Tech

- **SQL Server** (SSMS)
- **T-SQL** (Transact-SQL)
- GitHub for version control and documentation

---

##  Sample Query Snippet

```sql
-- Who are the top 5 spending users each month?
WITH MonthlySpending AS (
  SELECT 
    SUM(final_price) AS TotalSpent, 
    USER_ID, 
    MONTH
  FROM Ecommerce
  GROUP BY MONTH, User_ID
),
SpendingRank AS (
  SELECT *, 
    RANK() OVER (PARTITION BY MONTH ORDER BY TotalSpent DESC) AS Rank
  FROM MonthlySpending
)
SELECT * 
FROM SpendingRank
WHERE Rank <= 5;
