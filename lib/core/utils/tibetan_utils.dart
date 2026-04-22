/// Tibetan language utility functions for number and month conversion.
library tibetan_utils;

// ── Numerals ───────────────────────────────────────────────────────────────────

const _tibDigits = ['༠', '༡', '༢', '༣', '༤', '༥', '༦', '༧', '༨', '༩'];

/// Convert an integer to Tibetan numeral string.
/// e.g. toTibNum(2026) → "༢༠༢༦", toTibNum(30) → "༣༠"
String toTibNum(int n) => n.toString().split('').map((d) {
      final i = int.tryParse(d);
      return i != null ? _tibDigits[i] : d;
    }).join();

// ── Gregorian Month Names ──────────────────────────────────────────────────────

const _tibMonthFull = [
  '',
  'ཟླ་དང་པོ།',    // January
  'ཟླ་གཉིས་པ།',   // February
  'ཟླ་གསུམ་པ།',   // March
  'ཟླ་བཞི་པ།',    // April
  'ཟླ་ལྔ་པ།',     // May
  'ཟླ་དྲུག་པ།',   // June
  'ཟླ་བདུན་པ།',   // July
  'ཟླ་བརྒྱད་པ།',  // August
  'ཟླ་དགུ་པ།',    // September
  'ཟླ་བཅུ་པ།',    // October
  'ཟླ་བཅུ་གཅིག་པ།', // November
  'ཟླ་བཅུ་གཉིས་པ།', // December
];

/// Gregorian month number (1–12) → full Tibetan month name.
String tibMonthFull(int m) =>
    (m >= 1 && m <= 12) ? _tibMonthFull[m] : '';

/// Gregorian month number (1–12) → short label (ཟླ་༡ … ཟླ་༡༢).
String tibMonthShort(int m) => 'ཟླ་${toTibNum(m)}';

// ── Weekdays ───────────────────────────────────────────────────────────────────

/// English weekday name → full Tibetan weekday name.
String tibWeekday(String en) {
  switch (en.toLowerCase()) {
    case 'monday':    return 'གཟའ་ཟླ་བ།';
    case 'tuesday':   return 'གཟའ་མིག་དམར།';
    case 'wednesday': return 'གཟའ་ལྷག་པ།';
    case 'thursday':  return 'གཟའ་ཕུར་བུ།';
    case 'friday':    return 'གཟའ་པ་སངས།';
    case 'saturday':  return 'གཟའ་སྤེན་པ།';
    case 'sunday':    return 'གཟའ་ཉི་མ།';
    default:          return en;
  }
}

/// Calendar grid column headers: Sun=0, Mon=1, … Sat=6 → single Tibetan label.
/// Mirrors the S M T W T F S pattern in English.
const tibWeekdayLetters = [
  'ཉི', // Sun
  'ཟླ', // Mon
  'མིག', // Tue
  'ལྷག', // Wed
  'ཕུར', // Thu
  'སངས', // Fri
  'སྤེན', // Sat
];
