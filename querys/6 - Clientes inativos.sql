-- ITEM 6: Clientes inativos
-- Query para identificar clientes que não fizeram pedidos nos últimos 3 meses.

-- lógica:
-- varre a tabela gold_DimCustomer para identificar clientes inativos, last_order_date ñão aconteceu nos últimos 3 meses ou é nulo.
  
SELECT
  customer_id,
  name,
  email,
  city,
  last_order_date
FROM
  `case_alymente.gold_DimCustomer`
WHERE
  last_order_date IS NULL OR last_order_date < DATE_SUB(CURRENT_DATE(), INTERVAL 3 MONTH)
ORDER BY
  last_order_date DESC;