import { createClient } from '@supabase/supabase-js'

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL!
const supabaseAnonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!

export const supabase = createClient(supabaseUrl, supabaseAnonKey)

export type NewsPost = {
  id: string
  title_en: string
  title_bo: string
  excerpt_en: string
  excerpt_bo: string
  content_en: string
  content_bo: string
  category: 'teachings' | 'lineage' | 'announcements'
  image_url: string
  author: string
  published_at: string | null
  status: 'draft' | 'published'
  created_at: string
  updated_at: string
}
