WITH esperadas(tabela) AS (
    VALUES
        ('cliente'), ('telefone_cliente'), ('cliente_conta'),
        ('funcionario'), ('produto'), ('compra'), ('item_compra')
)
SELECT
    e.tabela,
    CASE WHEN t.tablename IS NOT NULL THEN 'EXISTE' ELSE 'AUSENTE' END AS situacao
FROM esperadas e
LEFT JOIN pg_catalog.pg_tables t
    ON t.schemaname = 'public' AND t.tablename = e.tabela
ORDER BY e.tabela;

-- 2. Verificar as colunas: tipo completo, NOT NULL, valor padrao e IDENTITY
SELECT
    c.table_name AS tabela,
    c.ordinal_position AS ordem,
    c.column_name AS coluna,
    CASE
        WHEN c.data_type = 'USER-DEFINED' THEN c.udt_name
        WHEN c.data_type = 'character varying' THEN 'varchar(' || c.character_maximum_length || ')'
        WHEN c.data_type = 'character' THEN 'char(' || c.character_maximum_length || ')'
        WHEN c.data_type = 'numeric' THEN 'numeric(' || c.numeric_precision || ',' || c.numeric_scale || ')'
        ELSE c.data_type
    END AS tipo,
    c.is_nullable AS permite_null,
    c.is_identity AS identidade,
    c.identity_generation AS geracao_identidade,
    c.column_default AS valor_padrao
FROM information_schema.columns c
WHERE c.table_schema = 'public'
  AND c.table_name IN (
      'cliente', 'telefone_cliente', 'cliente_conta',
      'funcionario', 'produto', 'compra', 'item_compra'
  )
ORDER BY c.table_name, c.ordinal_position;

-- 3. Verificar PK, FK, UNIQUE e CHECK, inclusive as referencias e condicoes
SELECT
    tab.relname AS tabela,
    con.conname AS restricao,
    CASE con.contype
        WHEN 'p' THEN 'PRIMARY KEY'
        WHEN 'f' THEN 'FOREIGN KEY'
        WHEN 'u' THEN 'UNIQUE'
        WHEN 'c' THEN 'CHECK'
        ELSE con.contype::text
    END AS tipo,
    pg_get_constraintdef(con.oid, true) AS definicao
FROM pg_constraint con
JOIN pg_class tab ON tab.oid = con.conrelid
JOIN pg_namespace ns ON ns.oid = tab.relnamespace
WHERE ns.nspname = 'public'
  AND tab.relname IN (
      'cliente', 'telefone_cliente', 'cliente_conta',
      'funcionario', 'produto', 'compra', 'item_compra'
  )
  AND con.contype IN ('p', 'f', 'u', 'c')
ORDER BY tab.relname, tipo, con.conname;

-- 4. Verificar especificamente as chaves estrangeiras
SELECT
    tab.relname AS tabela,
    con.conname AS nome_fk,
    pg_get_constraintdef(con.oid, true) AS relacionamento
FROM pg_constraint con
JOIN pg_class tab ON tab.oid = con.conrelid
JOIN pg_namespace ns ON ns.oid = tab.relnamespace
WHERE ns.nspname = 'public'
  AND tab.relname IN (
      'cliente', 'telefone_cliente', 'cliente_conta',
      'funcionario', 'produto', 'compra', 'item_compra'
  )
  AND con.contype = 'f'
ORDER BY tab.relname, con.conname;

-- 5. Conferir a quantidade de registros (antes de popular, normalmente 0)
SELECT 'cliente' AS tabela, COUNT(*) AS registros FROM public.cliente
UNION ALL SELECT 'telefone_cliente', COUNT(*) FROM public.telefone_cliente
UNION ALL SELECT 'cliente_conta', COUNT(*) FROM public.cliente_conta
UNION ALL SELECT 'funcionario', COUNT(*) FROM public.funcionario
UNION ALL SELECT 'produto', COUNT(*) FROM public.produto
UNION ALL SELECT 'compra', COUNT(*) FROM public.compra
UNION ALL SELECT 'item_compra', COUNT(*) FROM public.item_compra
ORDER BY tabela;

-- 6. Verificar se a Row Level Security (RLS) esta habilitada
SELECT
    c.relname AS tabela,
    c.relrowsecurity AS rls_ativada
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname = 'public'
  AND c.relkind = 'r'
  AND c.relname IN (
      'cliente', 'telefone_cliente', 'cliente_conta',
      'funcionario', 'produto', 'compra', 'item_compra'
  )
ORDER BY c.relname;
