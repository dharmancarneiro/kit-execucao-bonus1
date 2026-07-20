-- ============================================================
-- SUPABASE SETUP — Protocolo Anti-Autossabotagem (Bônus 2 · Execução 5.0)
-- Tabela de captura: bonus2_antisabotagem
--
-- SEGURANÇA (leia antes de rodar):
--   * bonus2-antisabotagem.html é PÚBLICO e usa SOMENTE a chave anon.
--   * Política: apenas INSERT para anon. NENHUMA política de SELECT.
--     A chave pública GRAVA mas NÃO LÊ (não vaza nome/e-mail/telefone).
--   * A leitura pro estudo é feita depois, em ambiente privado
--     (dashboard interna / SQL Editor), com a service_role, que
--     ignora RLS. A service_role NUNCA vai no arquivo público.
-- ============================================================

-- 1) Tabela
create table if not exists public.bonus2_antisabotagem (
  id            uuid primary key default gen_random_uuid(),
  created_at    timestamptz not null default now(),
  nome          text,
  email         text,
  telefone      text,
  -- pesquisa de objeções, dores e desejos (7 fechadas + 3 abertas)
  voz_interna     text,   -- 1 objeção/crença
  momento_ataque  text,   -- 2 dor: momento
  sentimento      text,   -- 3 dor: emoção
  frequencia      text,   -- 4 dor: frequência
  maior_duvida    text,   -- 5 objeção: maior dúvida
  medo_futuro     text,   -- 6 dor: medo se nada mudar
  prioridade      text,   -- 7 desejo: o que conquistar primeiro
  tarefa_adiada   text,   -- 8 aberta: tarefa que mais pesa
  custo_doloroso  text,   -- 9 aberta: o que já custou
  dia_livre       text,   -- 10 aberta: um dia livre da autossabotagem
  consentimento boolean not null default false
);

-- Se a tabela já existia (versão captura-leve), adicione as colunas novas:
alter table public.bonus2_antisabotagem
  add column if not exists voz_interna    text,
  add column if not exists momento_ataque text,
  add column if not exists sentimento     text,
  add column if not exists frequencia     text,
  add column if not exists maior_duvida   text,
  add column if not exists medo_futuro    text,
  add column if not exists prioridade     text,
  add column if not exists tarefa_adiada  text,
  add column if not exists custo_doloroso text,
  add column if not exists dia_livre      text;

-- 2) Habilita Row Level Security
alter table public.bonus2_antisabotagem enable row level security;

-- 3) Política de INSERT público (o gate grava aqui)
create policy "insert_publico_b2"
  on public.bonus2_antisabotagem
  for insert
  to anon
  with check (true);

-- 4) NÃO criar política de SELECT.
--    Sem ela, a chave anon grava mas não lê.
--    (A service_role, usada só em ambiente privado, ignora RLS e lê tudo.)

-- Índices úteis
create index if not exists idx_b2_created_at on public.bonus2_antisabotagem (created_at);
create index if not exists idx_b2_email      on public.bonus2_antisabotagem (lower(email));

-- ============================================================
-- QUERIES DO ESTUDO (rodar depois, em ambiente PRIVADO, com a
-- service_role — nunca no arquivo público). Descomente para usar.
-- ============================================================

-- Total de cadastros no Bônus 2
-- select count(*) as total_bonus2 from public.bonus2_antisabotagem;

-- Cadastros por dia
-- select date_trunc('day', created_at)::date as dia, count(*)
-- from public.bonus2_antisabotagem
-- group by 1 order by 1;

-- CRUZAMENTO COM O BÔNUS 1 (tabela alunos_execucao5) --------------------

-- Quem fez os DOIS bônus (Kit + Protocolo) — os mais engajados
-- select b1.nome, b1.email
-- from public.alunos_execucao5 b1
-- join public.bonus2_antisabotagem b2 on lower(b1.email) = lower(b2.email);

-- REENGAJAMENTO: quem fez o Kit (Bônus 1) mas ainda NÃO abriu o Bônus 2
-- (lista pra chamar de volta)
-- select b1.nome, b1.email, b1.whatsapp, b1.created_at
-- from public.alunos_execucao5 b1
-- where not exists (
--   select 1 from public.bonus2_antisabotagem b2
--   where lower(b2.email) = lower(b1.email)
-- )
-- order by b1.created_at desc;

-- Quem abriu o Bônus 2 mas NÃO consta no Kit (entraram por outro caminho)
-- select b2.nome, b2.email, b2.telefone
-- from public.bonus2_antisabotagem b2
-- where not exists (
--   select 1 from public.alunos_execucao5 b1
--   where lower(b1.email) = lower(b2.email)
-- );

