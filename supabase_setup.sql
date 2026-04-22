-- ─────────────────────────────────────────────────────────────
-- Nyingmapa Calendar — Supabase News Setup
-- Run this entire file in: Supabase Dashboard → SQL Editor → New Query
-- ─────────────────────────────────────────────────────────────

-- 1. Create the news_posts table
create table if not exists public.news_posts (
  id            uuid primary key default gen_random_uuid(),
  title_en      text not null,
  title_bo      text not null default '',
  excerpt_en    text not null default '',
  excerpt_bo    text not null default '',
  content_en    text not null default '',
  content_bo    text not null default '',
  category      text not null default 'announcements'
                  check (category in ('teachings', 'lineage', 'announcements')),
  image_url     text not null default '',
  author        text not null default 'Vajra Lotus Foundation',
  published_at  timestamptz,
  status        text not null default 'draft'
                  check (status in ('draft', 'published')),
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);

-- 2. Auto-update updated_at on any change
create or replace function public.handle_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists set_updated_at on public.news_posts;
create trigger set_updated_at
  before update on public.news_posts
  for each row execute procedure public.handle_updated_at();

-- 3. When a post is published, auto-set published_at (if not already set)
create or replace function public.handle_published_at()
returns trigger language plpgsql as $$
begin
  if new.status = 'published' and old.status != 'published' and new.published_at is null then
    new.published_at = now();
  end if;
  return new;
end;
$$;

drop trigger if exists set_published_at on public.news_posts;
create trigger set_published_at
  before update on public.news_posts
  for each row execute procedure public.handle_published_at();

-- 4. Indexes for fast query
create index if not exists idx_news_status_published_at
  on public.news_posts (status, published_at desc);

create index if not exists idx_news_category
  on public.news_posts (category, status, published_at desc);

-- 5. Enable Row Level Security
alter table public.news_posts enable row level security;

-- 6. RLS Policies
-- PUBLIC: anyone can read published posts (used by Flutter app with anon key)
drop policy if exists "Public can read published news" on public.news_posts;
create policy "Public can read published news"
  on public.news_posts for select
  using (status = 'published');

-- ADMIN (authenticated users): full CRUD — used by the Next.js admin panel
drop policy if exists "Authenticated users can manage news" on public.news_posts;
create policy "Authenticated users can manage news"
  on public.news_posts for all
  using (auth.role() = 'authenticated')
  with check (auth.role() = 'authenticated');

-- 7. Seed sample data (optional — delete after testing)
insert into public.news_posts
  (title_en, title_bo, excerpt_en, excerpt_bo, content_en, content_bo, category, image_url, author, status, published_at)
values
  (
    'Losar Celebrations 2026',
    'ལོ་གསར་དུས་ཆེན། ༢༠༢༦',
    'Join us for the Tibetan New Year celebrations at Vajra Lotus Foundation.',
    'རྡོ་རྗེ་པདྨ་གཞི་རྩར་བོད་ལོ་གསར་བར་མཉམ་འཛོམས་རོགས།',
    'We are delighted to invite all practitioners to our Losar celebrations...',
    'ང་ཚོས་སྒྲུབ་མཁན་ཚང་མ་ལ་ལོ་གསར་དུས་ཆེན་ལ་མཉམ་འཛོམས་ཞུ་རྒྱུར་དགའ་བཞིན་ཡིན།',
    'announcements',
    'https://f005.backblazeb2.com/file/nyingma-assets2/losar.webp',
    'Vajra Lotus Foundation',
    'published',
    now()
  ),
  (
    'Teaching on Dzogchen by Khenpo Rinpoche',
    'མཁན་པོ་རིན་པོ་ཆེའི་རྫོགས་ཆེན་ཆོས་ཚོགས།',
    'An upcoming teaching series on the Great Perfection.',
    'རྫོགས་ཆེན་གྱི་ཆོས་ཚོགས་གསར་པ་ཞིག་འབྱུང་འགྱུར་ཡིན།',
    'Khenpo Rinpoche will be giving a series of teachings on Dzogchen...',
    'མཁན་པོ་རིན་པོ་ཆེས་རྫོགས་ཆེན་གྱི་ཆོས་ཚོགས་ཕུལ་གནང་མཛད་འགྱུར།',
    'teachings',
    'https://f005.backblazeb2.com/file/nyingma-assets2/medicine_buddha.webp',
    'Vajra Lotus Foundation',
    'published',
    now() - interval '3 days'
  ),
  (
    'History of the Nyingma Lineage',
    'རྙིང་མ་བཀའ་བརྒྱུད་ཀྱི་ལོ་རྒྱུས།',
    'Exploring the ancient roots of the Nyingma tradition.',
    'རྙིང་མ་ལུགས་ཀྱི་རྒྱུས་མདོ་རིང་མོ་ལ་བལྟ་བ།',
    'The Nyingma school is the oldest of the four major schools of Tibetan Buddhism...',
    'རྙིང་མ་གྲུབ་མཐའ་བཞི་ལས་རྙིང་བ་ཤོས་ཡིན།',
    'lineage',
    'https://f005.backblazeb2.com/file/nyingma-assets2/gurus.webp',
    'Vajra Lotus Foundation',
    'published',
    now() - interval '7 days'
  );

-- Done!
select 'news_posts table created and seeded successfully.' as result;
