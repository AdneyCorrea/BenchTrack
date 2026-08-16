-- =========================================================
-- BENCHTRACK - Arquivos e anexos
-- =========================================================

create table if not exists public.attachments (
  id uuid primary key default gen_random_uuid(),

  workstation_id uuid not null
    references public.workstations(id)
    on delete cascade,

  stress_test_id uuid
    references public.stress_tests(id)
    on delete cascade,

  occurrence_id uuid
    references public.test_occurrences(id)
    on delete cascade,

  file_name text not null,
  storage_path text not null unique,
  mime_type text,
  size_bytes bigint,

  uploaded_by uuid
    references auth.users(id)
    on delete set null,

  created_at timestamptz not null default now()
);

create index if not exists attachments_workstation_idx
  on public.attachments(workstation_id);

create index if not exists attachments_stress_test_idx
  on public.attachments(stress_test_id);

create index if not exists attachments_occurrence_idx
  on public.attachments(occurrence_id);

alter table public.attachments
  enable row level security;

grant select, insert, delete
on public.attachments
 to authenticated;

drop policy if exists "attachments_select_authenticated"
  on public.attachments;

create policy "attachments_select_authenticated"
  on public.attachments
  for select
  to authenticated
  using (true);

drop policy if exists "attachments_insert_authenticated"
  on public.attachments;

create policy "attachments_insert_authenticated"
  on public.attachments
  for insert
  to authenticated
  with check (uploaded_by = auth.uid());

drop policy if exists "attachments_delete_authenticated"
  on public.attachments;

create policy "attachments_delete_authenticated"
  on public.attachments
  for delete
  to authenticated
  using (uploaded_by = auth.uid());

-- Private bucket. Files are never publicly reachable by URL.
insert into storage.buckets (id, name, public)
values ('benchtrack-files', 'benchtrack-files', false)
on conflict (id) do update set public = false;

-- Users can upload only into their own top-level folder (auth.uid()).
drop policy if exists "benchtrack_files_insert_authenticated"
  on storage.objects;

create policy "benchtrack_files_insert_authenticated"
  on storage.objects
  for insert
  to authenticated
  with check (
    bucket_id = 'benchtrack-files'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

-- Users can read files from this bucket.
drop policy if exists "benchtrack_files_select_authenticated"
  on storage.objects;

create policy "benchtrack_files_select_authenticated"
  on storage.objects
  for select
  to authenticated
  using (
    bucket_id = 'benchtrack-files'
  );

-- Users can delete only files stored under their own folder.
drop policy if exists "benchtrack_files_delete_authenticated"
  on storage.objects;

create policy "benchtrack_files_delete_authenticated"
  on storage.objects
  for delete
  to authenticated
  using (
    bucket_id = 'benchtrack-files'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

notify pgrst, 'reload schema';
