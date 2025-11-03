
-- BANCO DE DADOS: Google BigQuery Standard SQL
-- MODELAGEM TRANSACIONAL NORMALIZADA NF3

-- SCHEMA (DDL) - CRIAÇÃO DAS TABELAS TRANSACIONAIS

-- Tabela de Clientes
CREATE TABLE seu_dataset.customers (
    customer_id INT64 NOT NULL, -- PRIMARY KEY (não imposto)
    name STRING,
    email STRING,
    city STRING,
    created_at DATE
);

-- Tabela de Produtos   
CREATE TABLE seu_dataset.products (
    product_id INT64 NOT NULL, -- PRIMARY KEY (não imposto)
    name STRING,
    category STRING,
    price NUMERIC -- Equivalente ao DECIMAL(10, 2)
);

-- Tabela de Pedidos
CREATE TABLE seu_dataset.orders (
    order_id INT64 NOT NULL,
    customer_id INT64,
    product_id INT64,
    quantity INT64,
    order_date DATE
);

-- CARGA DE DADOS NAS TABELAS TRANSACIONAIS

-- GERAR PRODUTOS
INSERT INTO seu_dataset.products (product_id, name, category, price)
SELECT
    id,
    CONCAT('Produto ', CAST(id AS STRING)) AS name,
    CASE
        WHEN MOD(id, 5) = 0 THEN 'Eletrônicos'
        WHEN MOD(id, 5) = 1 THEN 'Roupas'
        WHEN MOD(id, 5) = 2 THEN 'Casa'
        WHEN MOD(id, 5) = 3 THEN 'Alimentos'
        ELSE 'Esportes'
    END AS category,

    -- Gera preços aleatórios baseados na categoria
    ROUND(
        CAST(
            CASE
                WHEN MOD(id, 5) = 0 THEN RAND() * (3000 - 500) + 500    -- Eletrônicos (500-3000)
                WHEN MOD(id, 5) = 1 THEN RAND() * (300 - 50) + 50       -- Roupas (50-300)
                WHEN MOD(id, 5) = 2 THEN RAND() * (1000 - 100) + 100    -- Casa (100-1000)
                WHEN MOD(id, 5) = 3 THEN RAND() * (50 - 5) + 5          -- Alimentos (5-50)
                ELSE RAND() * (700 - 80) + 80                           -- Esportes (80-700)
            END
        AS NUMERIC),
    2) AS price
FROM UNNEST(GENERATE_ARRAY(1, 200)) AS id;

-- GERAR CLIENTES
INSERT INTO seu_dataset.customers (customer_id, name, email, city, created_at)
SELECT
    id,
    CONCAT('Cliente ', CAST(id AS STRING)) AS name,
    CONCAT('cliente', CAST(id AS STRING), '@example.com') AS email,
    (
        SELECT CASE
            WHEN r < 0.4 THEN 'São Paulo'       -- 40% dos clientes
            WHEN r < 0.65 THEN 'Rio de Janeiro' -- 25% dos clientes
            WHEN r < 0.8 THEN 'Belo Horizonte'  -- 15% dos clientes
            WHEN r < 0.9 THEN 'Curitiba'        -- 10% dos clientes
            ELSE 'Outra'                        -- 10% dos clientes
        END
        FROM (SELECT RAND() AS r) AS sub
    ) AS city,
    DATE_SUB(CURRENT_DATE(), INTERVAL CAST(FLOOR(RAND() * (365 * 2)) AS INT64) DAY) AS created_at
FROM UNNEST(GENERATE_ARRAY(1, 10000)) AS id;


-- GERAR PEDIDOS
INSERT INTO seu_dataset.orders (order_id, customer_id, product_id, quantity, order_date)
SELECT
    id,
    CAST(FLOOR(RAND() * (10000 - 1) + 1) AS INT64) AS customer_id,  -- ID aleatório de cliente (1 a 10000)
    CAST(FLOOR(RAND() * (200 - 1) + 1) AS INT64) AS product_id,     -- ID aleatório de produto (1 a 200)
    CAST(FLOOR(RAND() * 30 + 1) AS INT64) AS quantity,              -- Quantidade aleatória (1 a 30)
    DATE_SUB(CURRENT_DATE(), INTERVAL CAST(FLOOR(RAND() * (365 * 2)) AS INT64) DAY) AS order_date
FROM UNNEST(GENERATE_ARRAY(1, 100000)) AS id;


-- MODELAGEM DIMENSIONAL E CARGA ETL
-- SCHEMA (DDL) - CRIAÇÃO DAS TABELAS DO DATA MART


