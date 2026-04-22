# Nyingmapa Calendar — Deploy Notes

## Cập nhật data JSON lên B2

```bash
cd scripts
./deploy.sh
```

Chỉ cần chạy lệnh này mỗi khi có data mới. Script tự động:
1. Hash tất cả file trong `assets/data/` → tạo `manifest.json`
2. Upload chỉ những file thay đổi lên B2 (`data/` folder)
3. Upload `manifest.json` mới lên `data/manifest.json`

App sẽ tự nhận bản mới ở lần khởi động tiếp theo.

---

## Cấu trúc B2 bucket (`nyingma-assets2`)

```
data/
  manifest.json          ← app đọc cái này đầu tiên mỗi khi mở
  calendar/2026_04.json
  day_details/2026-04-17.json
  astrology/...
  auspicious/auspicious.json
  events/events.json
  reference/...
images/
  losar.webp             ← flat, không có subfolder
  ...
```

CDN base URL: `https://f005.backblazeb2.com/file/nyingma-assets2`

---

## rclone config (đã setup)

```
account = 0057796b6ab98bc0000000003   ← keyID (bắt đầu bằng 0057...)
key     = K005+QMZNaGN6WcBCBkIkiIfvlQlJU0   ← applicationKey
bucket  = nyingma-assets2
```

Nếu bị lỗi 401 sau này → vào Backblaze tạo key mới, chạy lại:
```bash
rclone config delete b2
rclone config create b2 b2 account <keyID> key <applicationKey>
```

---

## Quan trọng — Flow data của app

- **Lần đầu cài app**: bắt buộc phải có mạng để download data từ B2
- **Sau lần đầu**: offline vẫn chạy được (đọc từ local cache)
- **Không còn bundled data**: `assets/data/` đã bị xoá, không có fallback local

Nếu muốn thêm data mới cho năm tiếp theo → chạy `excel_to_json.py` → chạy `deploy.sh`.

---

## Upload ảnh lên B2

```bash
cd scripts
./deploy.sh --images
```

Ảnh cần được convert sang `.webp` trước bằng `prepare_images.py`.
Ảnh được upload **flat** vào bucket root (không có subfolder), tên file = imageKey.

---

## Lỗi thường gặp

| Lỗi | Nguyên nhân | Fix |
|-----|-------------|-----|
| `401 bad_auth_token` | account/key bị swap hoặc sai | Kiểm tra: account = keyID (bắt đầu `0057`), key = applicationKey (bắt đầu `K005`) |
| `403 unknown` khi upload | Key không có quyền ghi vào path đó | Tạo key mới, để trống File Name Prefix |
| App không load được data | Lần đầu cài không có mạng | Cần internet lần đầu |
