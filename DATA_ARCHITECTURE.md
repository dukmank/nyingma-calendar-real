# Nyingmapa Calendar — Data & Image Architecture

> Tài liệu này mô tả toàn bộ hệ thống load data và ảnh: từ Excel → Python script → B2 → Flutter app.
> Đọc file này trước khi sửa bất cứ thứ gì liên quan đến data pipeline.

---

## 1. Tổng quan kiến trúc

```
Excel (.xlsx)
    │
    ▼
scripts/excel_to_json.py          ← nguồn gốc duy nhất của tất cả data
    │
    ├── assets/data/calendar/YYYY_MM.json     (13 files — calendar grid)
    ├── assets/data/day_details/YYYY-MM-DD.json  (356 files — day detail screen)
    ├── assets/data/events_index.json         (events tab)
    ├── assets/data/auspicious_index.json     (generated, chưa dùng)
    ├── assets/data/reference/*.json          (17 files — astrology popups)
    └── scripts/manifest.json                 (hash table để sync)
    │
    ▼
Backblaze B2 bucket: nyingma-assets2
    │
    ├── data/calendar/...
    ├── data/day_details/...
    ├── data/events_index.json
    ├── data/reference/...
    ├── data/manifest.json         ← upload riêng từ scripts/manifest.json
    └── {image_key}.webp           ← ảnh flat, không subfolder
    │
    ▼
Cloudflare Worker CDN
    URL base: https://ittle-term-2262.phungducmanh18072005.workers.dev
    │
    ▼
Flutter App (RemoteDataCache + AppNetworkImage)
```

---

## 2. Hạ tầng B2 / CDN

### Bucket layout
```
nyingma-assets2/
├── data/
│   ├── manifest.json
│   ├── events_index.json
│   ├── auspicious_index.json
│   ├── calendar/
│   │   ├── 2026_02.json
│   │   ├── 2026_03.json
│   │   └── ... (13 files)
│   ├── day_details/
│   │   ├── 2026-02-18.json
│   │   └── ... (356 files)
│   └── reference/
│       ├── auspicious_days_ref.json
│       ├── astrology_cards_ref.json
│       ├── naga_days.json
│       ├── flag_days.json
│       ├── hair_cutting.json
│       ├── fire_rituals.json
│       ├── torma_offerings.json
│       ├── empty_vase.json
│       ├── daily_restrictions.json
│       ├── auspicious_timing.json
│       ├── life_force_male.json
│       ├── life_force_female.json
│       ├── horse_death.json
│       ├── eye_twitching.json
│       ├── fatal_weekdays.json
│       ├── gu_mig.json
│       └── daily_astrological_cards_ref.json
├── losar.webp
├── full_moon.webp
├── astrology_naga_days_minor.webp
└── ... (209 ảnh flat — không subfolder)
```

### CDN URL pattern
```
JSON:  https://{worker}/data/calendar/2026_04.json
Ảnh:   https://{worker}/{image_key}.webp
```

---

## 3. Hệ thống load JSON — RemoteDataCache

**File:** `lib/core/services/remote_data_cache.dart`

### Chiến lược 3 lớp (cho mỗi file JSON)

```
Lần 1 yêu cầu:
  ┌─────────────────────┐
  │  1. Memory cache     │  → HIT: trả ngay, zero I/O
  │  (Map<String,dynamic>)│
  └────────┬────────────┘
           │ MISS
  ┌────────▼────────────┐
  │  2. Local disk       │  → HIT: parse JSON, lưu vào memory
  │  Mobile/Desktop:     │
  │   Documents/nmc_data_cache/
  │   data_calendar_2026_04.json  (/ → _)
  │  Web:                │
  │   SharedPreferences  │
  │   key: nmc_json_cache__data_calendar_2026_04.json
  └────────┬────────────┘
           │ MISS
  ┌────────▼────────────┐
  │  3. Network fetch    │  → Download từ CDN, lưu disk, lưu memory
  │  cdnBaseUrl/path     │
  └─────────────────────┘
```

### Startup sync (manifest-based)

Chạy 1 lần khi app khởi động:

```
1. Fetch data/manifest.json (~40KB) — timeout 10s
2. Load stored hashes từ SharedPreferences (key: nmc_file_hashes)
3. So sánh hash từng file
4. Download chỉ các file thay đổi — batch 4 concurrent, timeout 30s/file
5. Lưu hashes mới vào SharedPreferences
```

