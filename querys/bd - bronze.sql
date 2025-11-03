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

