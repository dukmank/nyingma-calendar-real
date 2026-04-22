'use client'
import { useState } from 'react'
import { supabase, type NewsPost } from '@/lib/supabase'
import { uploadImageToB2 } from '@/lib/b2upload'
import { useRouter } from 'next/navigation'

type FormData = Omit<NewsPost, 'id' | 'created_at' | 'updated_at'>

type Props = {
  initial?: NewsPost
}

const EMPTY: FormData = {
  title_en: '', title_bo: '',
  excerpt_en: '', excerpt_bo: '',
  content_en: '', content_bo: '',
  category: 'announcements',
  image_url: '',
  author: 'Vajra Lotus Foundation',
  published_at: null,
  status: 'draft',
}

export default function NewsForm({ initial }: Props) {
  const router = useRouter()
  const isEdit = !!initial
  const [form, setForm] = useState<FormData>(initial ? {
    title_en: initial.title_en,
    title_bo: initial.title_bo,
    excerpt_en: initial.excerpt_en,
    excerpt_bo: initial.excerpt_bo,
    content_en: initial.content_en,
    content_bo: initial.content_bo,
    category: initial.category,
    image_url: initial.image_url,
    author: initial.author,
    published_at: initial.published_at,
    status: initial.status,
  } : EMPTY)

  const [imageFile, setImageFile] = useState<File | null>(null)
  const [imagePreview, setImagePreview] = useState<string>(initial?.image_url ?? '')
  const [saving, setSaving] = useState<'draft' | 'publish' | null>(null)
  const [error, setError] = useState('')

  function update(key: keyof FormData, value: string) {
    setForm(f => ({ ...f, [key]: value }))
  }

  function onImageChange(e: React.ChangeEvent<HTMLInputElement>) {
    const file = e.target.files?.[0]
    if (!file) return
    setImageFile(file)
    setImagePreview(URL.createObjectURL(file))
  }

  async function save(status: 'draft' | 'published') {
    if (!form.title_en.trim()) { setError('English title is required.'); return }
    setSaving(status === 'published' ? 'publish' : 'draft')
    setError('')

    try {
      // Upload ảnh nếu có chọn file
      let imageUrl = form.image_url
      if (imageFile) {
        try {
          imageUrl = await uploadImageToB2(imageFile)
        } catch (uploadErr: unknown) {
          const msg = uploadErr instanceof Error ? uploadErr.message : String(uploadErr)
          // Nếu B2 chưa cấu hình → hỏi người dùng có muốn lưu không ảnh không
          const skip = confirm(
            `⚠️ Upload ảnh thất bại:\n${msg}\n\nBấm OK để lưu bài viết không có ảnh.\nBấm Huỷ để quay lại sửa.`
          )
          if (!skip) { setSaving(null); return }
          imageUrl = ''  // lưu không có ảnh
        }
      }

      const payload = {
        ...form,
        image_url: imageUrl,
        status,
        published_at: status === 'published' && !form.published_at
          ? new Date().toISOString()
          : form.published_at,
      }

      if (isEdit) {
        const { error } = await supabase
          .from('news_posts')
          .update(payload)
          .eq('id', initial!.id)
        if (error) throw new Error(error.message)
      } else {
        const { error } = await supabase.from('news_posts').insert(payload)
        if (error) throw new Error(error.message)
      }

      router.push('/dashboard')
    } catch (e: unknown) {
      const msg = e instanceof Error ? e.message : String(e)
      setError(`Lưu thất bại: ${msg}`)
      setSaving(null)
    }
  }

  const inputClass = 'w-full px-3 py-2 border border-stone-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-red-900 focus:border-transparent'
  const textareaClass = inputClass + ' resize-none'
  const labelClass = 'block text-sm font-semibold text-stone-700 mb-1'

  return (
    <div className="max-w-3xl">
      <div className="flex items-center gap-3 mb-6">
        <button onClick={() => router.push('/dashboard')} className="text-stone-500 hover:text-stone-800 text-sm">
          ← Back
        </button>
        <h1 className="text-2xl font-bold text-stone-900">
          {isEdit ? 'Edit Post' : 'New Post'}
        </h1>
      </div>

      {error && (
        <div className="bg-red-50 text-red-700 text-sm px-4 py-3 rounded-lg mb-6">{error}</div>
      )}

      <div className="space-y-6">
        {/* Image upload */}
        <div className="bg-white rounded-xl border border-stone-200 p-5">
          <label className={labelClass}>Cover Image</label>
          <div className="flex items-start gap-4">
            {imagePreview && (
              <img src={imagePreview} alt="" className="w-32 h-24 rounded-lg object-cover flex-shrink-0 border border-stone-200" />
            )}
            <div className="flex-1">
              <input type="file" accept="image/*" onChange={onImageChange}
                className="block text-sm text-stone-600 file:mr-3 file:py-1.5 file:px-3 file:rounded-lg file:border-0 file:bg-stone-100 file:text-stone-700 file:font-medium hover:file:bg-stone-200" />
              <p className="text-xs text-stone-400 mt-2">Or paste a direct URL:</p>
              <input type="url" value={form.image_url} onChange={e => { update('image_url', e.target.value); setImagePreview(e.target.value) }}
                placeholder="https://f005.backblazeb2.com/file/..." className={inputClass + ' mt-1'} />
            </div>
          </div>
        </div>

        {/* Titles */}
        <div className="bg-white rounded-xl border border-stone-200 p-5 space-y-4">
          <h2 className="font-semibold text-stone-800 text-sm uppercase tracking-wide">Title</h2>
          <div>
            <label className={labelClass}>English *</label>
            <input type="text" value={form.title_en} onChange={e => update('title_en', e.target.value)} className={inputClass} placeholder="Enter English title" />
          </div>
          <div>
            <label className={labelClass}>Tibetan</label>
            <input type="text" value={form.title_bo} onChange={e => update('title_bo', e.target.value)} className={inputClass} placeholder="བོད་སྐད་ཀྱི་མིང་།" />
          </div>
        </div>

        {/* Excerpt */}
        <div className="bg-white rounded-xl border border-stone-200 p-5 space-y-4">
          <h2 className="font-semibold text-stone-800 text-sm uppercase tracking-wide">Excerpt / Summary</h2>
          <div>
            <label className={labelClass}>English</label>
            <textarea rows={2} value={form.excerpt_en} onChange={e => update('excerpt_en', e.target.value)} className={textareaClass} placeholder="Brief summary in English" />
          </div>
          <div>
            <label className={labelClass}>Tibetan</label>
            <textarea rows={2} value={form.excerpt_bo} onChange={e => update('excerpt_bo', e.target.value)} className={textareaClass} placeholder="བོད་སྐད་ཀྱི་བསྡུས་དོན།" />
          </div>
        </div>

        {/* Full content */}
        <div className="bg-white rounded-xl border border-stone-200 p-5 space-y-4">
          <h2 className="font-semibold text-stone-800 text-sm uppercase tracking-wide">Full Content</h2>
          <div>
            <label className={labelClass}>English</label>
            <textarea rows={10} value={form.content_en} onChange={e => update('content_en', e.target.value)} className={textareaClass} placeholder="Full article body in English…" />
          </div>
          <div>
            <label className={labelClass}>Tibetan</label>
            <textarea rows={10} value={form.content_bo} onChange={e => update('content_bo', e.target.value)} className={textareaClass} placeholder="བོད་སྐད་ཀྱི་ནང་དོན་ཆ་ཚང་།" />
          </div>
        </div>

        {/* Meta */}
        <div className="bg-white rounded-xl border border-stone-200 p-5 grid grid-cols-2 gap-4">
          <div>
            <label className={labelClass}>Category</label>
            <select value={form.category} onChange={e => update('category', e.target.value)} className={inputClass}>
              <option value="announcements">Announcements</option>
              <option value="teachings">Teachings</option>
              <option value="lineage">Lineage</option>
            </select>
          </div>
          <div>
            <label className={labelClass}>Author</label>
            <input type="text" value={form.author} onChange={e => update('author', e.target.value)} className={inputClass} />
          </div>
        </div>

        {/* Action buttons */}
        <div className="flex gap-3 pt-2 pb-12">
          <button
            onClick={() => save('draft')}
            disabled={!!saving}
            className="flex-1 py-3 rounded-xl font-semibold text-sm border-2 border-stone-300 text-stone-700 hover:bg-stone-100 transition-colors disabled:opacity-50"
          >
            {saving === 'draft' ? 'Saving…' : '💾 Save as Draft'}
          </button>
          <button
            onClick={() => save('published')}
            disabled={!!saving}
            className="flex-1 py-3 rounded-xl font-semibold text-sm bg-red-900 text-white hover:bg-red-800 transition-colors disabled:opacity-50"
          >
            {saving === 'publish' ? 'Publishing…' : '🚀 Publish'}
          </button>
        </div>
      </div>
    </div>
  )
}
