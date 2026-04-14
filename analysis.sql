-- =====================================
-- E-commerce Data Analysis
-- =====================================

-- 1. Cancellation Rate
-- -------------------------------------

SELECT
    COUNT(DISTINCT InvoiceNo) AS total_orders,
    COUNT(DISTINCT CASE WHEN InvoiceNo LIKE 'C%' THEN InvoiceNo END) AS cancelled_orders
FROM online_retail;



-- 2. Completed Revenue
-- -------------------------------------

SELECT SUM(Quantity * UnitPrice) AS completed
FROM online_retail
WHERE InvoiceNo NOT LIKE 'C%'
AND Quantity > 0;



-- 3. Revenue Breakdown
-- -------------------------------------

SELECT 
    SUM(Quantity * UnitPrice) AS gross_revenue,
    SUM(CASE 
        WHEN Quantity < 0 THEN Quantity * UnitPrice 
        ELSE 0 
    END) AS negative_impact
FROM online_retail;



-- 4. Unique Customers
-- -------------------------------------

SELECT COUNT(DISTINCT CustomerID) FROM online_retail;



-- 5. Top Products
-- -------------------------------------

SELECT Description, SUM(Quantity) AS total_sold
FROM online_retail
GROUP BY Description
ORDER BY total_sold DESC
LIMIT 10;



-- 6. Monthly Revenue
-- -------------------------------------

SELECT DATE_TRUNC('month', InvoiceDate::timestamp) AS month,
       SUM(Quantity * UnitPrice) AS revenue
FROM online_retail
WHERE Quantity > 0
GROUP BY month
ORDER BY month;



-- 7. RFM Segmentation
-- -------------------------------------

WITH rfm AS (
    SELECT 
        CustomerID,
        DATE_PART('day', CURRENT_DATE - MAX(InvoiceDate::timestamp)) AS recency,
        COUNT(DISTINCT InvoiceNo) AS frequency,
        SUM(Quantity * UnitPrice) AS monetary
    FROM online_retail
    WHERE CustomerID IS NOT NULL
    AND CustomerID <> ''
    AND CustomerID <> 'NULL'
    AND Quantity > 0
    GROUP BY CustomerID
),
scored AS (
    SELECT *,
        NTILE(5) OVER (ORDER BY recency DESC) AS r_score,
        NTILE(5) OVER (ORDER BY frequency) AS f_score,
        NTILE(5) OVER (ORDER BY monetary) AS m_score
    FROM rfm
),
segmented AS (
    SELECT *,
        CASE 
            WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4 THEN 'Champions'
            WHEN r_score >= 3 AND f_score >= 3 THEN 'Loyal'
            WHEN r_score >= 4 AND f_score <= 2 THEN 'New Customers'
            WHEN r_score <= 2 AND f_score >= 3 THEN 'At Risk'
            WHEN r_score <= 2 AND f_score <= 2 THEN 'Lost'
            ELSE 'Potential'
        END AS segment
    FROM scored
)

SELECT segment, COUNT(*) AS num_customers
FROM segmented
GROUP BY segment
ORDER BY num_customers DESC;



-- 8. Revenue per Segment
-- -------------------------------------

WITH rfm AS (
    SELECT 
        CustomerID,
        DATE_PART('day', CURRENT_DATE - MAX(InvoiceDate::timestamp)) AS recency,
        COUNT(DISTINCT InvoiceNo) AS frequency,
        SUM(Quantity * UnitPrice) AS monetary
    FROM online_retail
    WHERE CustomerID IS NOT NULL
    AND CustomerID <> ''
    AND CustomerID <> 'NULL'
    AND Quantity > 0
    GROUP BY CustomerID
),
scored AS (
    SELECT *,
        NTILE(5) OVER (ORDER BY recency DESC) AS r_score,
        NTILE(5) OVER (ORDER BY frequency) AS f_score,
        NTILE(5) OVER (ORDER BY monetary) AS m_score
    FROM rfm
),
segmented AS (
    SELECT *,
        CASE 
            WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4 THEN 'Champions'
            WHEN r_score >= 3 AND f_score >= 3 THEN 'Loyal'
            WHEN r_score >= 4 AND f_score <= 2 THEN 'New Customers'
            WHEN r_score <= 2 AND f_score >= 3 THEN 'At Risk'
            WHEN r_score <= 2 AND f_score <= 2 THEN 'Lost'
            ELSE 'Potential'
        END AS segment
    FROM scored
)

SELECT 
    segment,
    COUNT(*) AS num_customers,
    ROUND(SUM(monetary), 2) AS total_revenue,
    ROUND(AVG(monetary), 2) AS avg_customer_value
FROM segmented
GROUP BY segment
ORDER BY total_revenue DESC;
