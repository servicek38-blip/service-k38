create extension if not exists "pgcrypto";

create table if not exists public.app_users (
  id uuid primary key,
  email text unique,
  username text,
  role text default 'user',
  blocked boolean default false,
  last_login timestamptz,
  created_at timestamptz default now()
);

create table if not exists public.materiali (
  id uuid primary key default gen_random_uuid(),
  local_id text unique,
  codice_inventario text,
  nome text not null,
  categoria text,
  sottocategoria text,
  marca text,
  modello text,
  seriale text,
  quantita numeric default 1,
  posizione text,
  stato text default 'Disponibile',
  prezzo_listino numeric default 0,
  prezzo_reale numeric default 0,
  prezzo_noleggio numeric default 0,
  foto_url text,
  note text,
  created_at timestamptz default now()
);

create table if not exists public.preventivi (
  id uuid primary key default gen_random_uuid(),
  local_id text unique,
  cliente text,
  evento text,
  data_evento date,
  luogo text,
  audio numeric default 0,
  luci numeric default 0,
  video numeric default 0,
  trasporto numeric default 0,
  ore_tecnico numeric default 0,
  tariffa_tecnico numeric default 0,
  montaggio numeric default 0,
  sconto numeric default 0,
  iva numeric default 0,
  note text,
  totale numeric default 0,
  accettato boolean default false,
  evento_id uuid,
  created_at timestamptz default now()
);

create table if not exists public.eventi (
  id uuid primary key default gen_random_uuid(),
  local_id text unique,
  titolo text not null,
  cliente text,
  data_evento date,
  luogo text,
  stato text default 'Richiesta',
  preventivo_id uuid,
  materiali jsonb default '[]'::jsonb,
  note text,
  totale numeric default 0,
  created_at timestamptz default now()
);

alter table public.app_users enable row level security;
alter table public.materiali enable row level security;
alter table public.preventivi enable row level security;
alter table public.eventi enable row level security;

drop policy if exists app_users_read on public.app_users;
create policy app_users_read on public.app_users for select using (auth.uid() is not null);

drop policy if exists app_users_insert_self on public.app_users;
create policy app_users_insert_self on public.app_users for insert with check (auth.uid() = id);

drop policy if exists app_users_update_admin_or_self on public.app_users;
create policy app_users_update_admin_or_self on public.app_users
for update using (
  auth.uid() = id
  or exists (select 1 from public.app_users u where u.id = auth.uid() and u.role = 'admin')
);

drop policy if exists materiali_shared on public.materiali;
create policy materiali_shared on public.materiali for all using (auth.uid() is not null) with check (auth.uid() is not null);

drop policy if exists preventivi_shared on public.preventivi;
create policy preventivi_shared on public.preventivi for all using (auth.uid() is not null) with check (auth.uid() is not null);

drop policy if exists eventi_shared on public.eventi;
create policy eventi_shared on public.eventi for all using (auth.uid() is not null) with check (auth.uid() is not null);

insert into storage.buckets (id, name, public)
values ('foto-materiali', 'foto-materiali', true)
on conflict (id) do nothing;

drop policy if exists foto_materiali_upload on storage.objects;
create policy foto_materiali_upload on storage.objects
for insert with check (bucket_id = 'foto-materiali' and auth.uid() is not null);

drop policy if exists foto_materiali_read on storage.objects;
create policy foto_materiali_read on storage.objects
for select using (bucket_id = 'foto-materiali');

drop policy if exists foto_materiali_delete on storage.objects;
create policy foto_materiali_delete on storage.objects
for delete using (bucket_id = 'foto-materiali' and auth.uid() is not null);

-- DOPO IL PRIMO LOGIN, SE VUOI FORZARE ADMIN:
-- update public.app_users set role='admin' where email='servicek38@gmail.com';

-- AGGIORNAMENTO PER DATABASE GIÀ ESISTENTE
alter table public.materiali add column if not exists codice_inventario text;



-- MIGRAZIONI SICURE PER DATABASE GIÀ ESISTENTE
alter table public.materiali add column if not exists local_id text unique;
alter table public.materiali add column if not exists codice_inventario text;
alter table public.materiali add column if not exists prezzo_listino numeric default 0;
alter table public.materiali add column if not exists prezzo_reale numeric default 0;
alter table public.materiali add column if not exists prezzo_noleggio numeric default 0;

alter table public.preventivi add column if not exists local_id text unique;
alter table public.preventivi add column if not exists accettato boolean default false;
alter table public.preventivi add column if not exists evento_id uuid;

alter table public.eventi add column if not exists local_id text unique;
alter table public.eventi add column if not exists preventivo_id uuid;
alter table public.eventi add column if not exists totale numeric default 0;


-- MIGRAZIONI BUGFIX CALENDARIO
alter table public.preventivi add column if not exists accettato boolean default false;
alter table public.preventivi add column if not exists evento_id uuid;
alter table public.eventi add column if not exists preventivo_id uuid;
alter table public.eventi add column if not exists totale numeric default 0;


-- MIGRAZIONI FIX EVENTI MANUALI
alter table public.eventi add column if not exists local_id text unique;
alter table public.eventi add column if not exists preventivo_id uuid;
alter table public.eventi add column if not exists totale numeric default 0;
alter table public.preventivi add column if not exists accettato boolean default false;
alter table public.preventivi add column if not exists evento_id uuid;