**Manifest format:**
```json
{
  "schema_version": 1,
  "data_version": "2026.1.6",
  "files": {
    "data/calendar/2026_04.json": {
      "hash": "abc12345",
      "size_bytes": 32768,
      "updated_at": "2026-04-19T23:13:56Z"
    }
  }
}
```

**Kết quả:** App hoạt động offline hoàn toàn sau lần sync đầu tiên. Chỉ download lại khi data thay đổi.

### API

```dart
final cache = ref.watch(remoteDataCacheProvider);

// Đọc JSON (memory → disk → network)
final json = await cache.getJson('data/calendar/2026_04.json');

// Xoá toàn bộ cache
await cache.clearCache();

// Kích thước cache
final bytes = await cache.cacheSize();
```

---

## 4. Các file JSON và Flutter code đọc chúng

### 4.1 Monthly Calendar — `data/calendar/YYYY_MM.json`

**Dùng cho:** Calendar grid (chọn ngày)

**AppConstants path:**
```dart
AppConstants.calendarPath(year, month)
// → 'data/calendar/2026_04.json'
```

**Cấu trúc file:**
```json
{
  "year": 2026,
  "month": 4,
  "gregorian_month_en": "APR",
  "gregorian_month_bo": "ཕྱི་ཟླ་བཞི་པ།",
  "year_name_en": "Fire Horse",
  "year_name_bo": "མེ་ཕོ་རྟ་ལོ།",
  "days": [
    {
      "date_key": "2026-04-01",
      "gregorian_date": "1",
      "gregorian_date_bo": "༡",
      "weekday_en": "Wednesday",
      "weekday_bo": "ལྷག་པ།",
      "tibetan_day_en": "15",
      "tibetan_day_bo": "༡༥",
      "tibetan_month_en": "2",
      "tibetan_month_bo": "༢༽",
      "tibetan_month_name_en": "Wo-Dawa",
      "tibetan_month_name_bo": "དབོ་ཟླ་བ།",
      "tibetan_year_en": "2153",
      "tibetan_year_bo": "༢༡༥༣",
      "tibetan_year_name_en": "Fire Horse",
      "tibetan_year_name_bo": "མེ་ཕོ་རྟ་ལོ།",
      "animal_month_en": "Snake",
      "animal_month_bo": "སྦྲུལ་ཟླ།",
      "lunar_status_en": null,
      "image_key": "auspicious_days_fullmoon",
      "auspicious_day_name_en": "Full Moon",
      "auspicious_day_name_bo": "ཟླ་བ་ཉ་གང་།",
      "element_combo_en": "Water-Fire",
      "element_combo_bo": "ཆུ་མེ།",
      "astrology_status": {
        "naga_day": "auspicious_minor",
        "flag_day": "auspicious",
        "fire_ritual": "avoid",
        "torma_offering": "north",
        "empty_vase": "north",
        "hair_cutting": "auspicious",
        "inauspicious_day": "not_applicable",
        "daily_restriction": "avoid Family Gatherings",
        "auspicious_time": "8:00 AM · 3:00 PM"
      },
      "has_event": true
    }
  ]
}
```

**Flutter pipeline:**
```
CalendarLocalDatasource.getMonth(year, month)
  → cache.getJson(calendarPath)
  → CalendarMonthModel.fromJson(json)
    → CalendarDayModel.fromJson(dayJson, month, year)
  → CalendarDayEntity (UI)
```

**Key Flutter files:**
- `lib/features/calendar/data/datasources/calendar_local_datasource.dart`
- `lib/features/calendar/data/models/calendar_day_model.dart`

---

### 4.2 Day Detail — `data/day_details/YYYY-MM-DD.json`

**Dùng cho:** Màn hình chi tiết ngày (tap vào ngày bất kỳ)

**AppConstants path:**
```dart
AppConstants.dayDetailPath(dateKey)
// → 'data/day_details/2026-04-01.json'
```

