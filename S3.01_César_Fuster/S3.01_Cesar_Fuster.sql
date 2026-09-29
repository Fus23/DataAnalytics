-- Nivell 1
-- Exercici 1: Arquitectura de Dades (Lògica vs. Física)

-- Dataset sprint3_bronze, utilizando la UI de BigQuery: 
-- Creada con UI

-- Dataset sprint3_silver, utilizando código SQL (CREATE SCHEMA):
CREATE SCHEMA `sprint3-analytics-cesar-fuster.sprint3_silver`
OPTIONS (location = 'EU');

-- Dataset sprint3_gold, utilizando Cloud Shell (Línea de órdenes bq):
-- Creada con Cloud Shell:
"bq --location=EU mk --dataset sprint3-analytics-cesar-fuster:sprint3_gold"



-- Exercici 2: Ingesta en Capa Bronze (Connexió DDL)
-- Tabla transactions_raw:
CREATE OR REPLACE EXTERNAL TABLE `sprint3-analytics-cesar-fuster.sprint3_bronze.transactions_raw`
OPTIONS (
  format = 'csv',
  uris = ['gs://bootcamp-data-analytics-public/ERP/transactions.csv'],
  field_delimiter = ';'
)

-- Tabla companies_raw:
-- Se usa cloud shell para obtener el nombre de las columnas en el archivo:
"gcloud storage cat gs://bootcamp-data-analytics-public/ERP/companies.csv | head -n 5"

--Resultado de la consulta:
"
company_id,company_name,phone,email,country,website
b-2222,Ac Fermentum Incorporated,06 85 56 52 33,donec.porttitor.tellus@yahoo.net,Germany,https://instagram.com/site
b-2226,Magna A Neque Industries,04 14 44 64 62,risus.donec.nibh@icloud.org,Australia,https://whatsapp.com/group/9
b-2230,Fusce Corp.,08 14 97 58 85,risus@protonmail.edu,United States,https://pinterest.com/sub/cars
b-2234,Convallis In Incorporated,06 66 57 29 50,mauris.ut@aol.couk,Germany,https://cnn.com/user/110
"

-- Una vez se tienen los nombres de las columnas se crea la tabla con SQL:
CREATE OR REPLACE EXTERNAL TABLE
  `sprint3-analytics-cesar-fuster.sprint3_bronze.companies_raw` (
    company_id STRING,
    company_name STRING,
    phone STRING,
    email STRING,
    country STRING,
    website STRING
  )
OPTIONS (
  format = 'CSV',
  uris = ['gs://bootcamp-data-analytics-public/ERP/companies.csv'],
  skip_leading_rows = 1
);

-- Tabla american_users_raw:
CREATE OR REPLACE EXTERNAL TABLE
  `sprint3-analytics-cesar-fuster.sprint3_bronze.american_users_raw`
OPTIONS (
  format = 'CSV',
  uris = ['gs://bootcamp-data-analytics-public/CRM/american_users.csv']
);

-- Tabla european_users_raw:
CREATE OR REPLACE EXTERNAL TABLE
  `sprint3-analytics-cesar-fuster.sprint3_bronze.european_users_raw`
OPTIONS (
  format = 'CSV',
  uris = ['gs://bootcamp-data-analytics-public/CRM/european_users.csv']
);

-- Tabla credit_cards_raw:
CREATE OR REPLACE EXTERNAL TABLE
  `sprint3-analytics-cesar-fuster.sprint3_bronze.credit_cards_raw`
OPTIONS (
  format = 'CSV',
  uris = ['gs://bootcamp-data-analytics-public/CRM/credit_cards.csv']
);



-- Exercici 3: Càrrega de Dades Locals (Upload)
-- Se crea la tabla products manualmente en el dataset sprint3_bronze, utilizando el archivo products.csv del sprint anterior.



-- Exercici 4: Arquitectura i Rendiment. Materialització de Dades (Assistit per IA)
-- a) Código SQL generado por Gemini:
CREATE OR REPLACE TABLE `sprint3-analytics-cesar-fuster.sprint3_bronze.transactions_raw_native` AS
SELECT *
FROM `sprint3-analytics-cesar-fuster.sprint3_bronze.transactions_raw`;

-- b) Comparación de consumo según si la consulta se hace con una tabla externa o nativa
SELECT id
FROM `sprint3-analytics-cesar-fuster.sprint3_bronze.transactions_raw`; -- 12.61MB procesados, 13MB facturados

SELECT id
FROM `sprint3-analytics-cesar-fuster.sprint3_bronze.transactions_raw_native`; -- 3.62MB procesados, 10MB facturados

-- c) Comparación de consumo según si se utiliza LIMIT o no
SELECT id
FROM `sprint3-analytics-cesar-fuster.sprint3_bronze.transactions_raw` -- 1.44KB procesados, 10MB facturados
LIMIT 10;

SELECT id
FROM `sprint3-analytics-cesar-fuster.sprint3_bronze.transactions_raw_native` -- 3.62MB procesados, 10MB facturados
LIMIT 10;



-- Exercici 5: Adaptació de Sintaxi (Reporting)
SELECT DATE(timestamp) AS t_date, ROUND(SUM(amount),2) AS t_amount
FROM `sprint3-analytics-cesar-fuster.sprint3_bronze.transactions_raw`
WHERE EXTRACT(YEAR FROM timestamp) = 2021
AND declined = 0
GROUP BY t_date
ORDER BY t_amount DESC
LIMIT 5;



