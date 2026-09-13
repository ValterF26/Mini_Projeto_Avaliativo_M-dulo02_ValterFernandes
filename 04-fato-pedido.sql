-- 04-fato-pedido.sql
-- Pata Amiga | PostgreSQL 16
-- Rode depois do 03-dimensoes.sql
-- Grao: 1 linha = 1 pedido

INSERT INTO fato_pedido
(
    numero_pedido,
    sk_tempo_pedido,
    sk_tempo_entrega,
    sk_loja,
    sk_categoria,
    houve_desconto,
    canal_pedido,
    dt_pedido,
    qt_itens,
    vl_liquido,
    dias_integracao_separacao,
    dias_separacao_nota,
    dias_nota_despacho,
    dias_despacho_entrega,
    dias_total_ate_entrega
)
SELECT
    p."NumeroPedido",

    -- A data do pedido usa a mascara americana.
    TO_CHAR(
        TO_TIMESTAMP(p."DtHoraPedido", 'MM/DD/YYYY HH12:MI AM'),
        'YYYYMMDD'
    )::INT,

    -- Entrega em aberto aponta para a linha -1 da dim_tempo.
    CASE
        WHEN TRIM(p."DtEntregaCliente") = '' THEN -1
        ELSE TO_CHAR(p."DtEntregaCliente"::DATE, 'YYYYMMDD')::INT
    END,

    -- O nome e padronizado antes do lookup.
    CASE
        WHEN TRIM(p."Loja-Nome") = '' THEN -1
        ELSE COALESCE(l.sk_loja, -1)
    END,

    COALESCE(c.sk_categoria, -1),

    -- Dominio de desconto.
    CASE
        WHEN UPPER(TRIM(p."HouveDesconto")) IN
             ('S','SIM','1','X','TRUE','V')
            THEN 'Sim'
        WHEN UPPER(TRIM(p."HouveDesconto")) IN
             ('N','NAO','0','FALSE','F')
            THEN 'Nao'
        ELSE 'Nao Informado'
    END,

    -- WHATS vem antes de APP, pois WHATSAPP contem APP.
    CASE
        WHEN UPPER(TRIM(p."CanalPedido")) LIKE '%WHATS%'
            THEN 'WhatsApp'
        WHEN UPPER(TRIM(p."CanalPedido")) LIKE '%APP%'
            THEN 'App'
        WHEN UPPER(TRIM(p."CanalPedido")) LIKE '%SITE%'
            THEN 'Site'
        WHEN UPPER(TRIM(p."CanalPedido")) LIKE '%LOJA%'
            THEN 'Loja Fisica'
        WHEN UPPER(TRIM(p."CanalPedido")) LIKE '%TEL%'
            THEN 'Telefone'
        ELSE 'Nao Informado'
    END,

    TO_TIMESTAMP(p."DtHoraPedido", 'MM/DD/YYYY HH12:MI AM'),

    CASE
        WHEN TRIM(p."QTD.Itens") IN ('','-','N/I','N/D')
            THEN NULL
        ELSE CAST(REPLACE(TRIM(p."QTD.Itens"), ',', '.') AS INTEGER)
    END,

    -- Regra monetaria especificada no enunciado.
    CASE
        WHEN TRIM(REPLACE(p."ValorLiquidoPedido(R$)",'R$','')) IN ('','-')
            THEN NULL
        WHEN p."ValorLiquidoPedido(R$)" LIKE '%,%'
            THEN CAST(
                REPLACE(
                    REPLACE(
                        REPLACE(
                            REPLACE(p."ValorLiquidoPedido(R$)",'R$',''),
                            ' ',''
                        ),
                        '.',''
                    ),
                    ',','.'
                ) AS DECIMAL(15,2)
            )
        ELSE CAST(
            REPLACE(
                REPLACE(p."ValorLiquidoPedido(R$)",'R$',''),
                ' ',''
            ) AS DECIMAL(15,2)
        )
    END,

    -- Marco em branco significa processo aberto: NULL, nunca zero.
    CASE
        WHEN TRIM(p."Dt Separacao Estoque") = '' THEN NULL
        ELSE p."Dt Separacao Estoque"::DATE
             - TO_TIMESTAMP(p."DtHoraIntegracaoERP",
                            'MM/DD/YYYY HH12:MI AM')::DATE
    END,

    CASE
        WHEN TRIM(p."Dt Separacao Estoque") = ''
          OR TRIM(p."DtNotaFiscal") = ''
            THEN NULL
        ELSE p."DtNotaFiscal"::DATE
             - p."Dt Separacao Estoque"::DATE
    END,

    CASE
        WHEN TRIM(p."DtNotaFiscal") = ''
          OR TRIM(p."Dt_Despacho_Transportadora") = ''
            THEN NULL
        ELSE p."Dt_Despacho_Transportadora"::DATE
             - p."DtNotaFiscal"::DATE
    END,

    CASE
        WHEN TRIM(p."Dt_Despacho_Transportadora") = ''
          OR TRIM(p."DtEntregaCliente") = ''
            THEN NULL
        ELSE p."DtEntregaCliente"::DATE
             - p."Dt_Despacho_Transportadora"::DATE
    END,

    CASE
        WHEN TRIM(p."DtEntregaCliente") = '' THEN NULL
        ELSE p."DtEntregaCliente"::DATE
             - TO_TIMESTAMP(p."DtHoraIntegracaoERP",
                            'MM/DD/YYYY HH12:MI AM')::DATE
    END

