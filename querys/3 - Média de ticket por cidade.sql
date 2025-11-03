-- ITEM 3: Média de ticket por cidade
--Query para obter para calcular a média de ticket (total de receita por pedido) para cada cidade dos clientes.


SELECT
  COALESCE(dc.city, 'Cidade Não Especificada') AS city,
  ROUND(SUM(fs.total_revenue), 2) AS total_revenue,
  COUNT(DISTINCT fs.order_id) AS total_orders,
  ROUND(SAFE_DIVIDE(SUM(fs.total_revenue), COUNT(DISTINCT fs.order_id)), 2) AS avg_ticket
FROM
  `projeto-ceasa.case_alymente.gold_FactSales` AS fs
JOIN
  `projeto-ceasa.case_alymente.gold_DimCustomer` AS dc ON fs.customer_key = dc.customer_key
GROUP BY
  city
ORDER BY
  avg_ticket DESC;