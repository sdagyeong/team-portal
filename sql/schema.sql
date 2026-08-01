-- ========================================
-- 1. resources (자료실) 테이블
-- ========================================
create table if not exists resources (
  id bigint generated always as identity primary key,
  title text not null,
  description text,
  author text not null,
  file_url text,
  file_name text,
  created_at timestamptz default now()
);

alter table resources enable row level security;

create policy "allow anon select resources"
  on resources for select
  to anon
  using (true);

create policy "allow anon insert resources"
  on resources for insert
  to anon
  with check (true);

create policy "allow anon delete resources"
  on resources for delete
  to anon
  using (true);

-- ========================================
-- 2. schedules (일정관리) 테이블
-- ========================================
create table if not exists schedules (
  id bigint generated always as identity primary key,
  title text not null,
  description text,
  author text not null,
  start_date date not null,
  end_date date not null,
  created_at timestamptz default now()
);

alter table schedules enable row level security;

create policy "allow anon select schedules"
  on schedules for select
  to anon
  using (true);

create policy "allow anon insert schedules"
  on schedules for insert
  to anon
  with check (true);

create policy "allow anon delete schedules"
  on schedules for delete
  to anon
  using (true);

-- ========================================
-- 3. tasks (업무관리) 테이블
-- ========================================
create table if not exists tasks (
  id bigint generated always as identity primary key,
  title text not null,
  description text,
  assignee text not null,
  due_date date,
  status text not null default '진행중',
  created_at timestamptz default now()
);

alter table tasks enable row level security;

create policy "allow anon select tasks"
  on tasks for select
  to anon
  using (true);

create policy "allow anon insert tasks"
  on tasks for insert
  to anon
  with check (true);

create policy "allow anon update tasks"
  on tasks for update
  to anon
  using (true)
  with check (true);

create policy "allow anon delete tasks"
  on tasks for delete
  to anon
  using (true);

-- ========================================
-- 4. 자료실 파일 업로드용 Storage 버킷
-- ========================================
-- SQL로는 만들 수 없고, Supabase 대시보드에서 직접 생성해야 합니다.
-- Storage → New bucket → 이름: resources → Public bucket 체크
--
-- 버킷 생성 후, Storage 정책도 열어줘야 업로드/다운로드가 됩니다.
-- Storage → resources → Policies → New policy
--   - INSERT: role = anon, with check: true
--   - SELECT: role = anon, using: true
