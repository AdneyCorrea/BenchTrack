-- BenchTrack: ocorrências durante os testes de 48h
-- Execute este arquivo UMA VEZ no Supabase SQL Editor.

create table if not exists public.test_occurrences (
  id uuid primary key default gen_random_uuid(),

  stress_test_id uuid not null
    references public.stress_tests(id)
    on delete cascade,

  workstation_id uuid not null
    references public.workstations(id)
    on delete cascade,

  tipo text not null,
  descricao text not null,

  user_id uuid references auth.users(id)
    on delete set null,

  created_at timestamptz not null default now()
);

alter table public.test_occurrences
  enable row level security;

grant usage on schema public to authenticated;
grant select, insert, update, delete
on table public.test_occurrences
to authenticated;

drop policy if exists "test_occurrences_select_authenticated"
on public.test_occurrences;
create policy "test_occurrences_select_authenticated"
on public.test_occurrences
for select
to authenticated
using (true);

drop policy if exists "test_occurrences_insert_authenticated"
on public.test_occurrences;
create policy "test_occurrences_insert_authenticated"
on public.test_occurrences
for insert
to authenticated
with check (true);

drop policy if exists "test_occurrences_update_authenticated"
on public.test_occurrences;
create policy "test_occurrences_update_authenticated"
on public.test_occurrences
for update
to authenticated
using (true)
with check (true);

drop policy if exists "test_occurrences_delete_authenticated"
on public.test_occurrences;
create policy "test_occurrences_delete_authenticated"
on public.test_occurrences
for delete
to authenticated
using (true);

create index if not exists test_occurrences_test_id_created_at_idx
on public.test_occurrences (stress_test_id, created_at desc);

notify pgrst, 'reload schema';
