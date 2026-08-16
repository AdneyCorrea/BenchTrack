-- BenchTrack - permissões para exclusão

-- Ocorrências
revoke all on table public.test_occurrences from authenticated;
grant select, insert, update, delete on table public.test_occurrences to authenticated;

drop policy if exists "test_occurrences_delete_authenticated" on public.test_occurrences;
create policy "test_occurrences_delete_authenticated"
on public.test_occurrences
for delete
to authenticated
using (true);

-- Anexos / metadados
grant select, insert, update, delete on table public.attachments to authenticated;

drop policy if exists "attachments_delete_authenticated" on public.attachments;
create policy "attachments_delete_authenticated"
on public.attachments
for delete
to authenticated
using (true);

-- Workstations
grant select, insert, update, delete on table public.workstations to authenticated;

drop policy if exists "workstations_delete_authenticated" on public.workstations;
create policy "workstations_delete_authenticated"
on public.workstations
for delete
to authenticated
using (true);

-- Storage: bucket privado do BenchTrack
drop policy if exists "benchtrack_files_delete_authenticated" on storage.objects;
create policy "benchtrack_files_delete_authenticated"
on storage.objects
for delete
to authenticated
using (bucket_id = 'benchtrack-files');

notify pgrst, 'reload schema';
