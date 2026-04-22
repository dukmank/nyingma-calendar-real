# Nyingmapa Calendar — JSON Architecture & Script Design

> Generated: 2026-04-12 | Based on: `04_12_ Nyingmapa_Calendar.xlsx`

---

## 1. Tổng quan dữ liệu

| Nguồn | Số lượng |
|---|---|
| Ngày trong năm (daily_full) | 356 ngày (Feb 18, 2026 → Feb 8, 2027) |
| Sự kiện (events) | 162 events, 4 loại category |
| Auspicious days | 70 ngày, 7 loại |
| Reference sheets | 16 sheets (popup tables) |
| Astrology cards | 9 loại / ngày |

---

## 2. Cấu trúc file JSON output

```
/data/
├── calendar/
│   ├── daily_2026_02.json       ← 11 ngày (Feb 18–28)
│   ├── daily_2026_03.json       ← 31 ngày
│   ├── daily_2026_04.json
│   ├── ...                      ← 1 file / tháng
│   └── daily_2027_02.json       ← 8 ngày (Feb 1–8)
│
├── auspicious_index.json        ← Index auspicious days cho tab Auspicious
├── events_index.json            ← Tất cả events cho tab Events
│
└── reference/
    ├── astrology_cards_ref.json ← Metadata 9 astrology card types
    ├── auspicious_days_ref.json ← 7 auspicious day types + mô tả
    ├── naga_days.json
    ├── flag_days.json
    ├── hair_cutting.json
    ├── horse_death.json
    ├── fire_rituals.json
    ├── daily_restrictions.json
    ├── empty_vase.json
    ├── torma_offerings.json
    ├── auspicious_timing.json
    ├── life_force_male.json
    ├── life_force_female.json
    ├── eye_twitching.json
    ├── fatal_weekdays.json
    └── gu_mig.json
```

**Lý do chia theo tháng:**
- Flutter lazy-load: chỉ tải tháng hiện tại + tháng kế
- File mỗi tháng ~25–40KB (gzip ~8KB) — load nhanh trên mobile
- Reference files load 1 lần khi app khởi động, cache toàn bộ

---

## 3. Schema chi tiết

### 3.1 `daily_YYYY_MM.json` — Dữ liệu hàng ngày

