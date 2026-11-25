-- TRABALHO FINAL - E-COMMERCE DE ELETRONICOS
-- 03_popular_dados.sql - PostgreSQL / Supabase
-- Versao corrigida: nao utiliza tabelas temporarias (seed_*).
-- Uma unica instrucao DO para inserir todos os registros de forma atomica.
-- Tambem se recupera do erro anterior caso APENAS cliente e funcionario
-- tenham sido preenchidos, com exatamente 500 registros cada.
-- Nao faz DELETE, TRUNCATE, DROP ou recriacao de tabelas.

DO $populacao$
DECLARE
    v_clientes INTEGER;
    v_funcionarios INTEGER;
BEGIN
    SELECT COUNT(*) INTO v_clientes FROM public.cliente;
    SELECT COUNT(*) INTO v_funcionarios FROM public.funcionario;

    -- Nao continua se alguma tabela dependente ja recebeu dados.
    IF EXISTS (SELECT 1 FROM public.cliente_conta)
       OR EXISTS (SELECT 1 FROM public.telefone_cliente)
       OR EXISTS (SELECT 1 FROM public.produto)
       OR EXISTS (SELECT 1 FROM public.compra)
       OR EXISTS (SELECT 1 FROM public.item_compra) THEN
        RAISE EXCEPTION 'Populacao cancelada: uma ou mais tabelas dependentes ja possuem dados. Verifique as contagens antes de executar novamente.';
    END IF;

    IF v_clientes = 0 AND v_funcionarios = 0 THEN
        -- 1) 500 funcionarios
        INSERT INTO public.funcionario (nome, cargo, salario, data_contratacao)
        SELECT
            (ARRAY['Ana','Bruno','Carla','Daniel','Eduarda','Felipe','Gabriela','Henrique',
                   'Isabela','Joao','Larissa','Marcos','Natalia','Otavio','Paula','Rafael',
                   'Sofia','Thiago','Vanessa','Yuri'])[((g-1)%20)+1]
            || ' ' ||
            (ARRAY['Silva','Souza','Oliveira','Santos','Pereira','Costa','Rodrigues',
                   'Almeida','Nascimento','Lima','Araujo','Fernandes','Carvalho',
                   'Gomes','Martins','Rocha','Ribeiro','Alves','Monteiro','Freitas',
                   'Cardoso','Barbosa','Mendes','Castro','Teixeira'])[((g-1)/20)+1],
            (ARRAY['Vendas','Estoque','Atendimento','Financeiro','Tecnologia',
                   'Logistica','Compras','Supervisao'])[1+((g-1)%8)],
            (ARRAY[2800,3100,2700,4200,5800,2900,3500,6500]::numeric[])[1+((g-1)%8)]
                 + (g%17)*25.00,
            DATE '2019-01-01' + ((g*7)%2400)
        FROM generate_series(1,500) AS g;

        -- 2) 500 clientes com enderecos ficticios
        INSERT INTO public.cliente
            (nome, email, logradouro, cep, numero, estado, complemento, bairro)
        SELECT
            (ARRAY['Amanda','Bernardo','Camila','Diego','Elisa','Fabio','Giovana','Heitor',
                   'Iris','Juliana','Leonardo','Mariana','Nicolas','Patricia','Renato',
                   'Sabrina','Tiago','Valeria','Wesley','Yasmin'])[((g-1)%20)+1]
            || ' ' ||
            (ARRAY['Silva','Souza','Oliveira','Santos','Pereira','Costa','Rodrigues',
                   'Almeida','Nascimento','Lima','Araujo','Fernandes','Carvalho',
                   'Gomes','Martins','Rocha','Ribeiro','Alves','Monteiro','Freitas',
                   'Cardoso','Barbosa','Mendes','Castro','Teixeira'])[((g-1)/20)+1],
            'cliente' || LPAD(g::text,4,'0') || '@clientes.exemplo.test',
            (ARRAY['Rua das Palmeiras','Avenida Central','Rua do Comercio','Rua dos Ipes',
                   'Avenida Brasil','Rua das Acacias','Rua do Lago','Rua Primavera',
                   'Rua das Flores','Avenida Paulista'])[1+((g-1)%10)],
            '14' || LPAD((100000+(g*11)%80000)::text,6,'0'),
            (20+(g*3)%980)::text,
            'SP',
            CASE WHEN g%4=0 THEN 'Apartamento ' || ((g%90)+1)::text ELSE NULL END,
            (ARRAY['Centro','Jardim Europa','Vila Nova','Boa Vista','Sao Jose',
                   'Jardim America','Alto da Serra','Santa Rita'])[1+((g-1)%8)]
        FROM generate_series(1,500) AS g;

    ELSIF v_clientes = 500 AND v_funcionarios = 500 THEN
        -- Caso a execucao anterior tenha gravado somente estas duas tabelas,
        -- reaproveitamos os dados existentes sem duplica-los.
        IF (SELECT COUNT(*) FROM public.cliente
            WHERE email LIKE 'cliente%@clientes.exemplo.test') <> 500 THEN
            RAISE EXCEPTION 'Existem 500 clientes, mas eles nao correspondem ao conjunto ficticio esperado. Nenhuma alteracao foi aplicada.';
        END IF;
    ELSE
        RAISE EXCEPTION 'Estado inesperado: cliente=% e funcionario=%. Esperado 0/0 ou 500/500; nenhuma alteracao foi aplicada.',
            v_clientes, v_funcionarios;
    END IF;

    -- 3) 500 contas: um registro por cliente (relacionamento 1:1)
    INSERT INTO public.cliente_conta (id_cliente, data_criacao, status, ultimo_acesso)
    SELECT
        c.id_cliente,
        TIMESTAMPTZ '2024-01-01 08:00:00+00' + ((c.n%200)*INTERVAL '1 day'),
        CASE WHEN c.n<=475 THEN 'ativa' ELSE 'suspensa' END,
        CASE WHEN c.n<=475
             THEN TIMESTAMPTZ '2026-11-20 12:00:00+00' - ((c.n%50)*INTERVAL '1 day')
             ELSE NULL END
    FROM (
        SELECT id_cliente, ROW_NUMBER() OVER (ORDER BY id_cliente)::integer AS n
        FROM public.cliente
    ) AS c;

    -- 4) 800 telefones: 500 primeiros + telefone adicional para 300 clientes
    INSERT INTO public.telefone_cliente (id_cliente, telefone)
    SELECT c.id_cliente,
           '(16) 9' || LPAD((1000+c.n)::text,4,'0') || '-'
                     || LPAD(((c.n*17)%10000)::text,4,'0')
    FROM (
        SELECT id_cliente, ROW_NUMBER() OVER (ORDER BY id_cliente)::integer AS n
        FROM public.cliente
    ) AS c
    UNION ALL
    SELECT c.id_cliente,
           '(16) 9' || LPAD((6000+c.n)::text,4,'0') || '-'
                     || LPAD(((c.n*29)%10000)::text,4,'0')
    FROM (
        SELECT id_cliente, ROW_NUMBER() OVER (ORDER BY id_cliente)::integer AS n
        FROM public.cliente
    ) AS c
    WHERE c.n<=300;

    -- 5) 600 produtos vinculados aos funcionarios
    INSERT INTO public.produto
        (id_funcionario, nome, descricao, preco_venda, quantidade_estoque)
    SELECT
        f.id_funcionario,
        (ARRAY['Notebook','Smartphone','Monitor','Teclado','Mouse',
               'Headset','SSD','Webcam','Roteador','Tablet'])[1+((g-1)%10)]
             || ' ' ||
        (ARRAY['Aurora','Orion','Nexa','Prisma','Atlas','Quantum'])[1+((g-1)%6)]
             || ' Modelo ' || LPAD(g::text,4,'0'),
        'Eletronico da categoria '
             || (ARRAY['Notebook','Smartphone','Monitor','Teclado','Mouse',
                        'Headset','SSD','Webcam','Roteador','Tablet'])[1+((g-1)%10)]
             || ', modelo ficticio com garantia de 12 meses.',
        (ARRAY[2999.90,1699.90,899.90,159.90,89.90,
               249.90,339.90,229.90,319.90,1299.90]::numeric[])[1+((g-1)%10)]
             + (g%13)*9.50,
        80+((g*13)%120)
    FROM generate_series(1,600) AS g
    JOIN (
        SELECT id_funcionario, ROW_NUMBER() OVER (ORDER BY id_funcionario)::integer AS n
        FROM public.funcionario
    ) AS f ON f.n=1+((g-1)%500);

    -- 6) 1.500 compras de clientes com conta ativa
    INSERT INTO public.compra (id_cliente, data_compra, valor_total)
    SELECT c.id_cliente,
           DATE '2025-01-15' + ((g*17)%660),
           0.00
    FROM generate_series(1,1500) AS g
    JOIN (
        SELECT id_cliente, ROW_NUMBER() OVER (ORDER BY id_cliente)::integer AS n
        FROM public.cliente
    ) AS c ON c.n=1+((g-1)%475);

    -- 7) 3.000 itens: dois produtos diferentes por compra
    INSERT INTO public.item_compra
        (id_compra, id_produto, quantidade, preco_unitario)
    SELECT
        c.id_compra,
        p.id_produto,
        1+((c.n+s.posicao)%3),
        ROUND(p.preco_venda *
              (CASE WHEN (c.n+s.posicao)%9=0 THEN 0.90 ELSE 1.00 END),2)
    FROM (
        SELECT id_compra, ROW_NUMBER() OVER (ORDER BY id_compra)::integer AS n
        FROM public.compra
    ) AS c
    CROSS JOIN generate_series(1,2) AS s(posicao)
    JOIN (
        SELECT id_produto, preco_venda,
               ROW_NUMBER() OVER (ORDER BY id_produto)::integer AS n
        FROM public.produto
    ) AS p ON p.n=1+(((c.n-1)*2+(s.posicao-1))%600);

    -- O total de cada compra e calculado a partir dos itens inseridos.
    UPDATE public.compra AS c
    SET valor_total=x.total
    FROM (
        SELECT id_compra,
               SUM(quantidade*preco_unitario)::numeric(10,2) AS total
        FROM public.item_compra
        GROUP BY id_compra
    ) AS x
    WHERE c.id_compra=x.id_compra;

    -- Abate as quantidades vendidas do estoque disponivel.
    UPDATE public.produto AS p
    SET quantidade_estoque=p.quantidade_estoque-x.vendida
    FROM (
        SELECT id_produto, SUM(quantidade)::integer AS vendida
        FROM public.item_compra
        GROUP BY id_produto
    ) AS x
    WHERE p.id_produto=x.id_produto;

    -- Validacoes: se algo nao estiver consistente, desfaz-se toda esta execucao.
    IF (SELECT COUNT(*) FROM public.cliente)<>500
       OR (SELECT COUNT(*) FROM public.funcionario)<>500
       OR (SELECT COUNT(*) FROM public.cliente_conta)<>500
       OR (SELECT COUNT(*) FROM public.telefone_cliente)<>800
       OR (SELECT COUNT(*) FROM public.produto)<>600
       OR (SELECT COUNT(*) FROM public.compra)<>1500
       OR (SELECT COUNT(*) FROM public.item_compra)<>3000 THEN
        RAISE EXCEPTION 'Contagem inesperada; insercao cancelada.';
    END IF;

    IF EXISTS (
        SELECT 1 FROM public.compra AS c
        LEFT JOIN (
            SELECT id_compra, SUM(quantidade*preco_unitario) AS total,
                   COUNT(*) AS n_itens
            FROM public.item_compra
            GROUP BY id_compra
        ) AS it ON it.id_compra=c.id_compra
        WHERE it.n_itens<>2 OR it.n_itens IS NULL OR c.valor_total<>it.total
    ) THEN
        RAISE EXCEPTION 'Compra com total inconsistente ou sem exatamente dois itens.';
    END IF;

    IF EXISTS (
        SELECT 1 FROM public.item_compra
        GROUP BY id_compra,id_produto
        HAVING COUNT(*)>1
    ) THEN
        RAISE EXCEPTION 'Produto repetido em uma mesma compra.';
    END IF;

    IF EXISTS (SELECT 1 FROM public.produto WHERE quantidade_estoque<0) THEN
        RAISE EXCEPTION 'Estoque negativo detectado.';
    END IF;
END;
$populacao$;

-- Executar junto com o bloco acima. Exibe a contagem para o print da atividade.
SELECT tabela,registros,minimo,
       CASE WHEN registros>=minimo THEN 'OK' ELSE 'INSUFICIENTE' END AS situacao
FROM (
    SELECT 'cliente' AS tabela,COUNT(*) AS registros,500 AS minimo FROM public.cliente
    UNION ALL SELECT 'cliente_conta',COUNT(*),500 FROM public.cliente_conta
    UNION ALL SELECT 'telefone_cliente',COUNT(*),500 FROM public.telefone_cliente
    UNION ALL SELECT 'funcionario',COUNT(*),500 FROM public.funcionario
    UNION ALL SELECT 'produto',COUNT(*),500 FROM public.produto
    UNION ALL SELECT 'compra',COUNT(*),500 FROM public.compra
    UNION ALL SELECT 'item_compra',COUNT(*),500 FROM public.item_compra
) AS contagem
ORDER BY tabela;
