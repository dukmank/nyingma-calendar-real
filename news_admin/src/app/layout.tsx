import type { Metadata } from 'next'
import './globals.css'

export const metadata: Metadata = {
  title: 'Nyingmapa News Admin',
  description: 'Content management for Nyingmapa Calendar news',
}

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body className="bg-stone-50 min-h-screen">{children}</body>
    </html>
  )
}
