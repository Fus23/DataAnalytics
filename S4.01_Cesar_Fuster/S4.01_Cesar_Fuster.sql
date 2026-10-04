-- Nivell 1
-- Exercici 1: Consulta sobre Taula no Optimitzada (Diagnòstic)
SELECT t.*, c.*
FROM `sprint3-analytics-cesar-fuster.sprint3_silver.transactions_clean` AS t
JOIN `sprint3-analytics-cesar-fuster.sprint3_silver.companies_clean` AS c
ON t.business_id = c.company_id
WHERE DATE(t.timestamp) = '2022-03-12'
AND c.country = 'Germany';
-- Dry run: Esta consulta procesará 11.86 MB cuando se ejecute.

-- Se comprueba la cantidad de datos procesados obviando los filtros aplicados:
SELECT t.*, c.*
FROM `sprint3-analytics-cesar-fuster.sprint3_silver.transactions_clean` AS t
JOIN `sprint3-analytics-cesar-fuster.sprint3_silver.companies_clean` AS c
ON t.business_id = c.company_id
WHERE declined = 0;
-- Dry run: Esta consulta procesará 11.86 MB cuando se ejecute.



-- Exercici 2: Re-arquitectura i Optimització de l'Emmagatzematge (Partition & Cluster)
-- Paso 1: Generación de Datos Recientes (Mocking Data)
CREATE OR REPLACE TABLE `sprint3-analytics-cesar-fuster.sprint3_silver.transactions_recent` AS
SELECT * EXCEPT(timestamp),
TIMESTAMP_SUB(
  CURRENT_TIMESTAMP(),
  INTERVAL CAST(RAND() * 50 AS INT64) DAY
) AS timestamp
FROM `sprint3-analytics-cesar-fuster.sprint3_silver.transactions_clean`;

-- Paso 2: Creación de la Tabla Optimitzada (Partitioning & Clustering)
CREATE OR REPLACE TABLE `sprint3-analytics-cesar-fuster.sprint3_gold.fact_transactions_optimized`
PARTITION BY DATE(timestamp)
CLUSTER BY business_id AS
SELECT * FROM `sprint3-analytics-cesar-fuster.sprint3_silver.transactions_recent`;



-- Exercici 3: La Prova del Cotó (Benchmark)
-- Paso 1: Tabla no optimizada:
SELECT * FROM `sprint3-analytics-cesar-fuster.sprint3_silver.transactions_recent`
WHERE timestamp >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 30 DAY);

-- Paso 2: Tabla optimizada:
SELECT * FROM `sprint3-analytics-cesar-fuster.sprint3_gold.fact_transactions_optimized`
WHERE timestamp >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 30 DAY);



-- Exercici 4: Smart Caching (Vistes Materialitzades)
-- Creación de la vista materializada mv_daily_sales:
CREATE OR REPLACE MATERIALIZED VIEW `sprint3-analytics-cesar-fuster.sprint3_gold.mv_daily_sales` AS
SELECT DATE(timestamp) AS sales_date, SUM(amount) AS sales_amount
FROM `sprint3-analytics-cesar-fuster.sprint3_gold.fact_transactions_optimized`
WHERE declined = 0
GROUP BY sales_date;

-- Consulta que muestre la vista creada:
SELECT sales_date, ROUND(sales_amount, 2) AS sales_amount
FROM `sprint3-analytics-cesar-fuster.sprint3_gold.mv_daily_sales`
ORDER BY sales_date;



-- Nivell 2
-- Exercici 1: Perfilat de Clients VIP (Mètriques Agregades amb CTEs)
WITH VIP_Stats AS (
  SELECT user_id, SUM(amount) AS total_amount, COUNT(*) AS transaction_qty,
  ROUND(AVG(amount),2) AS avg_amount, MAX(amount) AS max_amount
  FROM `sprint3-analytics-cesar-fuster.sprint3_gold.fact_transactions_optimized`
  WHERE declined = 0
  GROUP BY user_id
  HAVING SUM(amount) > 500
)

SELECT v.user_id, CONCAT(u.name, ' ', u.surname) AS full_name, u.email, v.transaction_qty, v.avg_amount, v.max_amount, ROUND(v.total_amount,2) AS total_amount
FROM VIP_Stats AS v
JOIN `sprint3-analytics-cesar-fuster.sprint3_silver.users_combined` AS u
ON v.user_id = u.user_id
ORDER BY v.total_amount DESC;



