'use client'
import { useEffect, useState } from 'react'
import { supabase } from '@/lib/supabase'
import { useRouter } from 'next/navigation'

export default function DashboardLayout({ children }: { children: React.ReactNode }) {
  const router = useRouter()
  const [checking, setChecking] = useState(true)
  const [email, setEmail] = useState('')

  useEffect(() => {
    supabase.auth.getSession().then(({ data }) => {
      if (!data.session) {
        router.replace('/')
      } else {
        setEmail(data.session.user.email ?? '')
        setChecking(false)
      }
    })
  }, [router])

  async function handleLogout() {
    await supabase.auth.signOut()
    router.replace('/')
  }

  if (checking) return (
    <div className="min-h-screen flex items-center justify-center">
      <div className="animate-spin rounded-full h-8 w-8 border-2 border-red-900 border-t-transparent" />
    </div>
  )

  return (
    <div className="min-h-screen flex flex-col">
      {/* Top nav */}
      <header className="bg-white border-b border-stone-200 px-6 py-3 flex items-center justify-between">
        <div className="flex items-center gap-3">
          <span className="text-xl text-red-900">༄</span>
          <span className="font-bold text-stone-900 text-sm">Nyingmapa News Admin</span>
        </div>
        <div className="flex items-center gap-4 text-sm text-stone-600">
          <span>{email}</span>
          <button
            onClick={handleLogout}
            className="text-red-700 hover:text-red-900 font-medium"
          >
            Sign out
          </button>
        </div>
      </header>
      <main className="flex-1 max-w-5xl mx-auto w-full px-6 py-8">{children}</main>
    </div>
  )
}