```json
{
  "meta": {
    "year": 2026,
    "month": "FEB",
    "tibetan_year": 2153,
    "generated_at": "2026-04-12T00:00:00Z"
  },
  "days": [
    {
      "date": "2026-02-18",
      "gregorian": {
        "year": 2026,
        "month": "FEB",
        "day": 18,
        "day_of_week": "Wednesday",
        "year_bo": "༢༠༢༦",
        "month_bo": "ཕྱི་ཟླ་གཉིས་པ།",
        "date_bo": "༡༨",
        "day_of_week_bo": "ལྷག་པ།"
      },
      "tibetan": {
        "year": 2153,
        "month": 1,
        "month_name": "Chu-Dawa",
        "animal_month": "Dragon",
        "day": 1,
        "year_bo": "༢༡༥༣",
        "month_bo": "༡༽",
        "month_name_bo": "མཆུ་ཟླ་བ།",
        "animal_month_bo": "འབྲུག་ཟླ།",
        "day_bo": "༡༽"
      },
      "daily_image": "losar",
      "auspicious_day": {
        "name_en": "Tibetan New Year (Losar)",
        "name_bo": "དུས་ཚིག",
        "short_desc_en": "The start of the Tibetan lunar calendar...",
        "short_desc_bo": "བོད་ཀྱི་ཟླ་ཐོའི་དབུ་བརྙེས་པའི་དུས་བཟང་..."
      },
      "lunar_status": {
        "en": "LOSAR",
        "bo": "ལོ་གསར།"
      },
      "day_significance": {
        "en": "Losar – Lunar New Year (Start of Chötrul Düchen)...",
        "bo": "..."
      },
      "element_combo": {
        "combo_en": "Water-Water",
        "combo_bo": "ཆུ་ཆུ།",
        "meaning_en": "Ambrosia: Strengthens healthy long life; good for business...",
        "meaning_bo": "བདུད་རྩི། ..."
      },
      "astrology": {
        "naga_day": {
          "status_en": "avoid",
          "status_bo": "ངན།",
          "image": "astrology_naga_days_sleep",
          "popup_ref": "naga-sleep_popup_ref"
        },
        "flag_day": {
          "status_en": "auspicious",
          "status_bo": "བཟང་།",
          "image": "astrology_flag_days",
          "popup_ref": "flag_popup_ref"
        },
        "fire_ritual": {
          "status_en": "avoid",
          "status_bo": "ངན།",
          "image": "astrology_fire_rituals",
          "popup_ref": "fire_popup_ref"
        },
        "torma_offering": {
          "status_en": "southwest",
          "status_bo": "ལྷོ་ནུབ།",
          "image": "astrology_torma_offerings",
          "popup_ref": "torma_popup_ref"
        },
        "empty_vase": {
          "status_en": "south",
          "status_bo": "ལྷོ།",
          "image": "astrology_empty_vase",
          "popup_ref": "empty_vase_popup_ref"
        },
        "hair_cutting": {
          "status_en": "auspicious",
          "status_bo": "བཟང་།",
          "image": "astrology_hair_cutting",
          "popup_ref": "hair_cutting_popup_ref"
        },
        "inauspicious_day": {
          "status_en": "not_applicable",
          "status_bo": "འབྲེལ་བ་མེད་པ།",
          "image": "astrology_horse_death",
          "popup_ref": "horse_death_popup_ref"
        },
        "daily_restriction": {
          "status_en": "avoid Hosting Guests",
          "status_bo": "མགྲོན་པོ་བསུ་བར་འཛེམ།",
          "image": "astrology_daily_restrictions_guest",
          "popup_ref": "daily_restrictions_popup_ref"
        },
        "auspicious_time": {
          "status_en": "8:00 AM · 3:00 PM · 7:00 PM · 2:00 AM",
          "status_bo": "སྔ་དྲོ་ཆུ་ཚོད་ ༨:༠༠ / ...",
          "image": "astrology_auspicious_time",
          "popup_ref": "auspicious_time_popup_ref"
        }
      },
      "events": [
        {
          "name_en": "Tibetan New Year (Losar)",
          "name_bo": "དུས་ཚིག",
          "image": "losar",
          "category_en": "Annual Festival",
          "category_bo": "ལོ་རེའི་དུས་སྟོན།",
          "details_en": "Om! To the deities of the wondrous...",
          "details_bo": "ༀ༔ ངོ་མཚར་བཀྲ་ཤིས་ཞིང་གི་ལྷ་རྣམས་ལ། ..."
        }
      ]
    }
  ]
}
```

**Ghi chú:**
- `daily_image`: có thể là `string` (key ảnh đặc biệt) hoặc `integer` 1–8 (rotation ảnh thường ngày)
- `auspicious_day`: `null` nếu ngày thường (không phải ngày đặc biệt)
- `lunar_status`: `null` nếu không có
- `events`: array rỗng `[]` nếu ngày không có event

---

### 3.2 `auspicious_index.json` — Index cho tab Auspicious

```json
{
  "year": 2026,
  "tibetan_year": 2153,
  "days": [
    {
      "date": "2026-02-18",
      "gregorian_display": "Feb 18, 2026",
      "tibetan_display": "Day 1, Month 1, 2153",
      "type_key": "losar",
      "name_en": "Tibetan New Year (Losar)",
      "name_bo": "དུས་ཚིག",
      "short_desc_en": "The start of the Tibetan lunar calendar...",
      "short_desc_bo": "...",
      "image": "losar"
    },
    {
      "date": "2026-02-25",
      "gregorian_display": "Feb 25, 2026",
      "tibetan_display": "Day 8, Month 1, 2153",
      "type_key": "medicine_buddha_day",
      "name_en": "Medicine Buddha Day",
      "name_bo": "སངས་རྒྱས་སྨན་ལྷའི་ཉིན་མོ།",
      "short_desc_en": "A day dedicated to healing prayers...",
      "short_desc_bo": "...",
      "image": "auspicious_days_medicinebuddha"
    }
  ]
}
```

**Mục đích:** Tab Auspicious cần biết ngày nào gần nhất, hiển thị countdown "In X Days". File này nhỏ (~70 entries), load toàn bộ một lần khi mở tab.

---

### 3.3 `events_index.json` — Index cho tab Events

```json
{
  "year": 2026,
  "categories": ["Annual Festival", "Birthday", "Parinirvana", "Odisha Dudjom Vihara"],
  "events": [
    {
      "id": "2026-02-18-0",
      "date": "2026-02-18",
      "gregorian_display": "Feb 18, 2026",
      "tibetan_display": "Day 1st, Month 1st, 2153",
      "name_en": "Tibetan New Year (Losar)",
      "name_bo": "དུས་ཚིག",
      "image": "losar",
      "category_en": "Annual Festival",
      "category_bo": "ལོ་རེའི་དུས་སྟོན།",
      "details_en": "...",
      "details_bo": "..."
    }
  ]
}
```