-- Exercici 2: Anàlisi de Tendències (Window Functions sobre Vistes)
SELECT sales_date, ROUND(sales_amount,2) AS sales_today,
ROUND(LAG(sales_amount) OVER(ORDER BY sales_date),2) AS sales_yesterday,
ROUND(SAFE_DIVIDE( sales_amount - LAG(sales_amount) OVER(ORDER BY sales_date), LAG(sales_amount) OVER(ORDER BY sales_date)) * 100,2) AS diff_percentage
FROM `sprint3-analytics-cesar-fuster.sprint3_gold.mv_daily_sales`
ORDER BY sales_date DESC;


-- Exercici 3: Totals Acumulats (Running Totals sobre Vistes)
SELECT sales_date, ROUND(sales_amount,2) AS sales_today,
ROUND(SUM(sales_amount) OVER(
  PARTITION BY EXTRACT(YEAR FROM sales_date)
  ORDER BY sales_date),2) AS sales_ytd 
FROM `sprint3-analytics-cesar-fuster.sprint3_gold.mv_daily_sales`
ORDER BY sales_date DESC;



-- Exercici 4: Fidelització i Valor del Client (Filtratge Avançat)
WITH first_three_purchases AS (
  SELECT user_id, timestamp, amount,
  ROW_NUMBER() OVER(
    PARTITION BY user_id
    ORDER BY timestamp
  ) AS purchase_number
  FROM `sprint3-analytics-cesar-fuster.sprint3_gold.fact_transactions_optimized`
  WHERE declined = 0
  QUALIFY purchase_number <= 3
)

SELECT u.user_id, CONCAT(u.name, ' ', u.surname) AS full_name, u.email, DATE(f.timestamp) AS transaction_date, f.amount,
ROUND(AVG(f.amount) OVER(PARTITION BY f.user_id),2) AS avg_amount_first_three
FROM `sprint3-analytics-cesar-fuster.sprint3_silver.users_combined` AS u
JOIN first_three_purchases AS f
ON u.user_id = f.user_id
QUALIFY f.purchase_number = 3
ORDER BY transaction_date;



-- Nivell 3
-- Exercici 1: Desanidament i Aplanament de Dades (Unnesting)
CREATE OR REPLACE TABLE `sprint3-analytics-cesar-fuster.sprint3_gold.dim_transactions_flat` AS
SELECT t.transaction_id, t.timestamp, t.amount AS total_ticket, product_sku, p.name AS product_name, p.price AS product_price
FROM `sprint3-analytics-cesar-fuster.sprint3_gold.fact_transactions_optimized` AS t
CROSS JOIN UNNEST(t.product_ids) AS product_sku
JOIN `sprint3-analytics-cesar-fuster.sprint3_silver.products_clean` AS p
ON product_sku = p.product_id
WHERE declined = 0;



-- Exercici 2: El Rànquing de Vendes (Agregació Simple)
SELECT product_name, COUNT(*) AS units_sold
FROM `sprint3-analytics-cesar-fuster.sprint3_gold.dim_transactions_flat`
GROUP BY product_name
ORDER BY units_sold DESC
LIMIT 5;



-- Exercici 3: Automatització del Pipeline i Visualització
-- Se crea la función calculate_tax:
CREATE OR REPLACE FUNCTION `sprint3-analytics-cesar-fuster.sprint3_gold.calculate_tax`(amount FLOAT64)
RETURNS FLOAT64 AS (
  amount * 1.21
);

-- Se aplica el cambio en la tabla ya existente dim_transactions_flat:
CREATE OR REPLACE TABLE `sprint3-analytics-cesar-fuster.sprint3_gold.dim_transactions_flat` AS
SELECT t.transaction_id, t.timestamp, t.amount AS total_ticket, product_sku, p.name AS product_name, p.price AS product_price,
ROUND(`sprint3-analytics-cesar-fuster.sprint3_gold.calculate_tax`(p.price),2) AS product_price_tax_inc
FROM `sprint3-analytics-cesar-fuster.sprint3_gold.fact_transactions_optimized` AS t
CROSS JOIN UNNEST(t.product_ids) AS product_sku
JOIN `sprint3-analytics-cesar-fuster.sprint3_silver.products_clean` AS p
ON product_sku = p.product_id
WHERE declined = 0;

-- Link al dashboard final en Looker Studio:
"https://datastudio.google.com/reporting/273209c7-5bdd-479e-a9eb-eb23be593e4d"