-- FIX UNIQUE LOCAL_ID PER UPSERT
create unique index if not exists materiali_local_id_unique_idx on public.materiali(local_id);
create unique index if not exists preventivi_local_id_unique_idx on public.preventivi(local_id);
create unique index if not exists eventi_local_id_unique_idx on public.eventi(local_id);


-- SYNC REALE MULTI DEVICE
alter table public.eventi add column if not exists local_id text;
alter table public.preventivi add column if not exists local_id text;
alter table public.materiali add column if not exists local_id text;
notify pgrst, 'reload schema';


-- FIX CATEGORIE/SOTTOCATEGORIE
alter table public.materiali add column if not exists sottocategoria text;
notify pgrst, 'reload schema';


-- SERVICE OPERATIVO EVENTI MATERIALI CHECKLIST
alter table public.eventi add column if not exists referente text;
alter table public.eventi add column if not exists telefono_referente text;
alter table public.eventi add column if not exists tecnico text;
alter table public.eventi add column if not exists ora_montaggio text;
alter table public.eventi add column if not exists ora_smontaggio text;
alter table public.eventi add column if not exists materiali jsonb default '[]'::jsonb;
alter table public.eventi add column if not exists checklist jsonb default '{}'::jsonb;

alter table public.preventivi add column if not exists referente text;
alter table public.preventivi add column if not exists telefono_referente text;

notify pgrst, 'reload schema';


-- FINANZA ARCHIVIO PROGRESSIVI PREVENTIVI
alter table public.preventivi add column if not exists numero_preventivo text;
alter table public.preventivi add column if not exists stato_pagamento text default 'Da saldare';
alter table public.preventivi add column if not exists importo_incassato numeric default 0;
alter table public.preventivi add column if not exists data_pagamento date;
alter table public.preventivi add column if not exists archiviato boolean default false;

alter table public.eventi add column if not exists numero_preventivo text;
alter table public.eventi add column if not exists stato_pagamento text default 'Da saldare';
alter table public.eventi add column if not exists importo_incassato numeric default 0;
alter table public.eventi add column if not exists data_pagamento date;

notify pgrst, 'reload schema';



-- BLOCCO PROFESSIONALE COMPLETO: FINANZA / ARCHIVIO / PROGRESSIVI / EVENTI COMPLETI
alter table public.preventivi add column if not exists numero_preventivo text;
alter table public.preventivi add column if not exists stato_pagamento text default 'Da saldare';
alter table public.preventivi add column if not exists importo_incassato numeric default 0;
alter table public.preventivi add column if not exists data_pagamento date;
alter table public.preventivi add column if not exists archiviato boolean default false;
alter table public.preventivi add column if not exists referente text;
alter table public.preventivi add column if not exists telefono_referente text;
alter table public.preventivi add column if not exists materiali jsonb default '[]'::jsonb;
alter table public.preventivi add column if not exists checklist jsonb default '{}'::jsonb;

alter table public.eventi add column if not exists numero_preventivo text;
alter table public.eventi add column if not exists stato_pagamento text default 'Da saldare';
alter table public.eventi add column if not exists importo_incassato numeric default 0;
alter table public.eventi add column if not exists data_pagamento date;
alter table public.eventi add column if not exists referente text;
alter table public.eventi add column if not exists telefono_referente text;
alter table public.eventi add column if not exists tecnico text;
alter table public.eventi add column if not exists materiali jsonb default '[]'::jsonb;
alter table public.eventi add column if not exists checklist jsonb default '{}'::jsonb;

notify pgrst, 'reload schema';

alter table public.preventivi add column if not exists data_fine_evento date;
alter table public.eventi add column if not exists data_fine_evento date;
notify pgrst, 'reload schema';

-- FIRMA CLIENTE PREVENTIVI
alter table public.preventivi add column if not exists firma_cliente text;
alter table public.preventivi add column if not exists firmato boolean default false;
notify pgrst, 'reload schema';

-- MEZZO E CALCOLO TRASPORTO
alter table public.preventivi add column if not exists mezzo_trasporto text;
alter table public.preventivi add column if not exists mezzo_custom text;
alter table public.preventivi add column if not exists km_trasporto numeric default 0;
alter table public.preventivi add column if not exists costo_km numeric default 0;

alter table public.eventi add column if not exists mezzo_trasporto text;
alter table public.eventi add column if not exists mezzo_custom text;
alter table public.eventi add column if not exists km_trasporto numeric default 0;
alter table public.eventi add column if not exists costo_km numeric default 0;

notify pgrst, 'reload schema';

-- MEZZI MULTIPLI TRASPORTO
alter table public.preventivi add column if not exists mezzi_trasporto jsonb default '[]'::jsonb;
alter table public.eventi add column if not exists mezzi_trasporto jsonb default '[]'::jsonb;
notify pgrst, 'reload schema';

-- UPDATE OPERATIVO PRO
alter table public.preventivi add column if not exists contratto_generato boolean default false;
alter table public.preventivi add column if not exists note_cliente text;

alter table public.eventi add column if not exists contratto_generato boolean default false;
alter table public.eventi add column if not exists note_cliente text;

notify pgrst, 'reload schema';
