


-- 1. CREATE: inserir um cliente ficticio de demonstracao

INSERT INTO public.cliente
    (nome, email, logradouro, cep, numero, estado, complemento, bairro)
SELECT
    'Cliente Demonstracao CRUD',
    'crud-demonstracao-2026@exemplo.test',
    'Rua Exemplo Academico',
    '14400-000',
    '100',
    'SP',
    NULL,
    'Centro'
WHERE NOT EXISTS (
    SELECT 1
    FROM public.cliente
    WHERE email = 'crud-demonstracao-2026@exemplo.test'
)
RETURNING id_cliente, nome, email, logradouro, cep, numero, estado, bairro;


-- 2. READ: consultar o cliente de demonstracao

SELECT id_cliente, nome, email, logradouro, cep, numero, estado, bairro
FROM public.cliente
WHERE email = 'crud-demonstracao-2026@exemplo.test'
ORDER BY id_cliente;

-- 3. UPDATE: alterar o endereco do cliente de demonstracao

UPDATE public.cliente
SET logradouro = 'Avenida Modelo Relacional',
    numero = '250',
    bairro = 'Jardim Teste'
WHERE email = 'crud-demonstracao-2026@exemplo.test'
  AND nome = 'Cliente Demonstracao CRUD'
RETURNING id_cliente, nome, email, logradouro, numero, bairro;


-- 4. DELETE: excluir SOMENTE o cliente de demonstracao

DELETE FROM public.cliente
WHERE email = 'crud-demonstracao-2026@exemplo.test'
  AND nome = 'Cliente Demonstracao CRUD'
RETURNING id_cliente, nome, email;


-- 5. CONFERENCIA OPCIONAL: executar APOS o DELETE

SELECT
    (SELECT COUNT(*)
     FROM public.cliente
     WHERE email = 'crud-demonstracao-2026@exemplo.test') AS cliente_teste_restante,
    (SELECT COUNT(*) FROM public.cliente) AS total_clientes;
