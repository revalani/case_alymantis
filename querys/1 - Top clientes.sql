-- ITEM 1 - TOP CLIENTES
-- Query para obter os 10 principais clientes com base no total gasto
-- Inclui o total gasto, número de pedidos e ticket médio

-- logica:
-- agrupa cliente
-- aplica métrica de consumo e força saida de somente 10 registros

SELECT
  dc.customer_id,
  dc.name,
  ROUND(SUM(fs.total_revenue), 2) AS total_spent,
  COUNT(DISTINCT fs.order_id) AS total_orders,
  ROUND(SAFE_DIVIDE(SUM(fs.total_revenue), COUNT(DISTINCT fs.order_id)), 2) AS avg_ticket
FROM
  `projeto-ceasa.case_alymente.gold_FactSales` AS fs
JOIN
  `projeto-ceasa.case_alymente.gold_DimCustomer` AS dc ON fs.customer_key = dc.customer_key
GROUP BY
  dc.customer_key, dc.customer_id, dc.name
ORDER BY
  total_spent DESC
LIMIT 10;