-- Exercici 6: Consultes Complexes
SELECT c.company_name, c.country, DATE(t.timestamp) AS transaction_date
FROM `sprint3-analytics-cesar-fuster.sprint3_bronze.transactions_raw` AS t
JOIN `sprint3-analytics-cesar-fuster.sprint3_bronze.companies_raw` AS c
ON t.business_id = c.company_id
WHERE t.amount BETWEEN 100 AND 200
AND t.declined = 0
AND DATE(t.timestamp) IN ('2015-04-29','2018-07-20','2024-03-13');



-- Nivell 2
-- Exercici 1: Neteja de Productes (Data Quality)
CREATE OR REPLACE TABLE `sprint3-analytics-cesar-fuster.sprint3_silver.products_clean` AS
SELECT id AS product_id, product_name AS name,
CAST(REPLACE(warehouse_id, 'WH-', '') AS INT64) AS warehouse_id,
CAST(price AS FLOAT64) AS price,
colour AS color,
weight
FROM `sprint3-analytics-cesar-fuster.sprint3_bronze.products_raw`;



-- Exercici 2: Creació de Transaccions Netes (Capa Silver)
CREATE OR REPLACE TABLE `sprint3-analytics-cesar-fuster.sprint3_silver.transactions_clean` AS
SELECT id AS transaction_id,card_id, business_id, timestamp,
IFNULL(SAFE_CAST(amount AS FLOAT64), 0) AS amount, declined,
ARRAY(
  SELECT SAFE_CAST(TRIM(product_id) AS INT64)
  FROM UNNEST(SPLIT(product_ids, ',')) AS product_id
  ) AS product_ids,
user_id, lat, longitude
FROM `sprint3-analytics-cesar-fuster.sprint3_bronze.transactions_raw`;



-- Exercici 3: Unificació d'Usuaris (UNION)
CREATE OR REPLACE TABLE `sprint3-analytics-cesar-fuster.sprint3_silver.users_combined` AS
SELECT id AS user_id, name, surname, phone, email,
birth_date, country, city, postal_code, address, 'USA'AS origin
FROM `sprint3-analytics-cesar-fuster.sprint3_bronze.american_users_raw`
UNION ALL
SELECT id AS user_id, name, surname, phone, email,
birth_date, country, city, postal_code, address, 'Europe'AS origin
FROM `sprint3-analytics-cesar-fuster.sprint3_bronze.european_users_raw`;



-- Exercici 4: Materialització de Companyies i Targetes de Crèdit
-- Creación de la tabla companies_clean:
CREATE OR REPLACE TABLE `sprint3-analytics-cesar-fuster.sprint3_silver.companies_clean` AS
SELECT company_id, company_name, phone, email, country, website
FROM `sprint3-analytics-cesar-fuster.sprint3_bronze.companies_raw`;

-- Creación de la tabla credit_cards_clean:
CREATE OR REPLACE TABLE `sprint3-analytics-cesar-fuster.sprint3_silver.credit_cards_clean` AS
SELECT id AS credit_card_id, user_id, iban, pan, pin, cvv, track1, track2, expiring_date
FROM `sprint3-analytics-cesar-fuster.sprint3_bronze.credit_cards_raw`;



-- Nivell 3
-- Exercici 1: La Vista de Màrqueting (Lògica de Negoci)
-- Creación de la vista v_marketing_kpis:
CREATE OR REPLACE VIEW `sprint3-analytics-cesar-fuster.sprint3_gold.v_marketing_kpis` AS
SELECT c.company_name, c.phone, c.country, AVG(t.amount) AS avg_amount,
CASE WHEN AVG(t.amount) > 260 THEN 'Premium' ELSE 'Standard' END AS client_tier
FROM `sprint3-analytics-cesar-fuster.sprint3_silver.companies_clean` AS c
JOIN `sprint3-analytics-cesar-fuster.sprint3_silver.transactions_clean` AS t
ON c.company_id = t.business_id
WHERE t.declined = 0
GROUP BY c.company_id, c.company_name, c.phone, c.country;

-- Consulta de la vista creada:
SELECT company_name, phone, country, ROUND(avg_amount,2), client_tier
FROM `sprint3-analytics-cesar-fuster.sprint3_gold.v_marketing_kpis`
ORDER BY client_tier DESC, avg_amount DESC;
-- ORDER BY client tier DESC funciona ya que Premium va antes que Standard alfabéticamente



-- Exercici 2: Rànquing de Productes (La Potència dels Arrays)
CREATE OR REPLACE TABLE `sprint3-analytics-cesar-fuster.sprint3_gold.product_sales_ranking` AS
SELECT p.product_id, p.name, p.price, p.color, COUNT(t.product_id) AS total_sold
FROM `sprint3-analytics-cesar-fuster.sprint3_silver.products_clean` AS p
LEFT JOIN (
  SELECT product_id
  FROM `sprint3-analytics-cesar-fuster.sprint3_silver.transactions_clean`,
  UNNEST(product_ids) AS product_id
  WHERE declined = 0
) AS t
ON p.product_id = t.product_id
GROUP BY p.product_id, p.name, p.price, p.color;



-- Exercici 3: Exportació de Resultats
-- Se ejecuta una consulta para mostrar en orden de mayor a menor los productos más vendidos de la tabla product_sales_ranking.
SELECT * FROM `sprint3-analytics-cesar-fuster.sprint3_gold.product_sales_ranking`
ORDER BY total_sold DESC;
-- A continuación se descarga el archivo en formato csv para poder abrirlo como archivo de Excel.