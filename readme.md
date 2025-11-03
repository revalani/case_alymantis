# Teste Técnico - Analista de Dados

Este repositório contém a solução para o teste técnico de Analista de Dados, focado em SQL, modelagem de dados e visualização.

## 1\. Ferramentas Usadas

  * **Banco de Dados:** Google BigQuery (Dialeto: Standard SQL)
  * **Visualização de Dados:** Google Looker Studio
  * **Controle de Versão:** Git / GitHub

## 2\. Motivação e Arquitetura

Para fins de demonstração, descrevi o schema em formato normalizado (camada **Bronze**) e criei uma modelagem dimensional (camada **Gold**) para fins analíticos. Esta abordagem aplica o conceito de arquitetura medalhão, criando uma cópia do banco de origem (Bronze) e aplicando tratamentos e cruzamentos de dados em camadas (Gold) até o cliente analítico final (Dashboards, analistas, etc.).

### Motivos para uso do Google BigQuery:

  * Banco de dados colunar otimizado para propósitos analíticos (OLAP).
  * Solução *Serverless*, eliminando a necessidade de gerenciamento de infraestrutura.
  * Processamento paralelo massivo (MPP) para alta performance em grandes volumes.
  * Integração nativa com o Looker Studio, incluindo cache de consultas e controle de parâmetros.

## 3\. Como Executar os Scripts

Os scripts devem ser executados no **Google BigQuery**.

### Pré-requisitos

1.  Crie um projeto no Google Cloud.
2.  Dentro do projeto, crie dois *datasets* no BigQuery (ex: `case_bronze` e `case_gold`).

### Passo 1: Criação e Simulação de Dados (Camada Bronze)

Execute o script abaixo no editor de consultas do BigQuery para criar as tabelas normalizadas e simular os dados de clientes, produtos e pedidos.

  * **Script:** `querys/bd - bronze.sql`
  * **Atenção:** Substitua a variável `seu_dataset` no script pelo nome do seu dataset **Bronze** (ex: `case_bronze`).

<!-- end list -->

```sql
-- Exemplo de substituição em bd - bronze.sql
CREATE TABLE `seu_dataset`.customers ( ... );
-- DEVE VIRAR
CREATE TABLE `case_bronze`.customers ( ... );
```

### Passo 2: ETL para Modelo Dimensional (Camada Gold)

Execute este script para criar o *Data Mart* (modelo dimensional Star Schema) e carregar os dados tratados da camada Bronze.

  * **Script:** `querys/bd - gold.sql`
  * **Atenção:** Substitua as variáveis `seu_dataset_origem` (Bronze) e `seu_dataset_destino` (Gold) pelos nomes corretos dos seus datasets.

<!-- end list -->

```sql
-- Exemplo de substituição em bd - gold.sql
CREATE OR REPLACE TABLE `seu_dataset_destino`.DimDate ( ... );
-- DEVE VIRAR
CREATE OR REPLACE TABLE `case_gold`.DimDate ( ... );

...

INSERT INTO `seu_dataset_destino`.DimDate ( ... )
SELECT ...
FROM UNNEST(GENERATE_DATE_ARRAY(COALESCE(min_date, CURRENT_DATE()), COALESCE(max_date, CURRENT_DATE()))) AS d;
-- (O SELECT acima usa variáveis, mas as cargas subsequentes não)

...

FROM `seu_dataset_origem`.products;
-- DEVE VIRAR
FROM `case_bronze`.products;
```

### Passo 3: Consultas Analíticas (Respostas do Teste)

Após a criação das camadas Bronze e Gold, as consultas analíticas (itens 1 a 6) podem ser executadas. Todas elas leem dados da camada **Gold**.

  * **Scripts:**
      * `querys/1 - Top clientes.sql`
      * `querys/2 - Vendas por categoria.sql`
      * `querys/3 - Média de ticket por cidade.sql`
      * `querys/4 - Evolução das vendas.sql`
      * `querys/5 - Produto com maior crescimento.sql`
      * `querys/6 - Clientes inativos.sql`
  * **Atenção:** Verifique se os nomes do projeto e dataset nas consultas correspondem ao seu ambiente (ex: `projeto-ceasa.case_alymente.gold_FactSales` ou `case_alymente.gold_DimCustomer`).

## 4\. Principais Decisões, Trade-offs e Limitações

  * **Decisão (Arquitetura):** Adotar a modelagem dimensional (Star Schema) na camada Gold.
      * **Trade-off:** Esta abordagem gera redundância de dados (comparada à 3FN da camada Bronze), mas oferece performance e simplicidade muito superiores para consultas analíticas (OLAP), que é o objetivo do teste.
  * **Decisão (Carga de Dados):** O script `bd - gold.sql` realiza uma carga completa (full-load).
      * **Limitação:** Para um ambiente de produção, o ideal seria implementar cargas incrementais (como mencionado na motivação inicial), especialmente para a `FactSales`, filtrando apenas por pedidos novos ou atualizados desde a última carga. A carga full-load é mais simples de implementar para esta demonstração.
  * **Limitação (Simulação de Dados):** Os dados gerados em `bd - bronze.sql` são aleatórios.
      * **Impacto:** A distribuição de vendas, clientes por cidade e tendências temporais (sazonalidade) não refletem um cenário de negócios real, o que limita a profundidade dos *insights* analíticos.
  * **Decisão (Query 5 - Crescimento):** A métrica de crescimento escolhida foi o maior **crescimento absoluto** na quantidade vendida comparando um mês com o mês anterior (`LAG`).
      * **Limitação:** Esta métrica favorece produtos com alto volume de vendas (um aumento de 1000 para 1100 unidades é maior que um de 10 para 50). Uma métrica de crescimento *percentual* (`growth_pct`) poderia ser usada, mas é volátil para produtos com baixo volume (ex: 1 para 10 = 900% de crescimento). A consulta calcula ambos, mas ordena pelo absoluto.

## 5\. Instruções para Abrir o Dashboard

O dashboard foi desenvolvido no Looker Studio e está disponível publicamente para visualização.

  * **Link de Acesso:** [https://lookerstudio.google.com/s/sUM4b5EFcJ4](https://lookerstudio.google.com/s/sUM4b5EFcJ4)

O dashboard se conecta diretamente ao *dataset* Gold no BigQuery e utiliza os requisitos mínimos solicitados no teste (KPIs, gráficos de barra, linha, pizza e filtros interativos).