-- ============================================================================
-- Personal site — Supabase schema for Admin board
-- Blog posts + private task manager
--
-- Usage:
--   1. Create a new Supabase project at https://supabase.com
--   2. Go to SQL Editor → New query
--   3. Paste + run this entire file
--   4. Then go to Authentication → Users and create your admin account
--      (or sign up once via the admin UI and then restrict signups)
-- ============================================================================

-- Enable required extensions (usually already on)
create extension if not exists "pgcrypto"; -- for gen_random_uuid()

-- ----------------------------------------------------------------------------
-- POSTS (blog)
-- ----------------------------------------------------------------------------
create table if not exists public.posts (
  id            uuid primary key default gen_random_uuid(),
  slug          text unique not null check (slug ~ '^[a-z0-9]+(?:-[a-z0-9]+)*$'),
  title         text not null,
  content       text not null,                 -- Markdown source
  published     boolean not null default false,
  published_at  timestamptz,
  tags          text[] not null default '{}',
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);

comment on table public.posts is 'Blog posts. Public can read only when published=true.';
comment on column public.posts.slug is 'URL-friendly slug, lowercase kebab-case.';
comment on column public.posts.content is 'Markdown content. Rendered on the client.';

-- ----------------------------------------------------------------------------
-- TASKS (private project/task manager)
-- ----------------------------------------------------------------------------
create table if not exists public.tasks (
  id          uuid primary key default gen_random_uuid(),
  title       text not null,
  description text,
  status      text not null default 'todo'
               check (status in ('todo', 'doing', 'done')),
  priority    smallint not null default 0,     -- -1=low, 0=normal, 1=high
  due_date    date,
  project     text,                            -- e.g. 'personal-site', 'research', 'infra'
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

comment on table public.tasks is 'Private task/project tracker. Only the site owner can access.';
comment on column public.tasks.status is 'todo | doing | done';
comment on column public.tasks.priority is '-1 low, 0 normal, 1 high';

-- ----------------------------------------------------------------------------
-- Updated-at trigger (shared)
-- ----------------------------------------------------------------------------
create or replace function public.set_updated_at()
returns trigger
language plpgsql as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

drop trigger if exists posts_set_updated_at on public.posts;
create trigger posts_set_updated_at
  before update on public.posts
  for each row execute function public.set_updated_at();

drop trigger if exists tasks_set_updated_at on public.tasks;
create trigger tasks_set_updated_at
  before update on public.tasks
  for each row execute function public.set_updated_at();

-- ----------------------------------------------------------------------------
-- ROW LEVEL SECURITY
-- ----------------------------------------------------------------------------
alter table public.posts enable row level security;
alter table public.tasks enable row level security;

-- IMPORTANT: Replace the email below with the exact email you will use
-- for the single admin account (in all 5 policy lines).
--
-- Recommended for this site: richardgtang@gmail.com
-- You can also switch to auth.uid() = 'exact-uuid-here' after you create the user.

-- === POSTS policies ===
-- Anyone (including anon) can read published posts
create policy "posts: public can read published"
  on public.posts for select
  using (published = true);

-- Admin can read everything (including drafts)
create policy "posts: admin can read all"
  on public.posts for select
  using ( (auth.jwt() ->> 'email') = 'richardgtang@gmail.com' );

-- Admin can insert, update, delete
create policy "posts: admin can insert"
  on public.posts for insert
  with check ( (auth.jwt() ->> 'email') = 'richardgtang@gmail.com' );

create policy "posts: admin can update"
  on public.posts for update
  using ( (auth.jwt() ->> 'email') = 'richardgtang@gmail.com' )
  with check ( (auth.jwt() ->> 'email') = 'richardgtang@gmail.com' );

create policy "posts: admin can delete"
  on public.posts for delete
  using ( (auth.jwt() ->> 'email') = 'richardgtang@gmail.com' );

-- === TASKS policies (fully private) ===
-- Only admin can do anything with tasks
create policy "tasks: admin full access"
  on public.tasks
  for all
  using ( (auth.jwt() ->> 'email') = 'richardgtang@gmail.com' )
  with check ( (auth.jwt() ->> 'email') = 'richardgtang@gmail.com' );

-- ----------------------------------------------------------------------------
-- Helpful indexes
-- ----------------------------------------------------------------------------
create index if not exists posts_published_idx on public.posts (published, published_at desc);
create index if not exists posts_slug_idx on public.posts (slug);
create index if not exists tasks_status_idx on public.tasks (status, updated_at desc);

-- ----------------------------------------------------------------------------
-- (Optional) Seed example data — comment out after first run if desired
-- ----------------------------------------------------------------------------
-- insert into public.posts (slug, title, content, published, published_at, tags) values
--   ('hello-world', 'Hello World', '# First post\n\nThis is **Markdown**.', true, now(), array['meta']);

-- insert into public.tasks (title, description, status, priority, project) values
--   ('Set up Supabase admin board', 'Get auth + schema + UI working', 'doing', 1, 'personal-site');
