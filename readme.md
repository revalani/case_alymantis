
# Parte 1 SQL

## Motivação
Para fins de demonstração, descrevi o schema em formato normalizado, e creiei uma modelagem dimencional para fins analitivos, para aplicação do conceito de arquitetura medalão, como referencias de boas práticas, criando uma copia do banco de origem e aplicando tratamento e cruzamento de dados em camadas e aplicando regras de negócio até o cliente analitico final, como paineis, analistas ou chefes das Unidades de negócio.

para carga do banco, cries um script para simular dados de produtos, cliente e ordens de compra conforme a espesificação.


Afim de cotinuar a amordagem medalhão, criei um script de carga para o modelo dimencional com carga incremental entre para menor impacto evitando full- load 



## Escolha do banco de dados Google BigQuery:
    - Banco para propositos analiticos OLAP
        - Banco colunar
    - Indicado para data warehouse 
    - Serverless
    - Processamento paralalo (MPP)
    - Integração com Looker Studio
        - Cache nativo de consultas
        - Controle de parametros

## url de acesso: 
    https://lookerstudio.google.com/s/sUM4b5EFcJ4