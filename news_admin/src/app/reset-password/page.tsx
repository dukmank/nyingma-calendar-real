'use client'
import { useEffect, useState } from 'react'
import { useRouter } from 'next/navigation'
import { supabase } from '@/lib/supabase'

type Step = 'verifying' | 'form' | 'success' | 'error'

export default function ResetPasswordPage() {
  const router = useRouter()
  const [step, setStep] = useState<Step>('verifying')
  const [password, setPassword] = useState('')
  const [confirm, setConfirm] = useState('')
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState('')
  const [showPassword, setShowPassword] = useState(false)

  // Supabase gửi token qua URL fragment (#access_token=...).
  // Khi trang load, Supabase JS tự đọc fragment và tạo session.
  useEffect(() => {
    const { data: listener } = supabase.auth.onAuthStateChange((event) => {
      if (event === 'PASSWORD_RECOVERY') {
        // Token hợp lệ — cho phép nhập mật khẩu mới
        setStep('form')
      } else if (event === 'SIGNED_IN' && step === 'verifying') {
        setStep('form')
      }
    })

    // Timeout nếu link hết hạn hoặc không hợp lệ
    const timeout = setTimeout(() => {
      setStep(prev => prev === 'verifying' ? 'error' : prev)
    }, 5000)

    return () => {
      listener.subscription.unsubscribe()
      clearTimeout(timeout)
    }
  }, [step])

  async function handleReset(e: React.FormEvent) {
    e.preventDefault()
    setError('')

    if (password.length < 8) {
      setError('Mật khẩu phải có ít nhất 8 ký tự.')
      return
    }
    if (password !== confirm) {
      setError('Hai mật khẩu không khớp.')
      return
    }

    setLoading(true)
    const { error } = await supabase.auth.updateUser({ password })

    if (error) {
      setError(error.message)
      setLoading(false)
    } else {
      setStep('success')
      // Tự động về trang login sau 3 giây
      setTimeout(() => router.replace('/'), 3000)
    }
  }

  // ── Verifying ──────────────────────────────────────────────────────────────
  if (step === 'verifying') return (
    <div className="min-h-screen flex items-center justify-center">
      <div className="text-center space-y-3">
        <div className="animate-spin rounded-full h-10 w-10 border-2 border-red-900 border-t-transparent mx-auto" />
        <p className="text-sm text-stone-500">Đang xác thực link…</p>
      </div>
    </div>
  )

  // ── Link hết hạn / lỗi ────────────────────────────────────────────────────
  if (step === 'error') return (
    <div className="min-h-screen flex items-center justify-center px-4">
      <div className="w-full max-w-sm text-center bg-white rounded-2xl border border-stone-200 p-8 shadow-sm space-y-4">
        <div className="inline-flex items-center justify-center w-14 h-14 rounded-full bg-red-100 mb-2">
          <svg className="w-7 h-7 text-red-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
          </svg>
        </div>
        <h2 className="text-lg font-semibold text-stone-900">Link không hợp lệ</h2>
        <p className="text-sm text-stone-500">
          Link đặt lại mật khẩu đã hết hạn hoặc đã được sử dụng.
          Vui lòng yêu cầu link mới.
        </p>
        <a
          href="/forgot-password"
          className="inline-block bg-red-900 text-white px-6 py-2.5 rounded-lg text-sm font-semibold hover:bg-red-800 transition-colors"
        >
          Yêu cầu link mới
        </a>
      </div>
    </div>
  )

  // ── Đổi mật khẩu thành công ───────────────────────────────────────────────
  if (step === 'success') return (
    <div className="min-h-screen flex items-center justify-center px-4">
      <div className="w-full max-w-sm text-center bg-white rounded-2xl border border-stone-200 p-8 shadow-sm space-y-4">
        <div className="inline-flex items-center justify-center w-14 h-14 rounded-full bg-green-100 mb-2">
          <svg className="w-7 h-7 text-green-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
          </svg>
        </div>
        <h2 className="text-lg font-semibold text-stone-900">Mật khẩu đã được đổi!</h2>
        <p className="text-sm text-stone-500">
          Đang chuyển về trang đăng nhập…
        </p>
        <div className="h-1 bg-stone-100 rounded-full overflow-hidden">
          <div className="h-full bg-red-900 rounded-full animate-[shrink_3s_linear_forwards]" />
        </div>
      </div>
    </div>
  )

  // ── Form nhập mật khẩu mới ────────────────────────────────────────────────
  return (
    <div className="min-h-screen flex items-center justify-center px-4">
      <div className="w-full max-w-sm">
        <div className="text-center mb-8">
          <div className="inline-flex items-center justify-center w-16 h-16 rounded-2xl bg-red-900 mb-4">
            <span className="text-2xl text-yellow-300">༄</span>
          </div>
          <h1 className="text-2xl font-bold text-stone-900">Đặt lại mật khẩu</h1>
          <p className="text-sm text-stone-500 mt-1">Nyingmapa Calendar CMS</p>
        </div>

        <form
          onSubmit={handleReset}
          className="bg-white rounded-2xl shadow-sm border border-stone-200 p-8 space-y-4"
        >
          {error && (
            <div className="bg-red-50 text-red-700 text-sm px-4 py-3 rounded-lg">
              {error}
            </div>
          )}

          {/* Mật khẩu mới */}
          <div>
            <label className="block text-sm font-medium text-stone-700 mb-1">
              Mật khẩu mới
            </label>
            <div className="relative">
              <input
                type={showPassword ? 'text' : 'password'}
                value={password}
                onChange={e => setPassword(e.target.value)}
                required
                autoFocus
                minLength={8}
                className="w-full px-3 py-2 border border-stone-300 rounded-lg text-sm pr-10 focus:outline-none focus:ring-2 focus:ring-red-900 focus:border-transparent"
                placeholder="Ít nhất 8 ký tự"
              />
              <button
                type="button"
                onClick={() => setShowPassword(p => !p)}
                className="absolute right-3 top-1/2 -translate-y-1/2 text-stone-400 hover:text-stone-700"
              >
                {showPassword ? (
                  <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2}
                      d="M13.875 18.825A10.05 10.05 0 0112 19c-4.478 0-8.268-2.943-9.543-7a9.97 9.97 0 011.563-3.029m5.858.908a3 3 0 114.243 4.243M9.878 9.878l4.242 4.242M9.88 9.88l-3.29-3.29m7.532 7.532l3.29 3.29M3 3l3.59 3.59m0 0A9.953 9.953 0 0112 5c4.478 0 8.268 2.943 9.543 7a10.025 10.025 0 01-4.132 5.411m0 0L21 21" />
                  </svg>
                ) : (
                  <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2}
                      d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2}
                      d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z" />
                  </svg>
                )}
              </button>
            </div>
            {/* Password strength indicator */}
            {password.length > 0 && (
              <div className="mt-2 space-y-1">
                <div className="flex gap-1">
                  {[1,2,3,4].map(i => (
                    <div
                      key={i}
                      className={`h-1 flex-1 rounded-full transition-colors ${
                        passwordStrength(password) >= i
                          ? i <= 1 ? 'bg-red-500' : i <= 2 ? 'bg-amber-500' : i <= 3 ? 'bg-yellow-400' : 'bg-green-500'
                          : 'bg-stone-200'
                      }`}
                    />
                  ))}
                </div>
                <p className={`text-xs ${
                  passwordStrength(password) <= 1 ? 'text-red-500' :
                  passwordStrength(password) <= 2 ? 'text-amber-600' :
                  passwordStrength(password) <= 3 ? 'text-yellow-600' : 'text-green-600'
                }`}>
                  {['', 'Yếu', 'Trung bình', 'Khá', 'Mạnh'][passwordStrength(password)]}
                </p>
              </div>
            )}
          </div>

          {/* Xác nhận mật khẩu */}
          <div>
            <label className="block text-sm font-medium text-stone-700 mb-1">
              Xác nhận mật khẩu
            </label>
            <input
              type={showPassword ? 'text' : 'password'}
              value={confirm}
              onChange={e => setConfirm(e.target.value)}
              required
              className={`w-full px-3 py-2 border rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-red-900 focus:border-transparent ${
                confirm && password !== confirm
                  ? 'border-red-400 bg-red-50'
                  : 'border-stone-300'
              }`}
              placeholder="Nhập lại mật khẩu"
            />
            {confirm && password !== confirm && (
              <p className="text-xs text-red-500 mt-1">Mật khẩu không khớp</p>
            )}
          </div>

          <button
            type="submit"
            disabled={loading || (!!confirm && password !== confirm)}
            className="w-full bg-red-900 text-white py-2.5 rounded-lg font-semibold text-sm hover:bg-red-800 transition-colors disabled:opacity-60 mt-2"
          >
            {loading ? 'Đang lưu…' : 'Đặt lại mật khẩu'}
          </button>
        </form>
      </div>
    </div>
  )
}

function passwordStrength(pwd: string): number {
  let score = 0
  if (pwd.length >= 8)  score++
  if (pwd.length >= 12) score++
  if (/[A-Z]/.test(pwd) && /[a-z]/.test(pwd)) score++
  if (/[0-9]/.test(pwd) || /[^A-Za-z0-9]/.test(pwd)) score++
  return score
}
