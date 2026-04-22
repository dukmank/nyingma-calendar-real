import { NextRequest, NextResponse } from 'next/server'

export async function POST(req: NextRequest) {
  try {
    // ── 1. Kiểm tra credentials ─────────────────────────────────────────────
    const B2_KEY_ID     = process.env.B2_KEY_ID
    const B2_APP_KEY    = process.env.B2_APP_KEY
    const B2_BUCKET_ID  = process.env.B2_BUCKET_ID
    const B2_PUBLIC_URL = process.env.B2_PUBLIC_URL

    if (!B2_KEY_ID || !B2_APP_KEY || !B2_BUCKET_ID || !B2_PUBLIC_URL) {
      return NextResponse.json(
        { error: 'B2 chưa được cấu hình. Thêm B2_KEY_ID, B2_APP_KEY, B2_BUCKET_ID, B2_PUBLIC_URL vào .env.local rồi restart server.' },
        { status: 500 }
      )
    }

    // ── 2. Lấy file từ form ────────────────────────────────────────────────
    const formData = await req.formData()
    const file = formData.get('file') as File | null
    if (!file) {
      return NextResponse.json({ error: 'Không có file được gửi lên.' }, { status: 400 })
    }

    // ── 3. Authorize với B2 ────────────────────────────────────────────────
    const creds = Buffer.from(`${B2_KEY_ID}:${B2_APP_KEY}`).toString('base64')
    const authRes = await fetch('https://api.backblazeb2.com/b2api/v3/b2_authorize_account', {
      headers: { Authorization: `Basic ${creds}` },
    })

    if (!authRes.ok) {
      const authErr = await authRes.text()
      return NextResponse.json(
        { error: `B2 auth thất bại (${authRes.status}): ${authErr}` },
        { status: 500 }
      )
    }

    const auth = await authRes.json()

    // B2 v3 response: auth.apiInfo.storageApi.apiUrl
    const apiUrl: string | undefined =
      auth?.apiInfo?.storageApi?.apiUrl ?? auth?.apiUrl
    const authToken: string | undefined = auth?.authorizationToken

    if (!apiUrl || !authToken) {
      return NextResponse.json(
        { error: `B2 trả về response không hợp lệ: ${JSON.stringify(auth)}` },
        { status: 500 }
      )
    }

    // ── 4. Lấy upload URL ─────────────────────────────────────────────────
    const urlRes = await fetch(`${apiUrl}/b2api/v3/b2_get_upload_url`, {
      method: 'POST',
      headers: {
        Authorization: authToken,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ bucketId: B2_BUCKET_ID }),
    })

    if (!urlRes.ok) {
      const urlErr = await urlRes.text()
      return NextResponse.json(
        { error: `Không lấy được upload URL từ B2 (${urlRes.status}): ${urlErr}` },
        { status: 500 }
      )
    }

    const uploadData = await urlRes.json()

    if (!uploadData.uploadUrl || !uploadData.authorizationToken) {
      return NextResponse.json(
        { error: `B2 upload URL response không hợp lệ: ${JSON.stringify(uploadData)}` },
        { status: 500 }
      )
    }

    // ── 5. Upload file ────────────────────────────────────────────────────
    const bytes = await file.arrayBuffer()
    // Làm sạch tên file: bỏ dấu cách, ký tự đặc biệt
    const safeName = file.name
      .replace(/\s+/g, '-')
      .replace(/[^a-zA-Z0-9._-]/g, '')
      || 'image.jpg'
    const fileName = `news/${Date.now()}-${safeName}`

    const fetchOptions: RequestInit & { duplex?: string } = {
      method: 'POST',
      headers: {
        Authorization: uploadData.authorizationToken,
        'X-Bz-File-Name': encodeURIComponent(fileName),
        'Content-Type': file.type || 'image/jpeg',
        'X-Bz-Content-Sha1': 'do_not_verify',
      },
      body: bytes as BodyInit,
      duplex: 'half',
    }
    const uploadRes = await fetch(uploadData.uploadUrl, fetchOptions)

    if (!uploadRes.ok) {
      const uploadErr = await uploadRes.text()
      return NextResponse.json(
        { error: `Upload lên B2 thất bại (${uploadRes.status}): ${uploadErr}` },
        { status: 500 }
      )
    }

    const publicUrl = `${B2_PUBLIC_URL}/${fileName}`
    return NextResponse.json({ url: publicUrl })

  } catch (e: unknown) {
    const msg = e instanceof Error ? e.message : String(e)
    return NextResponse.json({ error: `Lỗi server: ${msg}` }, { status: 500 })
  }
}
