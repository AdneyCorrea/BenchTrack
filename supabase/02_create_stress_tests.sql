-- BenchTrack - Testes de stress de 48 horas

create table if not exists public.stress_tests (
  id uuid primary key default gen_random_uuid(),
  workstation_id uuid not null references public.workstations(id) on delete cascade,
  status text not null default 'running'
    check (status in ('running', 'completed')),
  started_at timestamptz not null default now(),
  completed_at timestamptz,
  result text
    check (result is null or result in ('Aprovada', 'Reprovada')),
  notes text,
  created_at timestamptz not null default now()
);

alter table public.stress_tests enable row level security;

grant select, insert, update, delete
on public.stress_tests
to authenticated;

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

-- Uma Workstation pode ter somente um teste ativo por vez.
create unique index if not exists stress_tests_one_running_per_workstation
on public.stress_tests (workstation_id)
where status = 'running';
