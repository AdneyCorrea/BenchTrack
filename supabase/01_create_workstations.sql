create extension if not exists pgcrypto;

create table if not exists public.workstations (
  id uuid primary key default gen_random_uuid(),
  codigo text not null unique,
  pedido text,
  responsavel text not null,
  processador text not null,
  placa_mae text not null,
  memoria_ram text not null,
  placa_video text not null,
  armazenamento text not null,
  fonte text not null,
  cooler text,
  sistema_operacional text,
  observacoes text,
  status text not null default 'Montagem' check (status in ('Montagem','Aguardando teste','Teste 48h','Aprovada','Reprovada')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.workstations enable row level security;

drop policy if exists 'workstations_select_authenticated' on public.workstations;
create policy 'workstations_select_authenticated' on public.workstations for select to authenticated using (true);

drop policy if exists 'workstations_insert_authenticated' on public.workstations;
create policy 'workstations_insert_authenticated' on public.workstations for insert to authenticated with check (true);

drop policy if exists 'workstations_update_authenticated' on public.workstations;
create policy 'workstations_update_authenticated' on public.workstations for update to authenticated using (true) with check (true);

create or replace function public.set_updated_at() returns trigger language plpgsql as $$ begin new.updated_at = now(); return new; end; $$;

drop trigger if exists workstations_set_updated_at on public.workstations;
create trigger workstations_set_updated_at before update on public.workstations for each row execute function public.set_updated_at();
