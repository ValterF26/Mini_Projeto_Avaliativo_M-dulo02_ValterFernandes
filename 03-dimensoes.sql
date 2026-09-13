-- 03-dimensoes.sql
-- Pata Amiga | PostgreSQL 16
-- Rode depois do 02-dimensoes-prontas.sql

-- ============================================================
-- DIM_CATEGORIA
-- Grao: uma grafia da origem.
-- A grafia crua fica armazenada para que a fato possa fazer
-- o lookup sem subconsulta.
-- ============================================================

INSERT INTO dim_categoria
    (sk_categoria, categoria_origem, nome_categoria, grupo_categoria)
VALUES
    (-1, 'Nao Informado', 'Nao Informado', 'Nao Informado');

INSERT INTO dim_categoria
    (categoria_origem, nome_categoria, grupo_categoria)
SELECT DISTINCT
    "CategoriaProduto",
    CASE
        WHEN UPPER(TRANSLATE(TRIM("CategoriaProduto"),
             'ÁÀÂÃÄÉÈÊËÍÌÎÏÓÒÔÕÖÚÙÛÜÇ',
             'AAAAAEEEEIIIIOOOOOUUUUC')) LIKE '%MED%'
            THEN 'Medicamento'
        WHEN UPPER(TRANSLATE(TRIM("CategoriaProduto"),
             'ÁÀÂÃÄÉÈÊËÍÌÎÏÓÒÔÕÖÚÙÛÜÇ',
             'AAAAAEEEEIIIIOOOOOUUUUC')) LIKE '%PETISC%'
            THEN 'Petisco'
        WHEN UPPER(TRANSLATE(TRIM("CategoriaProduto"),
             'ÁÀÂÃÄÉÈÊËÍÌÎÏÓÒÔÕÖÚÙÛÜÇ',
             'AAAAAEEEEIIIIOOOOOUUUUC')) LIKE '%RA%'
            THEN 'Racao'
        WHEN UPPER(TRANSLATE(TRIM("CategoriaProduto"),
             'ÁÀÂÃÄÉÈÊËÍÌÎÏÓÒÔÕÖÚÙÛÜÇ',
             'AAAAAEEEEIIIIOOOOOUUUUC')) LIKE '%HIG%'
            THEN 'Higiene'
        WHEN UPPER(TRANSLATE(TRIM("CategoriaProduto"),
             'ÁÀÂÃÄÉÈÊËÍÌÎÏÓÒÔÕÖÚÙÛÜÇ',
             'AAAAAEEEEIIIIOOOOOUUUUC')) LIKE '%BRINQ%'
            THEN 'Brinquedo'
        WHEN UPPER(TRANSLATE(TRIM("CategoriaProduto"),
             'ÁÀÂÃÄÉÈÊËÍÌÎÏÓÒÔÕÖÚÙÛÜÇ',
             'AAAAAEEEEIIIIOOOOOUUUUC')) LIKE '%ACESS%'
            THEN 'Acessorio'
        WHEN UPPER(TRANSLATE(TRIM("CategoriaProduto"),
             'ÁÀÂÃÄÉÈÊËÍÌÎÏÓÒÔÕÖÚÙÛÜÇ',
             'AAAAAEEEEIIIIOOOOOUUUUC')) LIKE '%SERV%'
            THEN 'Servico'
        ELSE 'Nao Informado'
    END,
    CASE
        WHEN UPPER(TRANSLATE(TRIM("CategoriaProduto"),
             'ÁÀÂÃÄÉÈÊËÍÌÎÏÓÒÔÕÖÚÙÛÜÇ',
             'AAAAAEEEEIIIIOOOOOUUUUC')) LIKE '%MED%'
            THEN 'Saude e Higiene'
        WHEN UPPER(TRANSLATE(TRIM("CategoriaProduto"),
             'ÁÀÂÃÄÉÈÊËÍÌÎÏÓÒÔÕÖÚÙÛÜÇ',
             'AAAAAEEEEIIIIOOOOOUUUUC')) LIKE '%PETISC%'
            THEN 'Alimentacao'
        WHEN UPPER(TRANSLATE(TRIM("CategoriaProduto"),
             'ÁÀÂÃÄÉÈÊËÍÌÎÏÓÒÔÕÖÚÙÛÜÇ',
             'AAAAAEEEEIIIIOOOOOUUUUC')) LIKE '%RA%'
            THEN 'Alimentacao'
        WHEN UPPER(TRANSLATE(TRIM("CategoriaProduto"),
             'ÁÀÂÃÄÉÈÊËÍÌÎÏÓÒÔÕÖÚÙÛÜÇ',
             'AAAAAEEEEIIIIOOOOOUUUUC')) LIKE '%HIG%'
            THEN 'Saude e Higiene'
        WHEN UPPER(TRANSLATE(TRIM("CategoriaProduto"),
             'ÁÀÂÃÄÉÈÊËÍÌÎÏÓÒÔÕÖÚÙÛÜÇ',
             'AAAAAEEEEIIIIOOOOOUUUUC')) LIKE '%BRINQ%'
            THEN 'Bem-estar'
        WHEN UPPER(TRANSLATE(TRIM("CategoriaProduto"),
             'ÁÀÂÃÄÉÈÊËÍÌÎÏÓÒÔÕÖÚÙÛÜÇ',
             'AAAAAEEEEIIIIOOOOOUUUUC')) LIKE '%ACESS%'
            THEN 'Bem-estar'
        WHEN UPPER(TRANSLATE(TRIM("CategoriaProduto"),
             'ÁÀÂÃÄÉÈÊËÍÌÎÏÓÒÔÕÖÚÙÛÜÇ',
             'AAAAAEEEEIIIIOOOOOUUUUC')) LIKE '%SERV%'
            THEN 'Bem-estar'
        ELSE 'Nao Informado'
    END
FROM stg_pedido;

-- ============================================================
-- DIM_PRACA
-- Grao: uma praca de atendimento.
-- ============================================================

INSERT INTO dim_praca
    (sk_praca, cod_praca, nome_praca, regional, domicilios_com_pet)
VALUES
    (-1, 'N/I', 'Nao Informado', 'Nao Informado', NULL);

INSERT INTO dim_praca
    (cod_praca, nome_praca, regional, domicilios_com_pet)
SELECT DISTINCT
    "CodPraca",
    "NomePraca",
    "Regional",
    CAST(REPLACE("DomiciliosComPet", '.', '') AS INTEGER)
FROM stg_loja_praca;

-- ============================================================
-- BRIDGE_LOJA_PRACA
-- A ponte usa o codigo natural da loja, conforme especificacao.
-- ============================================================

INSERT INTO bridge_loja_praca
    (cod_loja, sk_praca, fator_publico)
SELECT
    s."CodLoja",
    p.sk_praca,
    CAST(s."PercentualPublico" AS DECIMAL(6,4))
FROM stg_loja_praca s
JOIN dim_praca p
  ON p.cod_praca = s."CodPraca";
