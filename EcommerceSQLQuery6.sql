select * from Ecommerce

--Renaming column
Exec sp_rename 'dbo.Ecommerce.[Discount (%)]','Discount','COLUMN';

--Getting all column names
SELECT COLUMN_NAME
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'ecommerce';

-- normalizing the datatype
alter table Ecommerce
alter column purchase_date date

-- normalizing the datatype
alter table Ecommerce
alter column discount int

--EXPLORATORY DATA ANALYSIS
--Who are the top 5 spending users each month based on total Final_Price?
WITH MonthlySpending AS (
         SELECT sum(final_price) as TotalSpent, 
               USER_ID, 
                month
        FROM Ecommerce
        GROUP BY month, User_ID
	),
  SpendingRank AS (
       SELECT *, 
          RANK() over (partition by month order by totalspent desc) as rank
       FROM Monthlyspending
	)
SELECT * 
FROM SpendingRank
WHERE rank<=5


--What is the rank of each product by total revenue within its category?
WITH cte_product as (
     SELECT 
        Product_id, 
		category, 
		sum(final_price) as Revenue
     FROM Ecommerce
     GROUP BY Product_id, category)
 SELECT *, 
    RANK() OVER(PARTITION  BY category order by revenue) as r
 FROM cte_product


 --What is the running total of revenue month over month?
  WITH cte_revenue AS (
     SELECT datetrunc(month, Purchase_Date) AS Month, 
	       SUM(final_price) as revenue
     FROM Ecommerce
     GROUP BY datetrunc(month, Purchase_Date))
  SELECT *,
      sum(revenue) OVER(ORDER BY month) as Running_Total
  FROM cte_revenue

--For each user, what was their first and last purchase date?
SELECT USER_ID,
       MIN(purchase_date) AS first_purchase_date,
       MAX(purchase_date) AS last_purchase_date
FROM Ecommerce
GROUP BY User_ID

--What is the average discount per user compared to the average discount overall?
SELECT User_ID, 
       AVG(discount) as AvgDiscount, 
	   (select AVG(discount) from Ecommerce) as overallAverage
FROM Ecommerce
GROUP BY User_ID

-- Find the category-wise average discount, then return all purchases where the discount is above the category average
WITH CategoryAvg AS (
  SELECT Category, AVG(Discount) AS Avg_Discount
  FROM Ecommerce
  GROUP BY Category
)
SELECT e.*
FROM Ecommerce e
JOIN CategoryAvg c ON e.Category = c.Category
WHERE e.Discount > c.Avg_Discount;

--identify users with purchases in more than one category.
SELECT User_id, count(distinct Category) AS NumOfPurchases
FROM Ecommerce
GROUP BY User_ID
HAVING count(distinct Category)>1

--find products with a decreasing trend in average Final_Price month-over-month
WITH MonthlyAvg AS (
     SELECT datetrunc(month, Purchase_Date) AS Month, 
	        Product_id,
	        AVG(final_price) as AvgPrice
     FROM Ecommerce
     GROUP BY datetrunc(month, Purchase_Date),  Product_id
	 ),
Prev_month AS ( 
   SELECT *, 
        LAG(AvgPrice) OVER(PARTITION BY product_id ORDER BY Month) as PrevAvg
	FROM MonthlyAvg 
	)
SELECT *
FROM Prev_month
WHERE PrevAvg>AvgPrice
  
--Identify payment methods with revenue consistently above the monthly average over the last 3 months.
WITH MonthlyRevenue AS (
    SELECT datetrunc(month, purchase_date) as month, payment_method, sum(final_price) AS Revenue
    FROM Ecommerce
    WHERE Purchase_Date >= DATEADD(MONTH, -3, GETDATE())
    GROUP BY datetrunc(month, purchase_date), payment_method),
MonthlyAverage AS (SELECT month, avg(Revenue) AS AvgRevenue
    FROM MonthlyRevenue
    GROUP BY month)
SELECT m.*
FROM MonthlyRevenue m
JOIN MonthlyAverage ma ON m.month = ma.month
WHERE m.revenue > ma.AvgRevenue

--Find the users whose average discount percentage is in the top 10% of all users
WITH AverageDiscount AS (
	SELECT user_id,
	       avg(discount) AS AvgDiscount
    FROM Ecommerce
    GROUP BY User_ID
),
DiscountRank AS (SELECT *,
        PERCENT_RANK() OVER (ORDER BY AvgDiscount DESC) AS r
  FROM AverageDiscount)
SELECT *
FROM DiscountRank
WHERE r<=0.1

--What is the month-over-month growth rate in total revenue?
WITH MonthlyRevenue AS (
		SELECT DATETRUNC(month, purchase_date) AS Month,
	           SUM(final_price) AS Revenue
        FROM Ecommerce
        GROUP BY DATETRUNC(month, purchase_date)
),
PreviousRevenue AS (
SELECT *,
      LAG(Revenue) OVER(ORDER BY Month) AS prevRev
FROM MonthlyRevenue
)
SELECT *, 
      (Revenue - PrevRev)*100 /PrevRev AS MoMGrowth
FROM PreviousRevenue

--What day of the week generates the highest average Final_Price?
SELECT DATENAME(weekday, purchase_date) AS Weekday, sum(final_price) AS Revenue
FROM Ecommerce
GROUP BY DATENAME(weekday, purchase_date)
ORDER BY Revenue DESC

--Compare the average Price and Final_Price per category and return the categories with the highest margin.
SELECT category, CAST(AVG(price - final_price) AS Decimal(5,2)) as Margin
FROM Ecommerce
GROUP BY Category
ORDER BY Margin Desc

--What is the discount effectiveness ratio (discount % vs. actual price reduction) per product?
SELECT 
  Product_ID,
  CAST(AVG((Price - Final_Price) / NULLIF(Price, 0)) * 100 AS Decimal(5,2)) AS EffectivenessPct
FROM Ecommerce
GROUP BY Product_ID

--What is the user lifetime value (LTV) for each user (sum of their total purchases)?
SELECT user_id, sum(final_price) AS Revenue
FROM Ecommerce
GROUP BY user_id

--Identify the top 3 categories by revenue in each month.
WITH CategoryRev AS (
  SELECT 
    category,
    DATETRUNC(Month, purchase_date) AS Month,
    SUM(final_price) AS Revenue,
    RANK() OVER (
      PARTITION BY DATETRUNC(Month, purchase_date) 
      ORDER BY SUM(final_price) DESC
    ) AS r
  FROM Ecommerce
  GROUP BY category, DATETRUNC(Month, purchase_date)
)
SELECT *
FROM CategoryRev
WHERE r <= 3


