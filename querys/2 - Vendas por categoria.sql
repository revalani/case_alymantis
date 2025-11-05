-- ITEM 2 - VENDAS POR CATEGORIA
-- Query para obter o total de vendas, quantidade vendida e preço médio por categoria de produto 

-- logica:
-- agrupa categoria
-- aplica métricas de soma e média

SELECT
  dp.category,
  ROUND(SUM(fs.total_revenue), 2) AS total_revenue,
  SUM(fs.quantity_sold) AS total_quantity,
  ROUND(SAFE_DIVIDE(SUM(fs.total_revenue), SUM(fs.quantity_sold)), 2) AS avg_price
FROM
  `projeto-ceasa.case_alymente.gold_FactSales` AS fs
JOIN
  `projeto-ceasa.case_alymente.gold_DimProduct` AS dp ON fs.product_key = dp.product_key
GROUP BY
  dp.category
ORDER BY
  total_revenue DESC;