**Cấu trúc file:**
```json
{
  "date_key": "2026-04-01",
  "tibetan_year_name_en": "Fire Horse",
  "image_key": "auspicious_days_fullmoon",

  "gregorian": {
    "year": 2026,
    "year_bo": "༢༠༢༦",
    "month_en": "APR",
    "month_bo": "ཕྱི་ཟླ་བཞི་པ།",
    "date": 1,
    "date_bo": "༡",
    "weekday_en": "Wednesday",
    "weekday_bo": "ལྷག་པ།"
  },

  "tibetan": {
    "year_en": "2153",
    "year_bo": "༢༡༥༣",
    "month_en": "2",
    "month_bo": "༢༽",
    "month_name_en": "Wo-Dawa",
    "month_name_bo": "དབོ་ཟླ་བ།",
    "animal_month_en": "Snake",
    "animal_month_bo": "སྦྲུལ་ཟླ།",
    "day_en": "15",
    "day_bo": "༡༥",
    "lunar_status_en": null,
    "lunar_status_bo": null
  },

  "significance": {
    "day_significance_en": "The Day of Amitabha Buddha",
    "day_significance_bo": "སངས་རྒྱས་འོད་དཔག་མེད་ཉིན།",
    "element_combo_en": "Water-Fire",
    "element_combo_bo": "ཆུ་མེ།",
    "meaning_of_coincidence_en": "Death: Snatches away lives; very negative coincidence.",
    "meaning_of_coincidence_bo": "འཆི་བ།"
  },

  "auspicious_day": {
    "name_en": "Full Moon",
    "name_bo": "ཟླ་བ་ཉ་གང་།",
    "short_description_en": "A powerful day for merit-making...",
    "short_description_bo": "དགེ་རྩ་གསོག་པ།..."
  },

  "astrology_cards": [
    {
      "type": "naga_day",
      "status_en": "auspicious_minor",
      "status_bo": "བཟང་།",
      "image_key": "astrology_naga_days_minor",
      "popup_ref": "naga-minor_popup_ref"
    }
  ],

  "torma_offering": {
    "direction_en": "north",
    "image_key": "astrology_torma_offerings",
    "popup_ref": "torma_popup_ref"
  },

  "empty_vase": {
    "direction_en": "north",
    "image_key": "astrology_empty_vase",
    "popup_ref": "empty_vase_popup_ref"
  },

  "daily_restriction": {
    "description_en": "avoid Family Gatherings",
    "image_key": "astrology_daily_restrictions_kinship",
    "popup_ref": "daily_restrictions_popup_ref"
  },

  "auspicious_times": {
    "description_en": "8:00 AM · 3:00 PM · 7:00 PM · 2:00 AM",
    "image_key": "astrology_auspicious_time",
    "popup_ref": "auspicious_time_popup_ref"
  },

  "events": [
    {
      "name_en": "Commencement of Teaching...",
      "name_bo": "...",
      "category_en": "Odisha Dudjom Vihara",
      "category_bo": "...",
      "details_en": null,
      "details_bo": null,
      "image_key": "handover"
    }
  ]
}
```

**Flutter pipeline:**
```
DayDetailLocalDatasource.getDayDetail(dateKey)
  → cache.getJson(dayDetailPath)
  → DayDetailModel.fromJson(json)
  → DayDetailEntity (UI)
```

**Key Flutter files:**
- `lib/features/day_detail/data/datasources/day_detail_local_datasource.dart`
- `lib/features/day_detail/data/models/day_detail_model.dart`

---

### 4.3 Events — `data/events_index.json`

**Dùng cho:** Tab Events, EventDetail screen

**AppConstants path:**
```dart
AppConstants.eventsPath
// → 'data/events_index.json'
```

**Cấu trúc file:**
```json
{
  "year": 2026,
  "count": 163,
  "categories": ["Annual Festival", "Birthday", "Parinirvana"],
  "events": [
    {
      "id": "2026-02-18-0",
      "date": "2026-02-18",
      "gregorian_display": "Feb 18, 2026",
      "tibetan_display": "Day 1st, Month 1st, 2153",
      "name_en": "Tibetan New Year (Losar)",
      "name_bo": "...",
      "image": "losar",
      "category_en": "Annual Festival",
      "category_bo": "...",
      "details_en": "...",
      "details_bo": "..."
    }
  ]
}
```

> ⚠️ **Chú ý field name:** file dùng `"image"` (không phải `"image_key"`) và `"date"` (không phải `"date_key"`).
> `EventModel.fromJson` xử lý cả hai: `json['image_key'] ?? json['image']`

