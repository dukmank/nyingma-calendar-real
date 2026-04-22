// Backblaze B2 direct upload via pre-signed URL
// The admin calls our Next.js API route which signs the URL server-side.

export async function uploadImageToB2(file: File): Promise<string> {
  const formData = new FormData()
  formData.append('file', file)

  const res = await fetch('/api/upload', { method: 'POST', body: formData })
  if (!res.ok) {
    const err = await res.json()
    throw new Error(err.error ?? 'Upload failed')
  }
  const data = await res.json()
  return data.url as string
}
