'use client'
import { useState } from 'react'
import Link from 'next/link'
import { supabase } from '@/lib/supabase'
import { useRouter } from 'next/navigation'

export default function LoginPage() {
  const router = useRouter()
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState('')

  async function handleLogin(e: React.FormEvent) {
    e.preventDefault()
    setLoading(true)
    setError('')

    const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL
    if (!supabaseUrl || supabaseUrl.includes('YOUR_PROJECT')) {
      setError('Chưa cấu hình .env.local — xem hướng dẫn bên dưới')
      setLoading(false)
      return
    }

    try {
      const { error } = await supabase.auth.signInWithPassword({ email, password })
      if (error) {
        const msg = error.message.toLowerCase()
        if (msg.includes('invalid login') || msg.includes('invalid credentials')) {
          setError('Email hoặc mật khẩu không đúng.')
        } else if (msg.includes('fetch') || msg.includes('network')) {
          setError(`Không kết nối được Supabase.\nURL: ${supabaseUrl}\nHãy kiểm tra lại .env.local và restart server.`)
        } else {
          setError(error.message)
        }
        setLoading(false)
      } else {
        router.push('/dashboard')
      }
    } catch (err: unknown) {
      setError(`Lỗi kết nối. Đã restart "npm run dev" sau khi sửa .env.local chưa?\n${String(err)}`)
      setLoading(false)
    }
  }

  return (
    <div className="min-h-screen flex items-center justify-center px-4">
      <div className="w-full max-w-sm">
        {/* Logo / brand */}
        <div className="text-center mb-8">
          <div className="inline-flex items-center justify-center w-16 h-16 rounded-2xl bg-red-900 mb-4">
            <span className="text-2xl text-yellow-300">༄</span>
          </div>
          <h1 className="text-2xl font-bold text-stone-900">News Admin</h1>
          <p className="text-sm text-stone-500 mt-1">Nyingmapa Calendar CMS</p>
        </div>

        <form onSubmit={handleLogin} className="bg-white rounded-2xl shadow-sm border border-stone-200 p-8 space-y-4">
          {error && (
            <div className="bg-red-50 text-red-700 text-sm px-4 py-3 rounded-lg">{error}</div>
          )}
          <div>
            <label className="block text-sm font-medium text-stone-700 mb-1">Email</label>
            <input
              type="email"
              value={email}
              onChange={e => setEmail(e.target.value)}
              required
              className="w-full px-3 py-2 border border-stone-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-red-900 focus:border-transparent"
              placeholder="admin@vajralotusfoundation.org"
            />
          </div>
          <div>
            <div className="flex items-center justify-between mb-1">
              <label className="block text-sm font-medium text-stone-700">Password</label>
              <Link
                href="/forgot-password"
                className="text-xs text-red-900 hover:underline font-medium"
              >
                Quên mật khẩu?
              </Link>
            </div>
            <input
              type="password"
              value={password}
              onChange={e => setPassword(e.target.value)}
              required
              className="w-full px-3 py-2 border border-stone-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-red-900 focus:border-transparent"
            />
          </div>
          <button
            type="submit"
            disabled={loading}
            className="w-full bg-red-900 text-white py-2.5 rounded-lg font-semibold text-sm hover:bg-red-800 transition-colors disabled:opacity-60"
          >
            {loading ? 'Signing in…' : 'Sign In'}
          </button>
        </form>
      </div>
    </div>
  )
}