FROM stg_pedido p

LEFT JOIN dim_categoria c
  ON c.categoria_origem = p."CategoriaProduto"

LEFT JOIN dim_loja l
  ON l.chave_loja =
     CASE
        WHEN UPPER(
             TRANSLATE(
                REPLACE(REPLACE(TRIM(p."Loja-Nome"), '/SC', ''), '  ', ' '),
                'áàâãäéèêëíìîïóòôõöúùûüçÁÀÂÃÄÉÈÊËÍÌÎÏÓÒÔÕÖÚÙÛÜÇ',
                'aaaaaeeeeiiiiooooouuuucAAAAAEEEEIIIIOOOOOUUUUC'
             )
        ) = 'PATA AMIGA BLUMENAL CENTRO'
            THEN 'PATA AMIGA BLUMENAU CENTRO'
        WHEN UPPER(
             TRANSLATE(
                REPLACE(REPLACE(TRIM(p."Loja-Nome"), '/SC', ''), '  ', ' '),
                'áàâãäéèêëíìîïóòôõöúùûüçÁÀÂÃÄÉÈÊËÍÌÎÏÓÒÔÕÖÚÙÛÜÇ',
                'aaaaaeeeeiiiiooooouuuucAAAAAEEEEIIIIOOOOOUUUUC'
             )
        ) = 'PATA AMIGA FLORIPA NORTE'
            THEN 'PATA AMIGA FLORIANOPOLIS NORTE'
        WHEN UPPER(
             TRANSLATE(
                REPLACE(REPLACE(TRIM(p."Loja-Nome"), '/SC', ''), '  ', ' '),
                'áàâãäéèêëíìîïóòôõöúùûüçÁÀÂÃÄÉÈÊËÍÌÎÏÓÒÔÕÖÚÙÛÜÇ',
                'aaaaaeeeeiiiiooooouuuucAAAAAEEEEIIIIOOOOOUUUUC'
             )
        ) = 'PATA AMIGA JGUA DO SUL'
            THEN 'PATA AMIGA JARAGUA DO SUL'
        ELSE UPPER(
             TRANSLATE(
                REPLACE(REPLACE(TRIM(p."Loja-Nome"), '/SC', ''), '  ', ' '),
                'áàâãäéèêëíìîïóòôõöúùûüçÁÀÂÃÄÉÈÊËÍÌÎÏÓÒÔÕÖÚÙÛÜÇ',
                'aaaaaeeeeiiiiooooouuuucAAAAAEEEEIIIIOOOOOUUUUC'
             )
        )
     END;