**Flutter pipeline:**
```
EventsLocalDataSource.getEvents()
  → cache.getJson(eventsPath)
  → EventsRepositoryImpl: json['events'] → List<EventModel>
  → eventsProvider (FutureProvider)
  → eventByIdProvider: lookup by id OR by "YYYY-MM-DD-{index}"
```

**Key Flutter files:**
- `lib/features/events/data/datasources/events_local_datasource.dart`
- `lib/features/events/data/models/event_model.dart`
- `lib/features/events/presentation/controllers/events_controller.dart`

---

### 4.4 Auspicious Days — `data/reference/auspicious_days_ref.json`

**Dùng cho:** Tab Auspicious — description lookup

**AppConstants path:**
```dart
AppConstants.auspiciousPath
// → 'data/reference/auspicious_days_ref.json'
```

**Cấu trúc file:**
```json
{
  "types": [
    {
      "auspicious_day_name_en": "Full Moon",
      "auspicious_day_name_bo": "...",
      "short_description_en": "A powerful day for merit-making...",
      "short_description_bo": "..."
    }
  ]
}
```

**Flutter pipeline:**
```
auspiciousProvider (FutureProvider)
  → cache.getJson(auspiciousPath)         ← descriptions
  → cache.getJson(calendarPath(y, m))     ← 6 tháng upcoming days
  → filter days có auspicious_day_name_en
  → join descriptions bằng name matching (toLowerCase)
  → List<AuspiciousDay> sorted by date
```

**Key Flutter files:**
- `lib/features/auspicious/presentation/controllers/auspicious_controller.dart`

---

### 4.5 Astrology Reference — `data/reference/*.json`

**Dùng cho:** AstrologyDetailScreen (popup khi tap astrology card)

**AppConstants path:**
```dart
AppConstants.referencePath(key)
// 'auspicious_times'       → 'data/reference/auspicious_timing.json'
// 'restriction_activities' → 'data/reference/daily_restrictions.json'
// mặc định: key == tên file
```

**2 loại file được load:**

1. `data/reference/astrology_cards_ref.json` — metadata (title, description, image, table name)
2. `data/reference/{topic}.json` — data rows cho table

**Route key → file mapping** (trong `astrology_detail_screen.dart`):
```
naga_days              → data/reference/naga_days.json
hair_cutting           → data/reference/hair_cutting.json
flag_days              → data/reference/flag_days.json
horse_death            → data/reference/horse_death.json
restriction_activities → data/reference/daily_restrictions.json
fire_rituals           → data/reference/fire_rituals.json
torma_offerings        → data/reference/torma_offerings.json
empty_vase             → data/reference/empty_vase.json
life_force_male        → data/reference/life_force_male.json
life_force_female      → data/reference/life_force_female.json
eye_twitching          → data/reference/eye_twitching.json
fatal_weekdays         → data/reference/fatal_weekdays.json
gu_mig                 → data/reference/gu_mig.json
auspicious_times       → data/reference/auspicious_timing.json
```

**Flutter pipeline:**
```
_detailProvider(routeKey) FutureProvider
  → cache.getJson('data/reference/astrology_cards_ref.json')
    → match by table_en key (e.g. "naga_days_tab")
    → build _CardMeta (title, description, image)
  → cache.getJson(refJsonPath(routeKey))
    → rows[] → _buildTableData() → bilingual table
```

**Key Flutter files:**
- `lib/features/astrology/presentation/screens/astrology_detail_screen.dart`

---

## 5. Hệ thống load ảnh — AppNetworkImage

**File:** `lib/shared/widgets/app_network_image.dart`

### URL pattern
```dart
AppConstants.imageUrl('losar')
// → 'https://{worker}/losar.webp'
```

Tất cả ảnh đều **flat** trên B2 (không subfolder), tên file = `{image_key}.webp`.

### Widget

```dart
AppNetworkImage(
  imageKey: 'losar',        // không cần .webp
  width: 200,
  height: 200,
  fit: BoxFit.cover,
  borderRadius: BorderRadius.circular(12),
)
```

### Caching strategy

```
Lần 1:
  → Fetch từ CDN
  → Lưu vào flutter_cache_manager (AppCacheManager)
  → TTL: 30 ngày (override B2 default 1 hour)
  → Max 300 ảnh

Lần 2+:
  → Serve từ local cache (zero network)
```

