/* RFM Analysis */
-- Objective: Calculating RFM score and segmenting customers based on the scores.

-- 1. Calculate RFM values
WITH customer_rfm as(
	SELECT
		customer_id,
		CURRENT_DATE - MAX(order_date) as recency,
		COUNT(DISTINCT order_id) as frequency,
		SUM(payment_value) as monetary
	FROM
		public.transaction
	GROUP BY
		customer_id
),

-- 2. RFM scoring
rfm_scores AS (
    SELECT
        customer_id,
        recency,
        frequency,
        monetary,
		-- Recency Score: Lower rencency = Higher score
        CASE
            WHEN recency IS NULL THEN 1
            ELSE (6 - NTILE(5) OVER (ORDER BY recency ASC))
        END AS R_Score,
		
        -- Frequency Score: Higher score for higher Frequency
        NTILE(5) OVER (ORDER BY Frequency DESC) AS F_Score,
		
        -- Monetary Score: Higher score for higher Monetary value
        NTILE(5) OVER (ORDER BY Monetary DESC) AS M_Score
    FROM
        customer_rfm
),

-- 3. Customer Segmentation
rfm_segments AS (
    SELECT
        customer_id,
        recency,
        frequency,
        monetary,
        R_Score,
        F_Score,
        M_Score,
		-- Combine scores
        CAST(R_Score AS TEXT) || CAST(F_Score AS TEXT) || CAST(M_Score AS TEXT) AS RFM_Score,
        
		-- Assign customer segments based on RFM score combinations
        CASE
            WHEN R_Score >= 4 AND F_Score >= 4 AND M_Score >= 4 THEN 'Champions'
            WHEN R_Score >= 3 AND F_Score >= 4 AND M_Score >= 3 THEN 'Loyal'
            WHEN R_Score >= 4 AND F_Score >= 2 AND M_Score >= 2 THEN 'Potential'
            WHEN R_Score <= 2 AND (F_Score >= 3 OR M_Score >= 3) THEN 'At Risk'
            WHEN R_Score <= 3 AND F_Score <= 3 AND M_Score <= 3 THEN 'Hibernating'
            WHEN R_Score <= 1 AND F_Score <= 1 AND M_Score <= 1 THEN 'Lost'
            ELSE 'Other' 
        END AS RFM_Segment
    FROM
        rfm_scores
)

-- 4. Final table
SELECT
    customer_id,
    recency,
    frequency,
    monetary,
    R_Score,
    F_Score,
    M_Score,
	RFM_score,
    RFM_Segment
FROM
    rfm_segments
ORDER BY
    RFM_Score DESC;


/* Monthly Repeat Purchases */
-- Objective: Find customers with more than 1 transaction in a month

EXPLAIN
-- 1. Orders per month
WITH monthly_orders AS (
  SELECT
    customer_id,
    EXTRACT(MONTH FROM order_date) AS order_month,
    COUNT(order_id) AS orders_per_month
  FROM public.transaction
  GROUP BY customer_id, order_month
),

repeat_purchases AS (
-- 2. Filter orders where orders per month is at least 2
  SELECT *
  FROM monthly_orders
  WHERE orders_per_month >= 2
)

-- 3. Customers with orders >=2 in a month (Final table)
SELECT
  order_month,
  COUNT(DISTINCT customer_id) AS repeat_customers
FROM repeat_purchases
GROUP BY order_month
ORDER BY order_month;

