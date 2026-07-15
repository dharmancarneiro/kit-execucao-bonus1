-- ============================================================
-- SUPABASE SETUP — Kit de Execução Imediata (Bônus 1 · Execução 5.0)
-- Tabela de pesquisa: alunos_execucao5
--
-- SEGURANÇA (leia antes de rodar):
--   * O arquivo kit-execucao-imediata.html é PÚBLICO (até 5.000
--     alunos carregam no navegador) e usa SOMENTE a chave anon.
--   * Por isso, a política aqui é: INSERT e UPDATE permitidos
--     para o papel anon, e NENHUMA política de SELECT.
--     Resultado: a chave pública consegue GRAVAR, mas NÃO
--     consegue LER a tabela (nem listar e-mails/WhatsApp).
--   * A LEITURA dos dados para o estudo NÃO acontece no HTML.
--     Ela é feita depois, em ambiente privado (dashboard
--     interna / SQL Editor do Supabase), usando a service_role,
--     que ignora RLS. A service_role NUNCA vai no arquivo público.
-- ============================================================

-- 1) Tabela
create table if not exists public.alunos_execucao5 (
  id                 uuid primary key default gen_random_uuid(),
  created_at         timestamptz not null default now(),
  nome               text,
  email              text,
  whatsapp           text,
  profissao          text,
  mais_procrastina   text,
  motivo             text,
  -- tag de participação: todo cadastro deste kit entra como 'bonus1_kit_execucao'
  tag                text not null default 'bonus1_kit_execucao',
  progresso_48h      int not null default 0,
  tarefa_clarificada text,
  consentimento      boolean not null default false
);

-- 2) Habilita Row Level Security
alter table public.alunos_execucao5 enable row level security;

-- 3) Política de INSERT público (o gate de cadastro grava aqui)
create policy "insert_publico"
  on public.alunos_execucao5
  for insert
  to anon
  with check (true);

-- 4) Política de UPDATE (o PATCH de progresso atualiza a própria linha
--    pelo id guardado no navegador do aluno; sem SELECT, o anon não
--    consegue enumerar ids de outras pessoas)
create policy "update_progresso"
  on public.alunos_execucao5
  for update
  to anon
  using (true)
  with check (true);

-- 5) Importante: sem política de SELECT, o INSERT não pode usar
--    "Prefer: return=representation" (o RETURNING exige SELECT).
--    Por isso o HTML gera o uuid no navegador e insere com
--    "Prefer: return=minimal".
--
-- 6) NÃO criar política de SELECT.
--    Sem ela, a chave anon não lê nada — nem via REST, nem via JS.
--    (A service_role, usada só em ambiente privado, ignora RLS e lê tudo.)

-- Índices úteis para as análises do estudo
create index if not exists idx_alunos_exec5_created_at on public.alunos_execucao5 (created_at);
create index if not exists idx_alunos_exec5_motivo     on public.alunos_execucao5 (motivo);

-- ============================================================
-- QUERIES DO ESTUDO (rodar depois, em ambiente PRIVADO, com a
-- service_role — nunca no arquivo público). Descomente para usar.
-- ============================================================

-- Total de cadastros
-- select count(*) as total_cadastros from public.alunos_execucao5;

-- Quem participou do Bônus 1 (para exportar/tagar no seu CRM ou e-mail)
-- select nome, email, whatsapp, created_at
-- from public.alunos_execucao5
-- where tag = 'bonus1_kit_execucao'
-- order by created_at desc;

-- Ranking: o que as pessoas mais procrastinam
-- select mais_procrastina, count(*) as total
-- from public.alunos_execucao5
-- group by mais_procrastina
-- order by total desc;

-- Ranking: motivos de não fazer
-- select motivo, count(*) as total
-- from public.alunos_execucao5
-- group by motivo
-- order by total desc;

-- Cruzamento: profissão × motivo
-- select profissao, motivo, count(*) as total
-- from public.alunos_execucao5
-- group by profissao, motivo
-- order by profissao, total desc;

-- Funil de engajamento na Missão 48h
-- (0 = não começou · 1–10 = em andamento · 11 = concluiu)
-- select
--   case
--     when progresso_48h = 0  then '1. Não começaram'
--     when progresso_48h < 11 then '2. Em andamento'
--     else                         '3. Concluíram'
--   end as etapa,
--   count(*) as alunos
-- from public.alunos_execucao5
-- group by 1
-- order by 1;
