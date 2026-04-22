class TibetanInfo {
  // Tibetan numeral strings (for Tibetan-script display)
  final String? day;
  final String? month;
  final String? year;

  // English plain-text fields
  final String? dayEn;          // e.g. "15"
  final String? monthEn;        // e.g. "1"
  final String? monthNameEn;    // e.g. "Wo-Dawa"
  final String? yearEn;         // e.g. "2153"
  final String? yearNameEn;     // e.g. "Fire Horse"
  final String? animalMonthEn;  // e.g. "Snake"

  // Tibetan-script text fields (parallel to En fields above)
  final String? monthNameBo;    // e.g. "དབོ་ཟླ་བ།"
  final String? yearNameBo;     // e.g. "མེ་ཕོ་རྟ་ལོ།"
  final String? animalMonthBo;  // e.g. "སྦྲུལ་ཟླ།"

  // Legacy / derived fields
  final String? animalYear;
  final String? elementYear;

  const TibetanInfo({
    this.day,
    this.month,
    this.year,
    this.dayEn,
    this.monthEn,
    this.monthNameEn,
    this.yearEn,
    this.yearNameEn,
    this.animalMonthEn,
    this.monthNameBo,
    this.yearNameBo,
    this.animalMonthBo,
    this.animalYear,
    this.elementYear,
  });
}
