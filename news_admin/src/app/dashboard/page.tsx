'use client'
import { useEffect, useState } from 'react'
import Link from 'next/link'
import { supabase, type NewsPost } from '@/lib/supabase'

const CATEGORY_LABELS: Record<string, string> = {
  teachings: 'Teachings',
  lineage: 'Lineage',
  announcements: 'Announcements',
}

export default function DashboardPage() {
  const [posts, setPosts] = useState<NewsPost[]>([])
  const [loading, setLoading] = useState(true)
  const [deleting, setDeleting] = useState<string | null>(null)

  async function load() {
    setLoading(true)
    const { data } = await supabase
      .from('news_posts')
      .select('*')
      .order('created_at', { ascending: false })
    setPosts(data ?? [])
    setLoading(false)
  }

  useEffect(() => { load() }, [])

  async function handleDelete(id: string, title: string) {
    if (!confirm(`Delete "${title}"? This cannot be undone.`)) return
    setDeleting(id)
    await supabase.from('news_posts').delete().eq('id', id)
    await load()
    setDeleting(null)
  }

  async function togglePublish(post: NewsPost) {
    const newStatus = post.status === 'published' ? 'draft' : 'published'
    const update: Partial<NewsPost> = { status: newStatus }
    if (newStatus === 'published' && !post.published_at) {
      update.published_at = new Date().toISOString()
    }
    await supabase.from('news_posts').update(update).eq('id', post.id)
    await load()
  }

  return (
    <div>
      <div className="flex items-center justify-between mb-6">
        <div>
          <h1 className="text-2xl font-bold text-stone-900">News Posts</h1>
          <p className="text-sm text-stone-500 mt-0.5">{posts.length} total posts</p>
        </div>
        <Link
          href="/dashboard/news/new"
          className="bg-red-900 text-white px-4 py-2 rounded-lg text-sm font-semibold hover:bg-red-800 transition-colors"
        >
          + New Post
        </Link>
      </div>

      {loading ? (
        <div className="text-center py-20 text-stone-400">Loading…</div>
      ) : posts.length === 0 ? (
        <div className="text-center py-20 text-stone-400">
          No posts yet. <Link href="/dashboard/news/new" className="text-red-900 underline">Create one.</Link>
        </div>
      ) : (
        <div className="space-y-3">
          {posts.map(post => (
            <div
              key={post.id}
              className="bg-white rounded-xl border border-stone-200 px-5 py-4 flex items-start gap-4"
            >
              {/* Thumbnail */}
              {post.image_url ? (
                <img src={post.image_url} alt="" className="w-16 h-16 rounded-lg object-cover flex-shrink-0" />
              ) : (
                <div className="w-16 h-16 rounded-lg bg-stone-100 flex items-center justify-center flex-shrink-0">
                  <span className="text-2xl text-stone-300">📰</span>
                </div>
              )}

              <div className="flex-1 min-w-0">
                <div className="flex items-center gap-2 mb-1">
                  <span className={`text-xs font-semibold px-2 py-0.5 rounded-full ${
                    post.status === 'published'
                      ? 'bg-green-100 text-green-700'
                      : 'bg-amber-100 text-amber-700'
                  }`}>
                    {post.status === 'published' ? '● Published' : '○ Draft'}
                  </span>
                  <span className="text-xs bg-stone-100 text-stone-600 px-2 py-0.5 rounded-full">
                    {CATEGORY_LABELS[post.category] ?? post.category}
                  </span>
                </div>
                <p className="font-semibold text-stone-900 truncate">{post.title_en}</p>
                <p className="text-sm text-stone-500 truncate">{post.title_bo}</p>
                <p className="text-xs text-stone-400 mt-1">
                  {post.published_at
                    ? `Published ${new Date(post.published_at).toLocaleDateString()}`
                    : `Created ${new Date(post.created_at).toLocaleDateString()}`}
                </p>
              </div>

              <div className="flex items-center gap-2 flex-shrink-0">
                <button
                  onClick={() => togglePublish(post)}
                  className={`text-xs px-3 py-1.5 rounded-lg font-medium transition-colors ${
                    post.status === 'published'
                      ? 'bg-amber-50 text-amber-700 hover:bg-amber-100'
                      : 'bg-green-50 text-green-700 hover:bg-green-100'
                  }`}
                >
                  {post.status === 'published' ? 'Unpublish' : 'Publish'}
                </button>
                <Link
                  href={`/dashboard/news/edit?id=${post.id}`}
                  className="text-xs px-3 py-1.5 bg-stone-100 text-stone-700 rounded-lg hover:bg-stone-200 transition-colors font-medium"
                >
                  Edit
                </Link>
                <button
                  onClick={() => handleDelete(post.id, post.title_en)}
                  disabled={deleting === post.id}
                  className="text-xs px-3 py-1.5 bg-red-50 text-red-700 rounded-lg hover:bg-red-100 transition-colors font-medium disabled:opacity-50"
                >
                  {deleting === post.id ? '…' : 'Delete'}
                </button>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  )
}
