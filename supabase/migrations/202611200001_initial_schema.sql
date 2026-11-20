
-- Il Portale del Giostraio — schema iniziale Supabase
-- Eseguire in un progetto nuovo. Rivedere le policy prima della produzione.

create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  phone text unique not null,
  display_name text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.categories (
  id bigint generated always as identity primary key,
  name text not null unique,
  subcategories text[] not null default '{}',
  sort_order int not null default 0,
  is_active boolean not null default true
);

insert into public.categories(name, subcategories, sort_order) values
('Abitazioni', array['Campine e carovane','Camper','Case mobili','Altre abitazioni'],1),
('Giostre', array['Piccole','Medie','Grandi','Altre attrazioni'],2),
('Attrezzature', array['Attrezzature','Ricambi','Impianti','Accessori'],3)
on conflict(name) do nothing;

create table if not exists public.listings (
  id uuid primary key default gen_random_uuid(),
  seller_id uuid not null references public.profiles(id) on delete cascade,
  category_id bigint not null references public.categories(id),
  subcategory text not null,
  title text not null check (char_length(title) between 5 and 100),
  description text not null check (char_length(description) between 10 and 10000),
  price_eur numeric(12,2) not null check (price_eur > 0),
  status text not null default 'active' check (status in ('active','sold','archived')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists listings_public_feed on public.listings(status, created_at desc);
create index if not exists listings_seller on public.listings(seller_id, status);

create table if not exists public.listing_images (
  id uuid primary key default gen_random_uuid(),
  listing_id uuid not null references public.listings(id) on delete cascade,
  storage_path text not null,
  sort_order int not null default 0,
  created_at timestamptz not null default now()
);

create table if not exists public.wanted_posts (
  id uuid primary key default gen_random_uuid(),
  author_id uuid not null references public.profiles(id) on delete cascade,
  body text not null check (char_length(body) between 5 and 5000),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.conversations (
  id uuid primary key default gen_random_uuid(),
  listing_id uuid references public.listings(id) on delete set null,
  wanted_post_id uuid references public.wanted_posts(id) on delete set null,
  created_at timestamptz not null default now(),
  check (listing_id is not null or wanted_post_id is not null)
);

create table if not exists public.conversation_members (
  conversation_id uuid not null references public.conversations(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  joined_at timestamptz not null default now(),
  primary key(conversation_id,user_id)
);

create table if not exists public.messages (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references public.conversations(id) on delete cascade,
  sender_id uuid not null references public.profiles(id) on delete cascade,
  body text not null check (char_length(body) between 1 and 5000),
  created_at timestamptz not null default now(),
  read_at timestamptz
);
create index if not exists messages_conversation_time on public.messages(conversation_id, created_at);

create table if not exists public.favorites (
  user_id uuid not null references public.profiles(id) on delete cascade,
  listing_id uuid not null references public.listings(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key(user_id, listing_id)
);

create table if not exists public.reports (
  id uuid primary key default gen_random_uuid(),
  reporter_id uuid not null references public.profiles(id) on delete cascade,
  listing_id uuid references public.listings(id) on delete cascade,
  wanted_post_id uuid references public.wanted_posts(id) on delete cascade,
  reason text not null check (char_length(reason) between 5 and 2000),
  status text not null default 'open' check (status in ('open','reviewing','closed')),
  created_at timestamptz not null default now(),
  check (listing_id is not null or wanted_post_id is not null)
);

-- Profilo creato automaticamente al completamento dell'iscrizione con telefono.
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public
as $$
begin
  insert into public.profiles(id, phone)
  values (new.id, coalesce(new.phone, new.raw_user_meta_data->>'phone'))
  on conflict (id) do update set phone = excluded.phone;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created_profile on auth.users;
create trigger on_auth_user_created_profile
after insert on auth.users
for each row execute procedure public.handle_new_user();

-- Impone il limite di quattro annunci attivi anche con richieste concorrenti.
create or replace function public.enforce_four_active_listings()
returns trigger language plpgsql security definer set search_path = public
as $$
declare active_count integer;
begin
  if new.status = 'active' then
    perform pg_advisory_xact_lock(hashtextextended(new.seller_id::text, 0));
    select count(*) into active_count
      from public.listings
      where seller_id = new.seller_id
        and status = 'active'
        and id <> coalesce(new.id, '00000000-0000-0000-0000-000000000000'::uuid);
    if active_count >= 4 then
      raise exception 'Limite massimo di 4 annunci attivi raggiunto';
    end if;
  end if;
  return new;
end;
$$;
drop trigger if exists listings_four_active_limit on public.listings;
create trigger listings_four_active_limit
before insert or update of status, seller_id on public.listings
for each row execute procedure public.enforce_four_active_listings();

-- RLS
alter table public.profiles enable row level security;
alter table public.categories enable row level security;
alter table public.listings enable row level security;
alter table public.listing_images enable row level security;
alter table public.wanted_posts enable row level security;
alter table public.conversations enable row level security;
alter table public.conversation_members enable row level security;
alter table public.messages enable row level security;
alter table public.favorites enable row level security;
alter table public.reports enable row level security;

-- Il numero di cellulare è dato personale: ogni utente può leggere solo il proprio profilo.
create policy "users read own profile" on public.profiles
for select to authenticated using (id = auth.uid());
create policy "users update own profile" on public.profiles
for update to authenticated using (id = auth.uid()) with check (id = auth.uid());

create policy "active categories public read" on public.categories
for select using (is_active = true);

create policy "active listings public read" on public.listings
for select using (status = 'active' or seller_id = auth.uid());
create policy "seller creates own listing" on public.listings
for insert to authenticated with check (seller_id = auth.uid());
create policy "seller updates own listing" on public.listings
for update to authenticated using (seller_id = auth.uid()) with check (seller_id = auth.uid());
create policy "seller deletes own listing" on public.listings
for delete to authenticated using (seller_id = auth.uid());

create policy "listing images public read for active listings" on public.listing_images
for select using (exists(select 1 from public.listings l where l.id=listing_id and (l.status='active' or l.seller_id=auth.uid())));
create policy "seller manages listing images" on public.listing_images
for all to authenticated
using (exists(select 1 from public.listings l where l.id=listing_id and l.seller_id=auth.uid()))
with check (exists(select 1 from public.listings l where l.id=listing_id and l.seller_id=auth.uid()));

create policy "wanted posts public read" on public.wanted_posts
for select using (true);
create policy "author creates wanted post" on public.wanted_posts
for insert to authenticated with check (author_id=auth.uid());
create policy "author updates wanted post" on public.wanted_posts
for update to authenticated using (author_id=auth.uid()) with check (author_id=auth.uid());
create policy "author deletes wanted post" on public.wanted_posts
for delete to authenticated using (author_id=auth.uid());

-- Funzione SECURITY DEFINER per evitare ricorsione nelle policy RLS dei membri chat.
create or replace function public.is_conversation_member(target_conversation uuid, target_user uuid)
returns boolean language sql stable security definer set search_path = public
as $$
  select exists (
    select 1 from public.conversation_members cm
    where cm.conversation_id = target_conversation and cm.user_id = target_user
  );
$$;

create policy "conversation members read conversation" on public.conversations
for select to authenticated using (public.is_conversation_member(id, auth.uid()));
create policy "members read membership" on public.conversation_members
for select to authenticated using (public.is_conversation_member(conversation_id, auth.uid()));
-- La creazione conversazione e l'aggiunta dei due partecipanti vanno eseguite da una RPC server-side
-- che verifica che il contattante non sia il venditore e che il post/annuncio esista.
create policy "members read messages" on public.messages
for select to authenticated using (public.is_conversation_member(conversation_id, auth.uid()));
create policy "members send messages as self" on public.messages
for insert to authenticated with check (sender_id=auth.uid() and public.is_conversation_member(conversation_id, auth.uid()));

create policy "users manage own favorites" on public.favorites
for all to authenticated using (user_id=auth.uid()) with check (user_id=auth.uid());
create policy "users create own reports" on public.reports
for insert to authenticated with check (reporter_id=auth.uid());
create policy "users read own reports" on public.reports
for select to authenticated using (reporter_id=auth.uid());

-- Storage bucket: creare dal pannello Storage come "listing-photos".
-- Impostare lettura pubblica e scrittura/cancellazione limitata al proprietario
-- usando un percorso che inizi con auth.uid()::text.
