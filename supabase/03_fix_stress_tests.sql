-- BenchTrack: corrigir exposição Data API + alinhar o schema de stress_tests
-- Execute este arquivo UMA VEZ no Supabase SQL Editor.

-- 1) A role autenticada precisa enxergar o schema e a tabela pela Data API.
grant usage on schema public to authenticated;
grant select, insert, update, delete
on table public.stress_tests
to authenticated;

-- 2) Se a tabela ainda estiver com os nomes antigos da primeira versão,
-- alinhe para os nomes usados pelo aplicativo.
do $$
begin
  if exists (
    select 1 from information_schema.columns
    where table_schema = 'public'
      and table_name = 'stress_tests'
      and column_name = 'completed_at'
  ) and not exists (
    select 1 from information_schema.columns
    where table_schema = 'public'
      and table_name = 'stress_tests'
      and column_name = 'finished_at'
  ) then
    alter table public.stress_tests
      rename column completed_at to finished_at;
  end if;

  if exists (
    select 1 from information_schema.columns
    where table_schema = 'public'
      and table_name = 'stress_tests'
      and column_name = 'notes'
  ) and not exists (
    select 1 from information_schema.columns
    where table_schema = 'public'
      and table_name = 'stress_tests'
      and column_name = 'observacoes'
  ) then
    alter table public.stress_tests
      rename column notes to observacoes;
  end if;
end $$;

-- 3) Garante as colunas usadas pelo aplicativo.
alter table public.stress_tests
  add column if not exists finished_at timestamptz,
  add column if not exists observacoes text;

-- 4) Padroniza os status para o aplicativo.
do $$
declare
  c record;
begin
  for c in
    select conname
    from pg_constraint
    where conrelid = 'public.stress_tests'::regclass
      and contype = 'c'
      and pg_get_constraintdef(oid) ilike '%status%'
  loop
    execute format(
      'alter table public.stress_tests drop constraint if exists %I',
      c.conname
    );
  end loop;
end $$;

update public.stress_tests
set status = 'Em andamento'
where status = 'running';

update public.stress_tests
set status = 'Finalizado'
where status = 'completed';

alter table public.stress_tests
  add constraint stress_tests_status_check
  check (
    status in (
      'Em andamento',
      'Finalizado',
      'Cancelado'
    )
  );

-- 5) Resultado permitido.
do $$
declare
  c record;
begin
  for c in
    select conname
    from pg_constraint
    where conrelid = 'public.stress_tests'::regclass
      and contype = 'c'
      and pg_get_constraintdef(oid) ilike '%result%'
  loop
    execute format(
      'alter table public.stress_tests drop constraint if exists %I',
      c.conname
    );
  end loop;
end $$;

alter table public.stress_tests
  add constraint stress_tests_result_check
  check (
    result is null
    or result in ('Aprovada', 'Reprovada')
  );

-- 6) Uma Workstation só pode ter um teste ativo.
create unique index if not exists stress_tests_one_running_per_workstation
on public.stress_tests (workstation_id)
where status = 'Em andamento';

-- 7) Recria RLS/policies para garantir o acesso correto.
alter table public.stress_tests enable row level security;

drop policy if exists "stress_tests_select_authenticated"
on public.stress_tests;
create policy "stress_tests_select_authenticated"
on public.stress_tests
for select
 to authenticated
using (true);

drop policy if exists "stress_tests_insert_authenticated"
on public.stress_tests;
create policy "stress_tests_insert_authenticated"
on public.stress_tests
for insert
 to authenticated
with check (true);

drop policy if exists "stress_tests_update_authenticated"
on public.stress_tests;
create policy "stress_tests_update_authenticated"
on public.stress_tests
for update
 to authenticated
using (true)
with check (true);

drop policy if exists "stress_tests_delete_authenticated"
on public.stress_tests;
create policy "stress_tests_delete_authenticated"
on public.stress_tests
for delete
 to authenticated
using (true);

-- 8) Recarrega o schema cache do PostgREST.
notify pgrst, 'reload schema';
