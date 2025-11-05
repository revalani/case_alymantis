-- ITEM 5: Produto com maior crescimento
-- Query para identificar o produto com maior crescimento em vendas absolutas Mês a Mês no último semestre.

-- lógica:
-- Agregar vendas mensais por produto nos últimos 6 meses, usa a função LAG() para obter as vendas do mês anterior e calcular o crescimento absoluto (mês atual vs. anterior)
-- usar rownumber para classificar o produto com maior crescimento por mês





  -- Bloco 1: Definir o período
  DECLARE data_fim_6m DATE DEFAULT (
      SELECT DATE_SUB(
          DATE_TRUNC(MAX(dd.full_date), MONTH),
          INTERVAL 1 DAY
        )
      FROM `case_alymente.gold_FactSales` fs
        JOIN `case_alymente.gold_DimDate` dd ON fs.date_key = dd.date_key
    );
  DECLARE data_inicio_6m DATE DEFAULT (
      SELECT DATE_ADD(
          DATE_TRUNC(data_fim_6m, MONTH),
          INTERVAL -6 MONTH
        )
    );
  -- Bloco 2: Consulta principal com CTEs
  WITH sales_per_month AS (
    SELECT fs.product_key,
      dd.year_month,
      SUM(fs.quantity_sold) AS total_quantity
    FROM `case_alymente.gold_FactSales` AS fs
      JOIN `case_alymente.gold_DimDate` AS dd ON fs.date_key = dd.date_key
    WHERE dd.full_date BETWEEN data_inicio_6m AND data_fim_6m
    GROUP BY fs.product_key,
      dd.year_month
  ),
  sales_with_lag AS (
    SELECT product_key,
      year_month AS month_to,
      total_quantity AS qty_to,
      LAG(year_month, 1) OVER (
        PARTITION BY product_key
        ORDER BY year_month ASC
      ) AS month_from,
      LAG(total_quantity, 1) OVER (
        PARTITION BY product_key
        ORDER BY year_month ASC
      ) AS qty_from
    FROM sales_per_month
  ),
  growth_calc AS (
    SELECT product_key,
      month_from,
      month_to,
      COALESCE(qty_from, 0) AS qty_from,
      qty_to,
      (qty_to - COALESCE(qty_from, 0)) AS growth_absolute,
      SAFE_DIVIDE(qty_to - COALESCE(qty_from, 0), qty_from) AS growth_pct
    FROM sales_with_lag
    WHERE month_from IS NOT NULL
  ),
  top_month_product as (
    SELECT dp.product_id,
      dp.name,
      gc.month_from,
      gc.month_to,
      gc.qty_from,
      gc.qty_to,
      gc.growth_absolute,
      ROUND(gc.growth_pct, 4) AS growth_pct,

      -- only top 1 per month
      ROW_NUMBER() OVER(
        PARTITION BY gc.month_to
        ORDER BY gc.growth_absolute DESC
      ) AS rn
    FROM growth_calc AS gc
      JOIN `case_alymente.gold_DimProduct` AS dp ON gc.product_key = dp.product_key
    WHERE gc.growth_absolute > 0
    ORDER BY growth_absolute DESC
  )
  select *
  from top_month_product
  where rn = 1
  order by month_to desc