-- CONSOLIDAÇÃO COMPLETA DO ICP (demografia do B1 + psicográfico do B2)
-- Perfil unificado por pessoa, juntando as duas pesquisas pelo e-mail.
-- select
--   b2.nome, b2.email, b2.telefone,
--   -- Bônus 1 (quem é): demografia e comportamento
--   b1.profissao, b1.renda, b1.idade, b1.mais_procrastina, b1.motivo,
--   b1.tempo_procrastinacao, b1.custo_procrastinacao,
--   b1.decisao_entrada, b1.tentativas_anteriores, b1.desejo_12m,
--   -- Bônus 2 (por que trava): objeções, dores e desejos
--   b2.voz_interna, b2.momento_ataque, b2.sentimento, b2.frequencia,
--   b2.maior_duvida, b2.medo_futuro, b2.prioridade,
--   b2.tarefa_adiada, b2.custo_doloroso, b2.dia_livre
-- from public.bonus2_antisabotagem b2
-- left join public.alunos_execucao5 b1 on lower(b1.email) = lower(b2.email)
-- order by b2.created_at desc;

-- Rankings psicográficos (objeções/dores/desejos do B2)
-- select voz_interna,   count(*) from public.bonus2_antisabotagem group by 1 order by 2 desc;
-- select sentimento,    count(*) from public.bonus2_antisabotagem group by 1 order by 2 desc;
-- select maior_duvida,  count(*) from public.bonus2_antisabotagem group by 1 order by 2 desc;
-- select medo_futuro,   count(*) from public.bonus2_antisabotagem group by 1 order by 2 desc;
-- select prioridade,    count(*) from public.bonus2_antisabotagem group by 1 order by 2 desc;

-- ============================================================
-- Checagem de e-mail já respondido (para o gate do Bônus 2)
-- ------------------------------------------------------------
-- A tabela NÃO tem política de SELECT (privacidade). Esta função
-- roda como security definer só pra devolver um true/false — ela
-- nunca expõe dado nenhum, só responde "esse e-mail já respondeu?".
-- Sem ela, o gate simplesmente manda todo mundo pra pesquisa.
-- ============================================================
create or replace function public.bonus2_pesquisa_feita(p_email text)
returns boolean
language sql stable security definer set search_path = public
as $$
  select exists(
    select 1 from public.bonus2_antisabotagem
    where lower(email) = lower(trim(p_email))
  )
$$;
revoke all on function public.bonus2_pesquisa_feita(text) from public;
grant execute on function public.bonus2_pesquisa_feita(text) to anon;

-- ============================================================
-- CAMADAS DE SEGURANÇA (auditado e aplicado em 20/07/2026)
-- ------------------------------------------------------------
-- Verificado com a chave PÚBLICA contra a API real:
--   SELECT  -> devolve [] (RLS bloqueia leitura)
--   PATCH   -> não altera nada
--   DELETE  -> não apaga nada
-- Ou seja: a base de clientes NÃO é legível por quem tem a chave
-- do site. Só a service_role (painel local) enxerga os dados.
--
-- Abaixo, as travas contra ABUSO de escrita (a única coisa que a
-- chave pública pode fazer: inserir).
-- ============================================================

-- Limite de tamanho: sem isso, qualquer um despeja megabytes na tabela
alter table public.bonus2_antisabotagem drop constraint if exists b2_limites;
alter table public.bonus2_antisabotagem add constraint b2_limites check (
  length(nome) between 1 and 120
  and length(email) between 5 and 200
  and length(coalesce(telefone,'')) <= 30
  and length(coalesce(tarefa_adiada,'')) <= 2000
  and length(coalesce(custo_doloroso,'')) <= 2000
  and length(coalesce(dia_livre,'')) <= 2000
  and length(coalesce(voz_interna,'')) <= 200
  and length(coalesce(momento_ataque,'')) <= 200
  and length(coalesce(sentimento,'')) <= 200
  and length(coalesce(frequencia,'')) <= 200
  and length(coalesce(maior_duvida,'')) <= 200
  and length(coalesce(medo_futuro,'')) <= 200
  and length(coalesce(prioridade,'')) <= 200
) not valid;

-- E-mail precisa ter cara de e-mail
alter table public.bonus2_antisabotagem drop constraint if exists b2_email_formato;
alter table public.bonus2_antisabotagem add constraint b2_email_formato
  check (email ~ '^[^@[:space:]]+@[^@[:space:]]+[.][^@[:space:]]+$') not valid;

-- Mesmas travas no Bônus 1
alter table public.alunos_execucao5 drop constraint if exists b1_limites;
alter table public.alunos_execucao5 add constraint b1_limites check (
  length(nome) between 1 and 120 and length(email) between 5 and 200
) not valid;
alter table public.alunos_execucao5 drop constraint if exists b1_email_formato;
alter table public.alunos_execucao5 add constraint b1_email_formato
  check (email ~ '^[^@[:space:]]+@[^@[:space:]]+[.][^@[:space:]]+$') not valid;

-- RISCO CONHECIDO E ACEITO: bonus2_pesquisa_feita permite descobrir
-- se um e-mail específico está na base (enumeração). É o preço do
-- "já respondeu, entra direto". Só revela sim/não, nunca dados.