**Cache manager config:**
```dart
// lib/core/services/app_cache_manager.dart
CacheManager(Config(
  'nyingmapaImageCache',
  stalePeriod: Duration(days: 30),
  maxNrOfCacheObjects: 300,
))
```

**Fallback khi lỗi:** icon `temple_buddhist_outlined` màu gold.

### Platform difference

| Platform | JSON cache | Ảnh cache |
|----------|-----------|-----------|
| Mobile/Desktop | Documents/nmc_data_cache/*.json | flutter_cache_manager (disk) |
| Web | SharedPreferences (localStorage) | flutter_cache_manager (IndexedDB) |

---

## 6. Quy trình cập nhật data (update Excel → production)

```bash
# 1. Thay file Excel vào source/
cp new_calendar.xlsx source/

# 2. Generate JSON
python3 scripts/excel_to_json.py
# Output: assets/data/ (388 files) + scripts/manifest.json

# 3. Upload lên B2
rclone copy assets/data/ b2:nyingma-assets2/data/ --progress
rclone copyto scripts/manifest.json b2:nyingma-assets2/data/manifest.json

# 4. (Optional) Upload ảnh mới
rclone copy b2_upload/images/ b2:nyingma-assets2/ --progress
```

Khi user mở app lần tiếp theo:
1. App fetch `manifest.json`
2. So sánh hash, phát hiện file thay đổi
3. Download chỉ những file mới
4. UI update tự động

---

## 7. AppConstants — tất cả paths

**File:** `lib/core/constants/app_constants.dart`

```dart
// CDN base
static const String cdnBaseUrl = 'https://ittle-term-2262...workers.dev';

// Manifest
static const String manifestUrl = '$cdnBaseUrl/data/manifest.json';

// JSON paths (relative — truyền vào cache.getJson)
static String calendarPath(int year, int month)
    => 'data/calendar/${year}_${month.toString().padLeft(2,'0')}.json';

static String dayDetailPath(String dateKey)
    => 'data/day_details/$dateKey.json';

static const String eventsPath     = 'data/events_index.json';
static const String auspiciousPath = 'data/reference/auspicious_days_ref.json';

static String referencePath(String key) {
  const overrides = {
    'auspicious_times':       'auspicious_timing',
    'restriction_activities': 'daily_restrictions',
  };
  return 'data/reference/${overrides[key] ?? key}.json';
}

// Image URL (full URL — truyền thẳng vào CachedNetworkImage)
static String imageUrl(String key) => '$cdnBaseUrl/$key.webp';
```

---

## 8. SharedPreferences keys

| Key | Type | Nội dung |
|-----|------|----------|
| `nmc_file_hashes` | JSON string | `{"data/calendar/2026_04.json": "abc12345", ...}` |
| `nmc_data_version` | String | `"2026.1.6"` |
| `nmc_language` | String | `"en"` hoặc `"bo"` |
| `nmc_user_profile` | JSON string | Profile data |
| `nmc_practices` | JSON array | Practice list |
| `nmc_user_events` | JSON array | User-created events |
| `nmc_onboarding_done` | bool | Onboarding completed |
| `nmc_json_cache__{path}` | JSON string | Web-only: cached JSON files |

---

## 9. Lưu ý quan trọng

### Manifest không nằm trong assets/data/
`scripts/manifest.json` được generate ngoài `assets/data/` để tránh tự track chính nó. Luôn phải upload riêng:
```bash
rclone copyto scripts/manifest.json b2:nyingma-assets2/data/manifest.json
```

### Image key conventions
- Luôn dùng lowercase, underscore, không extension: `"losar"`, `"astrology_naga_days_minor"`
- Các key đặc biệt từ Excel được normalize trong `excel_to_json.py → normalize_image()`
- Số nguyên 1–8: daily rotation images (`.webp` files tên `1.webp`…`8.webp`)

### Field names trong events_index.json
File dùng `"image"` và `"date"` (không có `_key` suffix). Models xử lý bằng:
```dart
imageKey: (json['image_key'] ?? json['image']) as String?
dateKey:  (json['date_key']  ?? json['date'])  as String?
```

### auspicious_index.json
File được generate nhưng chưa được dùng bởi bất kỳ Flutter code nào. Controller đọc trực tiếp từ monthly calendar JSONs.
