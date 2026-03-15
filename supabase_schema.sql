-- ============================================================
-- INJAZ Lebanon Portal — Supabase Database Schema
-- Run this in: Supabase Dashboard → SQL Editor → New Query
-- ============================================================

-- 1. USER PROFILES (extends Supabase auth.users)
create table if not exists public.profiles (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid unique references auth.users(id) on delete cascade,
  email      text,
  name       text,
  role       text default 'job_seeker', -- job_seeker | employer | trainer | admin
  company    text,
  industry   text,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- 2. FORM RESPONSES (all forms in one table, keyed by form_key)
create table if not exists public.form_responses (
  id         uuid primary key default gen_random_uuid(),
  user_id    text not null,           -- auth user id
  form_key   text not null,           -- baseline | endline | performance | app_baseline | app_endline | employer_feedback | employer_mapping
  data       jsonb not null default '{}',
  user_name  text,
  created_at timestamptz default now(),
  updated_at timestamptz default now(),
  unique(user_id, form_key)           -- one response per user per form (upsertable)
);

-- 3. JOB APPLICATIONS
create table if not exists public.applications (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid references auth.users(id) on delete cascade,
  job_id     text not null,
  applied_at timestamptz default now(),
  unique(user_id, job_id)
);

-- 4. JOB POSTINGS (for employers)
create table if not exists public.jobs (
  id          uuid primary key default gen_random_uuid(),
  employer_id uuid references auth.users(id) on delete cascade,
  title       text not null,
  company     text not null,
  location    text,
  salary      text,
  type        text default 'Full-time',
  industry    text,
  description text,
  active      boolean default true,
  created_at  timestamptz default now()
);

-- ============================================================
-- ROW LEVEL SECURITY (RLS) — keeps data safe
-- ============================================================

-- Enable RLS on all tables
alter table public.profiles       enable row level security;
alter table public.form_responses enable row level security;
alter table public.applications   enable row level security;
alter table public.jobs           enable row level security;

-- PROFILES: users can read/write their own profile
create policy "Users can view own profile"
  on public.profiles for select
  using (auth.uid() = user_id);

create policy "Users can update own profile"
  on public.profiles for all
  using (auth.uid() = user_id);

-- Admins and trainers can see all profiles
create policy "Admins see all profiles"
  on public.profiles for select
  using (
    exists (
      select 1 from public.profiles p
      where p.user_id = auth.uid()
      and p.role in ('admin', 'trainer')
    )
  );

-- FORM RESPONSES: users can write their own, admins/trainers can read all
create policy "Users can manage own responses"
  on public.form_responses for all
  using (user_id = auth.uid()::text);

create policy "Admins can read all responses"
  on public.form_responses for select
  using (
    exists (
      select 1 from public.profiles p
      where p.user_id = auth.uid()
      and p.role in ('admin', 'trainer')
    )
  );

-- APPLICATIONS: users manage their own
create policy "Users manage own applications"
  on public.applications for all
  using (user_id = auth.uid());

create policy "Admins view all applications"
  on public.applications for select
  using (
    exists (
      select 1 from public.profiles p
      where p.user_id = auth.uid()
      and p.role in ('admin', 'employer')
    )
  );

-- JOBS: anyone can view, only employers can post
create policy "Anyone can view jobs"
  on public.jobs for select
  using (active = true);

create policy "Employers can manage own jobs"
  on public.jobs for all
  using (employer_id = auth.uid());

-- ============================================================
-- AUTO-CREATE PROFILE on signup (trigger)
-- ============================================================
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (user_id, email, name, role)
  values (
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data->>'name', split_part(new.email, '@', 1)),
    coalesce(new.raw_user_meta_data->>'role', 'job_seeker')
  )
  on conflict (user_id) do nothing;
  return new;
end;
$$ language plpgsql security definer;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- ============================================================
-- GRANT PERMISSIONS to authenticated users
-- ============================================================
grant usage on schema public to authenticated;
grant all on public.profiles       to authenticated;
grant all on public.form_responses to authenticated;
grant all on public.applications   to authenticated;
grant all on public.jobs           to authenticated;
grant usage, select on all sequences in schema public to authenticated;

-- Allow anon to read jobs (for public job board)
grant usage on schema public to anon;
grant select on public.jobs to anon;

-- Done!
select 'Schema created successfully!' as status;
