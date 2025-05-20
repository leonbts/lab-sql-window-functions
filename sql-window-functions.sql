-- Challenge 1
-- 1. Rank films by their length
SELECT 
  title, 
  length, 
  RANK() OVER (ORDER BY length DESC) AS 'rank'
FROM film
WHERE length IS NOT NULL AND length > 0;

-- 2. Rank films by length within each rating category
SELECT 
  title, 
  length, 
  rating,
  RANK() OVER (PARTITION BY rating ORDER BY length DESC) AS 'rank'
FROM film
WHERE length IS NOT NULL AND length > 0;

-- 3. Show the actor/actress who acted in the most films and list all their films
WITH actor_film_counts AS (
  SELECT 
    fa.actor_id,
    a.first_name,
    a.last_name,
    COUNT(fa.film_id) AS film_count
  FROM film_actor fa
  JOIN actor a ON fa.actor_id = a.actor_id
  GROUP BY fa.actor_id, a.first_name, a.last_name
),
most_prolific_actor AS (
  SELECT *
  FROM actor_film_counts
  ORDER BY film_count DESC
  LIMIT 1
)
SELECT 
  f.title AS film_title,
  mpa.first_name,
  mpa.last_name,
  mpa.film_count
FROM most_prolific_actor mpa
JOIN film_actor fa ON mpa.actor_id = fa.actor_id
JOIN film f ON fa.film_id = f.film_id;


-- Challenge 2
-- 1. Monthly Active Customers
WITH monthly_active_customers AS (
  SELECT 
    DATE_FORMAT(rental_date, '%Y-%m') AS rental_month,
    customer_id
  FROM rental
  GROUP BY rental_month, customer_id
),
monthly_counts AS (
  SELECT 
    rental_month,
    COUNT(DISTINCT customer_id) AS active_customers
  FROM monthly_active_customers
  GROUP BY rental_month
)
SELECT * FROM monthly_counts;

-- 2. Add Previous Month’s Customer Count
WITH monthly_active_customers AS (
  SELECT 
    DATE_FORMAT(rental_date, '%Y-%m') AS rental_month,
    customer_id
  FROM rental
  GROUP BY rental_month, customer_id
),
monthly_counts AS (
  SELECT 
    rental_month,
    COUNT(DISTINCT customer_id) AS active_customers
  FROM monthly_active_customers
  GROUP BY rental_month
),
monthly_with_lag AS (
  SELECT 
    rental_month,
    active_customers,
    LAG(active_customers) OVER (ORDER BY rental_month) AS previous_active_customers
  FROM monthly_counts
)
SELECT * FROM monthly_with_lag;

-- 3. Percentage Change in Active Customers
WITH monthly_active_customers AS (
  SELECT 
    DATE_FORMAT(rental_date, '%Y-%m') AS rental_month,
    customer_id
  FROM rental
  GROUP BY rental_month, customer_id
),
monthly_counts AS (
  SELECT 
    rental_month,
    COUNT(DISTINCT customer_id) AS active_customers
  FROM monthly_active_customers
  GROUP BY rental_month
),
monthly_with_lag AS (
  SELECT 
    rental_month,
    active_customers,
    LAG(active_customers) OVER (ORDER BY rental_month) AS previous_active_customers
  FROM monthly_counts
)
SELECT 
  rental_month,
  active_customers,
  previous_active_customers,
  ROUND(
    IF(previous_active_customers IS NULL, NULL,
      (active_customers - previous_active_customers) / previous_active_customers * 100
    ), 2
  ) AS pct_change
FROM monthly_with_lag;

-- 4. Retained Customers
WITH monthly_customers AS (
  SELECT 
    DATE_FORMAT(rental_date, '%Y-%m-01') AS rental_month,
    customer_id
  FROM rental
  GROUP BY rental_month, customer_id
),
retention AS (
  SELECT 
    this_month.rental_month AS current_month,
    COUNT(DISTINCT this_month.customer_id) AS retained_customers
  FROM monthly_customers this_month
  JOIN monthly_customers prev_month
    ON this_month.customer_id = prev_month.customer_id
    AND this_month.rental_month = DATE_FORMAT(DATE_ADD(prev_month.rental_month, INTERVAL 1 MONTH), '%Y-%m-01')
  GROUP BY this_month.rental_month
)
SELECT * FROM retention
ORDER BY current_month;