**Mục đích:** Tab Events filter theo tháng + category. File này có ~162 events, Flutter filter client-side.

---

### 3.4 `reference/astrology_cards_ref.json` — Metadata 9 card types

```json
{
  "cards": [
    {
      "key": "naga_day",
      "name_en": "Naga Days",
      "name_bo": "༈ ཀླུ་ཐེབས།",
      "main_image": "astrology_naga_days_major",
      "short_description_en": "According to Tibetan astrology, there are specific auspicious days...",
      "short_description_bo": "...",
      "popup_table_title_en": "Naga Activity Days",
      "popup_table_title_bo": "..."
    }
  ]
}
```

---

### 3.5 `reference/[sheet_name].json` — Popup reference tables

Mỗi reference sheet được serialize nguyên cấu trúc table dưới dạng:

```json
{
  "popup_ref": "naga-sleep_popup_ref",
  "title_en": "Naga Activity Days",
  "title_bo": "...",
  "rows": [
    { "col1": "value", "col2": "value", ... }
  ]
}
```

---

## 4. Script Architecture

```
excel_to_json.py
│
├── ExcelReader          ← load workbook, detect header rows
│
├── DailyParser          ← parse daily_full → per-month files
│   ├── parse_gregorian()
│   ├── parse_tibetan()
│   ├── parse_astrology()   ← 9 card fields → nested dict
│   ├── parse_events()      ← first/second/third/fourth → array
│   └── normalize_image()   ← int→str, strip ext, lowercase
│
├── IndexBuilder
│   ├── build_auspicious_index()   → auspicious_index.json
│   └── build_events_index()       → events_index.json
│
├── ReferenceParser      ← parse 16 reference sheets
│   └── parse_table()    ← generic table → JSON rows
│
└── Writer
    ├── write_monthly()    → calendar/daily_YYYY_MM.json
    ├── write_indexes()    → auspicious_index + events_index
    └── write_references() → reference/*.json
```

---

## 5. Quy tắc normalize data

| Vấn đề | Xử lý |
|---|---|
| Float dates (`2026.0`) | `int(val)` |
| `null` string | `None` → JSON `null` |
| `daily_image` số 1–8 | `int(val)` giữ nguyên (Flutter handle: `"${val.toInt()}.webp"`) |
| `daily_image` string | lowercase, strip |
| Cột `_en` (không phải `_eng`) | Match theo suffix `_en` |
| 4 events per day | Flatten thành array, bỏ `null` entry |
| `popup_ref` | Giữ nguyên string key |
| Tibetan text | UTF-8, không modify |

---

## 6. Flutter data loading strategy

```
App start:
  └── Load reference/*.json (16 files, ~200KB total) → cache

Tab Calendar open:
  └── Load daily_YYYY_MM.json (current month) → cache
  └── Prefetch next month in background

Tab Auspicious open:
  └── Load auspicious_index.json (1 file, ~15KB) → cache

Tab Events open:
  └── Load events_index.json (1 file, ~80KB) → cache

User taps day:
  └── Read from cached monthly JSON (instant)

User taps astrology card:
  └── Read popup_ref key → look up in cached reference file (instant)
```

---

## 7. Checklist script output

- [ ] `calendar/daily_2026_02.json` → 11 days
- [ ] `calendar/daily_2026_03.json` → 31 days
- [ ] `calendar/daily_2026_04.json` → 30 days
- [ ] `calendar/daily_2026_05.json` → 31 days
- [ ] `calendar/daily_2026_06.json` → 30 days
- [ ] `calendar/daily_2026_07.json` → 31 days
- [ ] `calendar/daily_2026_08.json` → 31 days
- [ ] `calendar/daily_2026_09.json` → 30 days
- [ ] `calendar/daily_2026_10.json` → 31 days
- [ ] `calendar/daily_2026_11.json` → 30 days
- [ ] `calendar/daily_2026_12.json` → 31 days
- [ ] `calendar/daily_2027_01.json` → 31 days
- [ ] `calendar/daily_2027_02.json` → 8 days
- [ ] `auspicious_index.json` → 70 entries
- [ ] `events_index.json` → 162 entries
- [ ] `reference/` → 16 files
