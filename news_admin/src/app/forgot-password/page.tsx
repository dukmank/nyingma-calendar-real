'use client'
import { useState } from 'react'
import Link from 'next/link'
import { supabase } from '@/lib/supabase'

export default function ForgotPasswordPage() {
  const [email, setEmail] = useState('')
  const [loading, setLoading] = useState(false)
  const [sent, setSent] = useState(false)
  const [error, setError] = useState('')

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault()
    setLoading(true)
    setError('')

    // Kiểm tra env vars trước khi gọi API
    const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL
    const supabaseKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY
    if (!supabaseUrl || supabaseUrl.includes('YOUR_PROJECT')) {
      setError('Chưa cấu hình NEXT_PUBLIC_SUPABASE_URL trong file .env.local')
      setLoading(false)
      return
    }
    if (!supabaseKey || supabaseKey.includes('YOUR_SUPABASE')) {
      setError('Chưa cấu hình NEXT_PUBLIC_SUPABASE_ANON_KEY trong file .env.local')
      setLoading(false)
      return
    }

    try {
      const { error } = await supabase.auth.resetPasswordForEmail(email, {
        redirectTo: `${window.location.origin}/reset-password`,
      })

      if (error) {
        // Dịch lỗi phổ biến sang tiếng Việt
        const msg = error.message.toLowerCase()
        if (msg.includes('fetch') || msg.includes('network')) {
          setError(`Không kết nối được Supabase. Kiểm tra lại NEXT_PUBLIC_SUPABASE_URL trong .env.local (hiện tại: ${supabaseUrl})`)
        } else if (msg.includes('rate limit')) {
          setError('Gửi quá nhiều lần. Vui lòng đợi vài phút rồi thử lại.')
        } else {
          setError(error.message)
        }
      } else {
        setSent(true)
      }
    } catch (err: unknown) {
      const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL ?? '(chưa set)'
      setError(`Lỗi kết nối mạng. Kiểm tra:\n1. File .env.local đã có NEXT_PUBLIC_SUPABASE_URL chưa?\n2. URL hiện tại: ${supabaseUrl}\n3. Đã restart "npm run dev" sau khi sửa .env.local chưa?\n\nChi tiết: ${String(err)}`)
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="min-h-screen flex items-center justify-center px-4">
      <div className="w-full max-w-sm">
        {/* Logo */}
        <div className="text-center mb-8">
          <div className="inline-flex items-center justify-center w-16 h-16 rounded-2xl bg-red-900 mb-4">
            <span className="text-2xl text-yellow-300">༄</span>
          </div>
          <h1 className="text-2xl font-bold text-stone-900">Quên mật khẩu</h1>
          <p className="text-sm text-stone-500 mt-1">Nyingmapa Calendar CMS</p>
        </div>

        <div className="bg-white rounded-2xl shadow-sm border border-stone-200 p-8">
          {sent ? (
            /* ── Trạng thái đã gửi email ── */
            <div className="text-center space-y-4">
              <div className="inline-flex items-center justify-center w-14 h-14 rounded-full bg-green-100 mb-2">
                <svg className="w-7 h-7 text-green-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
                </svg>
              </div>
              <h2 className="text-lg font-semibold text-stone-900">Đã gửi email!</h2>
              <p className="text-sm text-stone-600 leading-relaxed">
                Kiểm tra hộp thư của <span className="font-medium text-stone-900">{email}</span>.
                Click vào link trong email để đặt lại mật khẩu.
              </p>
              <p className="text-xs text-stone-400">
                Không thấy email? Kiểm tra thư mục Spam hoặc{' '}
                <button
                  onClick={() => setSent(false)}
                  className="text-red-900 underline hover:no-underline"
                >
                  thử lại
                </button>
              </p>
              <Link
                href="/"
                className="block mt-4 text-sm text-center text-red-900 font-medium hover:underline"
              >
                ← Quay lại đăng nhập
              </Link>
            </div>
          ) : (
            /* ── Form nhập email ── */
            <form onSubmit={handleSubmit} className="space-y-4">
              <p className="text-sm text-stone-600 mb-2">
                Nhập email của bạn, hệ thống sẽ gửi link để đặt lại mật khẩu.
              </p>

              {error && (
                <div className="bg-red-50 text-red-700 text-sm px-4 py-3 rounded-lg">
                  {error}
                </div>
              )}

              <div>
                <label className="block text-sm font-medium text-stone-700 mb-1">
                  Email
                </label>
                <input
                  type="email"
                  value={email}
                  onChange={e => setEmail(e.target.value)}
                  required
                  autoFocus
                  className="w-full px-3 py-2 border border-stone-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-red-900 focus:border-transparent"
                  placeholder="admin@vajralotusfoundation.org"
                />
              </div>

              <button
                type="submit"
                disabled={loading}
                className="w-full bg-red-900 text-white py-2.5 rounded-lg font-semibold text-sm hover:bg-red-800 transition-colors disabled:opacity-60"
              >
                {loading ? 'Đang gửi…' : 'Gửi link đặt lại mật khẩu'}
              </button>

              <Link
                href="/"
                className="block text-center text-sm text-stone-500 hover:text-stone-800 mt-2"
              >
                ← Quay lại đăng nhập
              </Link>
            </form>
          )}
        </div>
      </div>
    </div>
  )
}
