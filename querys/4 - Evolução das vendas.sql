-- ITEM 4: Evolução das vendas
-- Query para obter a evolução das vendas mensais (total de receita e número de pedidos)

-- logica:
-- calcula um período dinâmico (DATAS CTE) para os últimos 12 meses
-- agrupa a receita total e a contagem de pedidos únicos por mÊs

WITH DATAS AS (
  SELECT
    DATE_SUB(
      DATE_TRUNC(MAX(dd.full_date), MONTH),
      INTERVAL 1 DAY
    ) AS data_fim,

    DATE_SUB(
      DATE_TRUNC(MAX(dd.full_date), MONTH),
      INTERVAL 12 MONTH
    ) AS data_inicio
  FROM
    `case_alymente.gold_FactSales` fs
    JOIN `case_alymente.gold_DimDate` dd ON fs.date_key = dd.date_key
)
-- Bloco 2: Consulta principal
SELECT
  dd.year_month,
  ROUND(SUM(fs.total_revenue), 2) AS total_revenue,
  COUNT(DISTINCT fs.order_id) AS total_orders
FROM
  `case_alymente.gold_FactSales` AS fs
  JOIN `case_alymente.gold_DimDate` AS dd ON fs.date_key = dd.date_key
  JOIN DATAS d ON dd.full_date BETWEEN d.data_inicio AND d.data_fim
GROUP BY
  dd.year_month
ORDER BY
  dd.year_month ASC;