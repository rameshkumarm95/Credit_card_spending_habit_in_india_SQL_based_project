/*
Credit Card Spending Habits in India

Dataset: 

credit_card_transactioins (https://www.kaggle.com/datasets/thedevastator/analyzing-credit-card-spending-habits-in-india)

***About this dataset***

- This dataset contains insights into a collection of credit card transactions made in India, offering a comprehensive look at the spending habits of Indians across the nation. 
- From the Gender and Card type used to carry out each transaction, to which city saw the highest amount of spending and even what kind of expenses were made, this dataset paints an overall picture about how money is being spent in India today. 
- With its variety in variables, researchers have an opportunity to uncover deeper trends in customer spending as well as interesting correlations between data points that can serve as invaluable business intelligence. 
- Whether you're interested in learning more about customer preferences or simply exploring unbiased data analysis techniques, this data is sure to provide insight beyond what one could anticipate

Column Names and their descriptions: 

city		- The city in which the transaction took place. (String)
date		- The date of the transaction. (Date)
card_type	- The type of credit card used for the transaction. (String)
exp_type	- The type of expense associated with the transaction. (String)
gender		- The gender of the cardholder. (String)
amount		- The amount of the transaction. (Number)

*/

USE [SQL_Portfolio_Projects]; --Database

-- Exploring the dataset

-- Viewing all the columns
SELECT * FROM credit_card_transactions; 

-- Totally 26052 transactions
SELECT COUNT(transaction_id) FROM credit_card_transactions;

-- There are 986 cities
SELECT COUNT (DISTINCT city) 
FROM credit_card_transactions; 

-- Transactions happened between 2013-10-04 AND 2015-05-26
SELECT MIN(transaction_date) AS first_date
,MAX(transaction_date) AS end_date FROM credit_card_transactions

-- Card types - Platinum, Gold, Signature, Silver
SELECT DISTINCT card_type FROM credit_card_transactions;

-- Expense types - Entertainment,Food,Bills,Fuel,Travel,Grocery
SELECT exp_type FROM credit_card_transactions GROUP BY exp_type;

-- Genders - Male and Female
SELECT DISTINCT gender FROM credit_card_transactions;


-- 1 write a query to print top 5 cities with highest spends and their percentage contribution of total credit card spends 

-- Query
WITH city_spend AS (
SELECT city, SUM(amount) AS total_spends
FROM credit_card_transactions
GROUP BY city
), total_spend AS (
SELECT SUM(cast(amount AS BIGINT)) AS total_amount 
FROM credit_card_transactions
)
SELECT TOP 5 city_spend.*,
CONCAT(FLOOR(100*((total_spends*1.0)/total_amount)), '%')
AS percentage_contribution FROM 
city_spend, total_spend
ORDER BY city_spend.total_spends DESC;

-- 2. write a query to print highest spend month and amount spent in that month for each card type

-- Query
WITH highest_spend_month AS (
SELECT card_type, YEAR(transaction_date) AS years, 
MONTH(transaction_date) AS months, SUM(amount)
AS total_spent
FROM credit_card_transactions
GROUP BY card_type, YEAR(transaction_date), 
MONTH(transaction_date)
)
SELECT card_type,months,
years, total_spent FROM
(SELECT *, ROW_NUMBER() OVER(PARTITION BY card_type
ORDER BY total_spent DESC) AS rn
FROM highest_spend_month) a
WHERE rn = 1;

-- 3. write a query to print the transaction details(all columns from the table) for each card type when
--(it reaches a cumulative of 1000000 total spends(We should have 4 rows in the o/p one for each card type)


-- Query
WITH transaction_details AS (
SELECT *, SUM(amount) OVER (PARTITION BY card_type ORDER BY
transaction_date,transaction_id) AS total_spend
FROM credit_card_transactions
)
SELECT *
FROM (SELECT *, ROW_NUMBER() OVER (PARTITION BY card_type
ORDER BY total_spend) AS rn 
FROM transaction_details
WHERE total_spend >= 1000000) a
WHERE rn = 1;

-- 4. write a query to find city which had lowest percentage spend for gold card type

-- Query
WITH cities AS (
SELECT city, card_type, SUM(amount) AS total_amount,
SUM(CASE WHEN card_type='Gold' THEN amount ELSE 0 END) AS amount_gold
FROM credit_card_transactions
GROUP BY city, card_type
)
SELECT TOP 1 city,
SUM(amount_gold)*1.0/SUM(total_amount) AS lowest_ratio
FROM cities
GROUP BY city
HAVING SUM(amount_gold) > 0
ORDER BY lowest_ratio ASC;

-- 5. write a query to print 3 columns:  city, highest_expense_type , lowest_expense_type (example format : Delhi , bills, Fuel)

-- Query
WITH city_expense AS (
SELECT city, exp_type,
SUM(amount) AS total_amount
FROM credit_card_transactions 
GROUP BY city,exp_type
)
SELECT city, MIN(CASE WHEN rn_desc=1 THEN exp_type END)
AS highest_expense_type, MAX(CASE WHEN rn_asc=1 THEN exp_type END) 
AS lowest_expense_type
FROM (
SELECT *, 
ROW_NUMBER() 
OVER(PARTITION BY city ORDER BY total_amount DESC) AS rn_desc,
ROW_NUMBER() 
OVER(PARTITION BY city ORDER BY total_amount ASC) AS rn_asc
FROM city_expense
) A 
GROUP BY city;

-- 6. write a query to find percentage contribution of spends by females for each expense type

-- Query
SELECT exp_type
,CONCAT (FLOOR(SUM(CASE WHEN gender='F' THEN amount
ELSE 0 END)*1.0/SUM(amount)*100),'%') AS percentage_contribution_females
FROM credit_card_transactions
GROUP BY exp_type 
ORDER BY percentage_contribution_females DESC;

-- 7. which card and expense type combination saw highest month over month growth in Jan-2014

-- Query
WITH card_expense AS (
SELECT card_type, exp_type, YEAR(transaction_date) AS years,
MONTH(transaction_date) AS months, SUM(amount) AS total_amount
FROM credit_card_transactions
GROUP BY card_type, exp_type, YEAR(transaction_date), MONTH(transaction_date)
), combination AS (
SELECT *, LAG(total_amount) OVER (PARTITION BY
card_type, exp_type ORDER BY years,months) AS prev_amount
FROM card_expense
)
SELECT TOP 1* FROM (SELECT *,((total_amount - prev_amount)*1.0/prev_amount)
AS month_over_month_growth
FROM combination) a
WHERE years = 2014 AND months = '01'
AND prev_amount IS NOT NULL
ORDER BY month_over_month_growth DESC;

-- 8. during weekends which city has highest total spend to total no of transcations ratio 

-- Query
SELECT TOP 1 city,
SUM(amount)/COUNT(*) AS ratio
FROM credit_card_transactions
WHERE DATENAME(WEEKDAY, transaction_date) 
IN ('Saturday','Sunday')
GROUP BY city
ORDER BY ratio DESC;

-- 9. which city took least number of days to reach its 500th transaction after the first transaction in that city

-- Query
WITH total_transactions AS (
SELECT *,
ROW_NUMBER() OVER(PARTITION BY city ORDER BY transaction_date)
AS rn
FROM credit_card_transactions
)
SELECT TOP 1 * FROM (SELECT city, 
DATEDIFF(DAY,MIN(transaction_date),MAX(transaction_date))
AS least_no_of_days
FROM total_transactions
WHERE rn=1 OR rn=500
GROUP BY city) a
WHERE least_no_of_days >0
ORDER BY least_no_of_days ASC;



