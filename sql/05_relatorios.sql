

-- RELATORIO 01 - Quais sao os 10 clientes que mais gastaram na loja?

SELECT
    cl.id_cliente,
    cl.nome AS cliente,
    COUNT(c.id_compra) AS total_compras,
    SUM(c.valor_total)::NUMERIC(12,2) AS total_gasto
FROM public.cliente AS cl
JOIN public.compra AS c
    ON c.id_cliente = cl.id_cliente
WHERE c.data_compra >= DATE '2025-01-01'
GROUP BY cl.id_cliente, cl.nome
ORDER BY total_gasto DESC, total_compras DESC, cl.id_cliente
LIMIT 10;


-- RELATORIO 02 - Quais produtos venderam mais unidades?

SELECT
    p.id_produto,
    p.nome AS produto,
    SUM(i.quantidade) AS unidades_vendidas,
    SUM(i.quantidade * i.preco_unitario)::NUMERIC(12,2) AS receita_gerada
FROM public.produto AS p
JOIN public.item_compra AS i
    ON i.id_produto = p.id_produto
JOIN public.compra AS c
    ON c.id_compra = i.id_compra
WHERE c.data_compra >= DATE '2025-01-01'
GROUP BY p.id_produto, p.nome
ORDER BY unidades_vendidas DESC, receita_gerada DESC, p.id_produto
LIMIT 15;


-- RELATORIO 03 - Qual foi o faturamento registrado por mes?

SELECT
    DATE_TRUNC('month', c.data_compra)::DATE AS mes,
    COUNT(c.id_compra) AS quantidade_compras,
    COUNT(DISTINCT cl.id_cliente) AS clientes_distintos,
    SUM(c.valor_total)::NUMERIC(12,2) AS faturamento
FROM public.compra AS c
JOIN public.cliente AS cl
    ON cl.id_cliente = c.id_cliente
WHERE c.data_compra >= DATE '2025-01-01'
GROUP BY DATE_TRUNC('month', c.data_compra)::DATE
ORDER BY mes DESC;


-- RELATORIO 04 - Quais foram as compras de maior valor?

SELECT
    c.id_compra,
    c.data_compra,
    cl.id_cliente,
    cl.nome AS cliente,
    c.valor_total
FROM public.compra AS c
JOIN public.cliente AS cl
    ON cl.id_cliente = c.id_cliente
WHERE c.valor_total >= 500.00
ORDER BY c.valor_total DESC, c.id_compra
LIMIT 15;


-- RELATORIO 05 - Quais produtos estao com menor estoque e quem os cadastrou?

SELECT
    p.id_produto,
    p.nome AS produto,
    p.quantidade_estoque,
    f.nome AS funcionario_responsavel
FROM public.produto AS p
JOIN public.funcionario AS f
    ON f.id_funcionario = p.id_funcionario
WHERE p.quantidade_estoque <= 110
ORDER BY p.quantidade_estoque ASC, p.id_produto
LIMIT 20;


-- RELATORIO 06 - Quais funcionarios cadastraram mais produtos?

SELECT
    f.id_funcionario,
    f.nome AS funcionario,
    f.cargo,
    COUNT(p.id_produto) AS produtos_cadastrados
FROM public.funcionario AS f
JOIN public.produto AS p
    ON p.id_funcionario = f.id_funcionario
WHERE f.data_contratacao <= DATE '2026-11-25'
GROUP BY f.id_funcionario, f.nome, f.cargo
ORDER BY produtos_cadastrados DESC, f.id_funcionario
LIMIT 15;


-- RELATORIO 07 - Quais clientes possuem mais de um telefone cadastrado?

SELECT
    cl.id_cliente,
    cl.nome AS cliente,
    COUNT(t.telefone) AS telefones_cadastrados,
    STRING_AGG(t.telefone, ' | ' ORDER BY t.telefone) AS telefones
FROM public.cliente AS cl
JOIN public.telefone_cliente AS t
    ON t.id_cliente = cl.id_cliente
WHERE cl.estado = 'SP'
GROUP BY cl.id_cliente, cl.nome
HAVING COUNT(t.telefone) > 1
ORDER BY telefones_cadastrados DESC, cl.id_cliente
LIMIT 15;


-- RELATORIO 08 - Quanto gastaram os clientes com contas ativas?
-- Inclui clientes ativos sem compras por meio de LEFT JOIN.

SELECT
    cl.id_cliente,
    cl.nome AS cliente,
    cc.status AS status_conta,
    COUNT(c.id_compra) AS compras_realizadas,
    COALESCE(SUM(c.valor_total), 0)::NUMERIC(12,2) AS total_gasto
FROM public.cliente AS cl
JOIN public.cliente_conta AS cc
    ON cc.id_cliente = cl.id_cliente
LEFT JOIN public.compra AS c
    ON c.id_cliente = cl.id_cliente
WHERE cc.status = 'ativa'
GROUP BY cl.id_cliente, cl.nome, cc.status
ORDER BY total_gasto DESC, cl.id_cliente
LIMIT 15;


-- RELATORIO 09 - Em quais itens o preco historico ficou abaixo do atual?
-- Diferenca positiva indica preco registrado no item menor que o catalogo.

SELECT
    c.id_compra,
    c.data_compra,
    p.id_produto,
    p.nome AS produto,
    i.quantidade,
    i.preco_unitario AS preco_na_compra,
    p.preco_venda AS preco_atual,
    (p.preco_venda - i.preco_unitario)::NUMERIC(10,2) AS diferenca_unitaria
FROM public.item_compra AS i
JOIN public.compra AS c
    ON c.id_compra = i.id_compra
JOIN public.produto AS p
    ON p.id_produto = i.id_produto
WHERE i.preco_unitario < p.preco_venda
ORDER BY diferenca_unitaria DESC, c.id_compra
LIMIT 15;


-- RELATORIO 10 - Quais itens compoem as compras realizadas em 2026?
-- Mostra, por linha, cliente, produto, quantidade e subtotal.

SELECT
    c.id_compra,
    c.data_compra,
    cl.nome AS cliente,
    p.nome AS produto,
    i.quantidade,
    i.preco_unitario,
    (i.quantidade * i.preco_unitario)::NUMERIC(12,2) AS subtotal_item
FROM public.compra AS c
JOIN public.cliente AS cl
    ON cl.id_cliente = c.id_cliente
JOIN public.item_compra AS i
    ON i.id_compra = c.id_compra
JOIN public.produto AS p
    ON p.id_produto = i.id_produto
WHERE c.data_compra >= DATE '2026-01-01'
ORDER BY c.data_compra DESC, c.id_compra, p.nome
LIMIT 25;
