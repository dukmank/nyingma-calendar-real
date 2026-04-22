'use client'
import { useEffect, useState } from 'react'
import { useSearchParams } from 'next/navigation'
import { supabase, type NewsPost } from '@/lib/supabase'
import NewsForm from '@/components/NewsForm'

export default function EditPostPage() {
  const params = useSearchParams()
  const id = params.get('id')
  const [post, setPost] = useState<NewsPost | null>(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    if (!id) return
    supabase.from('news_posts').select('*').eq('id', id).single().then(({ data }) => {
      setPost(data)
      setLoading(false)
    })
  }, [id])

  if (loading) return (
    <div className="text-center py-20 text-stone-400">Loading post…</div>
  )
  if (!post) return (
    <div className="text-center py-20 text-stone-400">Post not found.</div>
  )
  return <NewsForm initial={post} />
}
