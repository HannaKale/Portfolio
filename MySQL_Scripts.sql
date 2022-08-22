-- Calculate revenue
SELECT sum (meal_price*order_quantity) AS revenue
  FROM meals
  JOIN orders ON meals.meal_id = orders.meal_id
-- Keep only the records of customer ID 15
WHERE user_id = 15;

  -- Calculate cost per meal ID
SELECT
  meals.meal_id,
  SUM (meal_cost*stocked_quantity) AS cost
FROM meals
JOIN stock ON meals.meal_id = stock.meal_id
GROUP BY meals.meal_id
ORDER BY cost DESC
-- Only the top 5 meal IDs by purchase cost
LIMIT 5;

  -- Calculate cost
SELECT
  DATE_TRUNC('month', stocking_date)::DATE AS delivr_month,
  SUM (meal_cost*stocked_quantity) AS cost
FROM meals
JOIN stock ON meals.meal_id = stock.meal_id
GROUP BY delivr_month
ORDER BY delivr_month ASC;

  -- Calculate revenue per eatery
WITH revenue AS (
  SELECT eatery,
         SUM(meal_price*order_quantity) AS revenue
    FROM meals
    JOIN orders ON meals.meal_id = orders.meal_id
   GROUP BY eatery),
  cost AS (
  -- Calculate cost per eatery
  SELECT eatery,
         SUM (meal_cost*stocked_quantity) AS cost
    FROM meals
    JOIN stock ON meals.meal_id = stock.meal_id
   GROUP BY eatery)
   -- Calculate profit per eatery
   SELECT revenue.eatery,
          revenue - cost AS profit
     FROM revenue
     JOIN cost ON revenue.eatery = cost.eatery
    ORDER BY profit DESC;

-- Set up the revenue CTE
WITH revenue AS ( 
	SELECT
		DATE_TRUNC('month', order_date) :: DATE AS delivr_month,
		SUM (meal_price*order_quantity) AS revenue
	FROM meals
	JOIN orders ON meals.meal_id = orders.meal_id
	GROUP BY delivr_month)
-- Set up the cost CTE
  cost AS (
 	SELECT
		DATE_TRUNC('month', stocking_date) :: DATE AS delivr_month,
		SUM (meal_cost*stocked_quantity) AS cost
	FROM meals
    JOIN stock ON meals.meal_id = stock.meal_id
	GROUP BY delivr_month)
-- Calculate profit by joining the CTEs
SELECT
	revenue.delivr_month,
	revenue - cost AS profit
FROM revenue
JOIN cost ON revenue.delivr_month = cost.delivr_month
ORDER BY revenue.delivr_month ASC;

  -- Truncate the order date to the nearest month
SELECT
  DATE_TRUNC ('month', order_date) :: DATE AS delivr_month,
  -- Count the unique user IDs
  COUNT (DISTINCT user_id) AS mau
FROM orders
GROUP BY delivr_month
-- Order by month
ORDER BY delivr_month ASC;

  -- Registrations running total
WITH reg_dates AS (
  SELECT
    user_id,
    MIN(order_date) AS reg_date
  FROM orders
  GROUP BY user_id)

SELECT
  -- Select the month and the registrations
  DATE_TRUNC ('month', reg_date) :: DATE AS delivr_month,
  COUNT (DISTINCT user_id) AS regs
FROM reg_dates
GROUP BY delivr_month
-- Order by month in ascending order
ORDER BY delivr_month; 

  -- MAU monitor
WITH mau AS (
  SELECT
    DATE_TRUNC('month', order_date) :: DATE AS delivr_month,
    COUNT(DISTINCT user_id) AS mau
  FROM orders
  GROUP BY delivr_month),

  mau_with_lag AS (
  SELECT
    delivr_month,
    mau,
    -- Fetch the previous month's MAU
    COALESCE(
      LAG(mau) OVER (ORDER BY delivr_month ASC),
    0) AS last_mau
  FROM mau)

SELECT
  -- Calculate each month's delta of MAUs
  delivr_month,
  ROUND (mau - last_mau, 2) AS mau_delta
FROM mau_with_lag
-- Order by month in ascending order
ORDER BY delivr_month ASC;

  -- Average orders per user
  WITH kpi AS (
  SELECT
    -- Select the count of orders and users
    COUNT (DISTINCT order_id) AS orders,
    COUNT (DISTINCT user_id) AS users
  FROM orders)

SELECT
  -- Calculate the average orders per user
  ROUND ( orders :: NUMERIC / GREATEST (users, 1), 2) AS arpu
FROM kpi;

  -- Histogram of orders
SELECT
  -- Select the user ID and the count of orders
  user_id,
  COUNT (DISTINCT order_id) AS orders
FROM orders
GROUP BY user_id
ORDER BY user_id ASC
LIMIT 5;

  -- Bucketing users by revenue
  WITH user_revenues AS (
  SELECT
    -- Select the user IDs and the revenues they generate
    user_id,
    SUM (meal_price*order_quantity) AS revenue
  FROM meals AS m
  JOIN orders AS o ON m.meal_id = o.meal_id
  GROUP BY user_id)

SELECT
  -- Fill in the bucketing conditions
  CASE
    WHEN revenue < 150  THEN 'Low-revenue users'
    WHEN revenue < 300 THEN 'Mid-revenue users'
    ELSE 'High-revenue users'
  END AS revenue_group,
  COUNT (DISTINCT user_id) AS users
FROM user_revenues
GROUP BY revenue_group;

  -- Revenue quartiles
  WITH user_revenues AS (
  -- Select the user IDs and their revenues
  SELECT
    user_id,
    SUM (meal_price*order_quantity) AS revenue
  FROM meals AS m
  JOIN orders AS o ON m.meal_id = o.meal_id
  GROUP BY user_id)

SELECT
  -- Calculate the first, second, and third quartile
  ROUND( PERCENTILE_CONT (0.25) WITHIN GROUP (ORDER BY revenue ASC):: NUMERIC, 2) AS revenue_p25,
  ROUND( PERCENTILE_CONT (0.50) WITHiN GROUP (ORDER BY revenue ASC):: NUMERIC, 2) AS revenue_p50,
  ROUND( PERCENTILE_CONT (0.75) WITHIN GROUP (ORDER BY revenue ASC):: NUMERIC, 2) AS revenue_p75,
  -- Calculate the average
  ROUND(AVG (revenue) :: NUMERIC, 2) AS avg_revenue
FROM user_revenues;

  -- Interquartile range
  SELECT
  -- Select user_id and calculate revenue by user
  user_id,
  SUM (meal_price*order_quantity) AS revenue
FROM meals AS m
JOIN orders AS o ON m.meal_id = o.meal_id
GROUP BY user_id;