-- 1.1. Dimensão de Tempo
CREATE OR REPLACE TABLE seu_dataset_destino.DimDate (
    date_key INT64 NOT NULL, 
    full_date DATE NOT NULL,
    year INT64 NOT NULL,
    quarter INT64 NOT NULL,
    month INT64 NOT NULL,
    year_month STRING NOT NULL,
    day_of_week STRING NOT NULL
    day_of_month INT64 NOT NULL,
    is_weekend BOOL NOT NULL
);

-- 1.2. Dimensão de Produto
CREATE OR REPLACE TABLE seu_dataset_destino.DimProduct (
    product_key INT64 NOT NULL,
    product_id INT64 NOT NULL,
    name STRING,
    category STRING,
    current_price NUMERIC
);

-- 1.3. Dimensão de Cliente
CREATE OR REPLACE TABLE seu_dataset_destino.DimCustomer (
    customer_key INT64 NOT NULL,
    customer_id INT64 NOT NULL,
    name STRING,
    email STRING,
    city STRING,
    created_at DATE,
    last_order_date DATE
);

-- 1.4. Tabela Fato (Vendas)
CREATE OR REPLACE TABLE seu_dataset_destino.FactSales (
    date_key INT64,
    customer_key INT64,
    product_key INT64,
    order_id INT64,
    quantity_sold INT64,
    unit_price NUMERIC,
    total_revenue NUMERIC
);


-- #############################################################################
-- CARGA DE DADOS NAS TABELAS DO DATA MART
-- #############################################################################

-- 2.1 Carga da DimDate
DECLARE min_date DATE DEFAULT (SELECT DATE_SUB(MIN(order_date), INTERVAL 1 YEAR) FROM seu_dataset_origem.orders);
DECLARE max_date DATE DEFAULT (SELECT DATE_ADD(MAX(order_date), INTERVAL 5 YEAR) FROM seu_dataset_origem.orders);

INSERT INTO seu_dataset_destino.DimDate (
    date_key, full_date, year, quarter, month, year_month, day_of_week, day_of_month, is_weekend
)
SELECT
    CAST(FORMAT_DATE('%Y%m%d', d) AS INT64) AS date_key,
    d AS full_date,
    EXTRACT(YEAR FROM d) AS year,
    EXTRACT(QUARTER FROM d) AS quarter,
    EXTRACT(MONTH FROM d) AS month,
    FORMAT_DATE('%Y-%m', d) AS year_month,
    FORMAT_DATE('%A', d) AS day_of_week,
    EXTRACT(DAY FROM d) AS day_of_month,
    EXTRACT(DAYOFWEEK FROM d) IN (1, 7) AS is_weekend
FROM
    UNNEST(GENERATE_DATE_ARRAY(COALESCE(min_date, CURRENT_DATE()), COALESCE(max_date, CURRENT_DATE()))) AS d;


-- 2.2. Carga da DimProduct
INSERT INTO seu_dataset_destino.DimProduct (
    product_key, product_id, name, category, current_price
)
SELECT
    ROW_NUMBER() OVER(ORDER BY product_id) AS product_key, 
    product_id,
    name,
    category,
    price AS current_price
FROM
    seu_dataset_origem.products;


-- 2.3. Carga da DimCustomer
INSERT INTO seu_dataset_destino.DimCustomer (
    customer_key, customer_id, name, email, city, created_at, last_order_date
)
SELECT
    ROW_NUMBER() OVER(ORDER BY c.customer_id) AS customer_key,
    c.customer_id,
    c.name,
    c.email,
    c.city,
    c.created_at,
    MAX(o.order_date) AS last_order_date 
FROM
    seu_dataset_origem.customers AS c
LEFT JOIN
    seu_dataset_origem.orders AS o ON c.customer_id = o.customer_id
GROUP BY
    c.customer_id, c.name, c.email, c.city, c.created_at;


-- 2.4. Carga da FactSales
INSERT INTO seu_dataset_destino.FactSales (
    date_key, customer_key, product_key, order_id,
    quantity_sold, unit_price, total_revenue
)
SELECT
    dd.date_key,
    dc.customer_key,
    dp.product_key,
    o.order_id,
    o.quantity AS quantity_sold,
    p.price AS unit_price, 
    ROUND(o.quantity * p.price, 2) AS total_revenue
    
FROM
    seu_dataset_origem.orders AS o
JOIN
    seu_dataset_origem.products AS p 
    ON o.product_id = p.product_id
JOIN
    seu_dataset_destino.DimCustomer AS dc 
    ON o.customer_id = dc.customer_id
JOIN
    seu_dataset_destino.DimProduct AS dp 
    ON o.product_id = dp.product_id
JOIN
    seu_dataset_destino.DimDate AS dd 
    ON o.order_date = dd.full_date;