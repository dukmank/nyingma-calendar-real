#!/usr/bin/env python3
"""
stage_images.py — Map source images to their correct image_key names
and copy/convert them to b2_upload/images/ ready for B2 upload.

The Excel uses specific image_key values (e.g. 'auspicious_days_dakini',
'parinirvana_dilgo_khyentse') but source files have different names.
This script bridges that gap using an explicit mapping table.

Usage:
    python3 scripts/stage_images.py [--dry-run]

After running:
    ./scripts/deploy.sh --images
"""

import argparse
import shutil
import sys
from pathlib import Path

try:
    from PIL import Image as PILImage
    PIL_AVAILABLE = True
except ImportError:
    PIL_AVAILABLE = False

# ── CONFIG ────────────────────────────────────────────────────────────────────

QUALITY   = 72
MAX_WIDTH = 900

# ── MAPPING: source_path (relative to source/images/) → image_key ─────────────
# Format: 'SubDir/filename.EXT': 'image_key_in_excel'

MAPPING = {
    # ── Header images (numbered) ──────────────────────────────────────────────
    'header_images/1.webp':  '1',
    'header_images/2.webp':  '2',
    'header_images/3.webp':  '3',
    'header_images/4.webp':  '4',
    'header_images/5.webp':  '5',
    'header_images/6.webp':  '6',
    'header_images/7.jpg':   '7',
    'header_images/8.webp':  '8',

    # ── Auspicious days ───────────────────────────────────────────────────────
    'Auspicious_days/dakini.PNG':           'auspicious_days_dakini',
    'Auspicious_days/dharmaprotector.PNG':  'auspicious_days_dharmaprotector',
    'Auspicious_days/fullmoon.PNG':         'auspicious_days_fullmoon',
    'Auspicious_days/medicinebuddha.PNG':   'auspicious_days_medicinebuddha',
    'Auspicious_days/newmoon.PNG':          'auspicious_days_newmoon',

    # ── Guru Rinpoche 12 manifestations ──────────────────────────────────────
    'Guru_Rinpoche_12_manefistation/janguru.PNG':   'auspicious_days_janguru',
    'Guru_Rinpoche_12_manefistation/febguru.PNG':   'auspicious_days_febguru',
    'Guru_Rinpoche_12_manefistation/marguru.PNG':   'auspicious_days_marguru',
    'Guru_Rinpoche_12_manefistation/aprilguru.PNG': 'auspicious_days_aprilguru',
    'Guru_Rinpoche_12_manefistation/mayguru.PNG':   'auspicious_days_mayguru',
    'Guru_Rinpoche_12_manefistation/junguru.PNG':   'auspicious_days_junguru',
    'Guru_Rinpoche_12_manefistation/julyguru.PNG':  'auspicious_days_julyguru',
    'Guru_Rinpoche_12_manefistation/augguru.PNG':   'auspicious_days_augguru',
    'Guru_Rinpoche_12_manefistation/sepguru.PNG':   'auspicious_days_sepguru',
    'Guru_Rinpoche_12_manefistation/octguru.PNG':   'auspicious_days_octguru',
    'Guru_Rinpoche_12_manefistation/novguru.PNG':   'auspicious_days_novguru',
    'Guru_Rinpoche_12_manefistation/decguru.PNG':   'auspicious_days_decguru',

    # ── Astrology ─────────────────────────────────────────────────────────────
    'astrology/auspicious_time.PNG':        'astrology_auspicious_time',
    'astrology/horse_death.webp':           'astrology_horse_death',
    'astrology/Naga-major.webp':            'astrology_naga_days_major',
    'astrology/Naga-minor.webp':            'astrology_naga_days_minor',
    'astrology/Naga-sleep.webp':            'astrology_naga_days_sleep',
    'astrology/empty_vase.PNG':             'astrology_empty_vase',
    'astrology/fire_deity.PNG':             'astrology_fire_rituals',
    'astrology/earth-lords(flag).PNG':      'astrology_flag_days',
    'astrology/Hair_cut.PNG':               'astrology_hair_cutting',
    'astrology/torma.PNG':                  'astrology_torma_offerings',
    'astrology/10_daily_restriction_activities/baby.webp':         'astrology_daily_restrictions_baby',
    'astrology/10_daily_restriction_activities/bride.webp':        'astrology_daily_restrictions_bride',
    'astrology/10_daily_restriction_activities/commerce.webp':     'astrology_daily_restrictions_commerce',
    'astrology/10_daily_restriction_activities/construction.webp': 'astrology_daily_restrictions_construction',
    'astrology/10_daily_restriction_activities/funerals.webp':     'astrology_daily_restrictions_funerals',
    'astrology/10_daily_restriction_activities/general.webp':      'astrology_daily_restrictions_general',
    'astrology/10_daily_restriction_activities/guest.PNG':         'astrology_daily_restrictions_guest',
    'astrology/10_daily_restriction_activities/kinship.webp':      'astrology_daily_restrictions_kinship',
    'astrology/10_daily_restriction_activities/military.webp':     'astrology_daily_restrictions_military',
    'astrology/10_daily_restriction_activities/tombs.webp':        'astrology_daily_restrictions_tombs',

    # ── Events ────────────────────────────────────────────────────────────────
    'events_2/Black_Hat_Vajra_Dance.PNG':        'black_hat_vajra_dance',
    'events_2/Cham_Dance.PNG':                   'cham_dance',
    'events_2/Chokhor_Duchen_.PNG':              'chokhor_duchen',
    'events_2/Drubchen.PNG':                     'drubchen',
    'events_2/Gutor_Commencement.PNG':           'gutor_commencement',
    'events_2/Krodhikali_.PNG':                  'krodhikali',
    'events_2/Losar.PNG':                        'losar',
    'events_2/Torma_Repelling.PNG':              'torma_repelling',
    'events_2/Translated_Words_of_the_Buddha.PNG': 'translated_words_of_the_buddha',
    'events_2/chotrul_duchen.webp':              'event_chotrul_duchen',
    'events_2/incense.PNG':                      'incense',
    'events_2/incense.PNG':                      'event_incense',   # same image, two keys
    'events_2/sawadawaduchen.webp':              'sawa_dawa_duchen',
    'Events_3/Monlam_Chenmo.PNG':                'monlam_chenmo',
    'Events_3/Nine_Bad_Omens.PNG':               'nine_bad_omens',
    'Events_3/Zangpo_Chu_Dzom.PNG':              'zangpo_chu_dzom',
    'Events_3/sawa_dawa.PNG':                    'sawa_dawa',
    'Events_3/Chokhor_Duchen.PNG':               'chokhor_duchen',   # duplicate from Events_3
    'Events_3/IMG_1758.PNG':                     'tsechu_offering',

    # ── Others ────────────────────────────────────────────────────────────────
    'others/guru.jpg':                           'guru',
    'others/monastery.webp':                     'monastery',
    'others/astrology_logo.webp':                'astrology_logo',

    # ── Parinirvana ───────────────────────────────────────────────────────────
    'parinirvana/ChatralSangye.PNG':             'chatral_sangye',
    'parinirvana/DilgoKhyentse.PNG':             'dilgo_khyentse',
    'parinirvana/Dodrupchen.PNG':                'parinirvana_1st_dodrupchen',
    'parinirvana/DudjomLingpa.PNG':              'dudjom_lingpa',
    'parinirvana/DudjomRinpoche.PNG':            'dudjom_rinpoche',
    'parinirvana/Jamyang_Khyentse_Wangpo_.PNG':  'jamyang_khyentse_wangpo',
    'parinirvana/JigmeLingpa-BookLaunch.PNG':    'event_jigmelingpa_booklaunch',
    'parinirvana/JigmePhuntsok.PNG':             'jigme_phuntsok',
    'parinirvana/JuMipham.PNG':                  'ju_mipham',
    'parinirvana/KyabjePenor.PNG':               'kyabje_penor',
    'parinirvana/LongchenRabjam.PNG':            'longchen_rabjam',
    'parinirvana/MinlingTrichen.JPG':            'parinirvana_minling_trichen',
    'parinirvana/MinlngTerchen.PNG':             'minlng_terchen',
    'parinirvana/NyoshulKhen.PNG':               'nyoshul_khen',
    'parinirvana/TaklungTsetrul.PNG':            'taklung_tsetrul',
    'parinirvana/TertonMingyur.PNG':             'terton_mingyur',
    'parinirvana/ThinleyNorbu.PNG':              'thinley_norbu',
    'parinirvana/ThulshekRipoche.PNG':           'parinirvana_thulshek_ripoche',
    'parinirvana/YangsiDudjom.PNG':              'yangsi_dudjom',
    'parinirvana/YangthangRinpoche.PNG':         'yangthang_rinpoche',
    'parinirvana/ZhenphenDawa.PNG':              'parinirvana_zhenphendawa',

    # ── Birthday ──────────────────────────────────────────────────────────────
    'Birthday/yangsi_Drubwang.webp':                               'yangsi_drubwang',
    'Birthday/Birthday._of_Kyabje_Yangshi_Dungse_Gyana_ta_Rinpoche.PNG': 'kyabje_yangshi_dungse_gyana',
    'Birthday/Birthday_of_Kyabje_Dungse_Garab_Rinpoche.PNG':      'kyabje_dungse',
    'Birthday/gold_medal_westerndate.PNG':                         'event_gold_medal_westerndate',
    # IMG files — need to be assigned by content; placeholders below
    # 'Birthday/IMG_1776.PNG': 'birthday_???',
    # 'Birthday/IMG_1777.PNG': 'birthday_???',
    # 'Birthday/IMG_1779.PNG': 'birthday_???',
    # 'Birthday/IMG_1780.PNG': 'birthday_???',
    # 'Birthday/IMG_1781.PNG': 'birthday_???',
    # 'Birthday/IMG_1782.PNG': 'birthday_???',
    # 'Birthday/IMG_1783.PNG': 'birthday_???',
    # 'Birthday/IMG_1785.PNG': 'birthday_???',
    # 'Birthday/IMG_1786.PNG': 'birthday_???',
    # 'Birthday/IMG_1787.PNG': 'birthday_???',
    # 'Birthday/IMG_1789.PNG': 'birthday_???',
}

# ── All image keys expected by the app (from Excel) ───────────────────────────
ALL_KEYS = {
    '1','2','3','4','5','6','7','8',
    'astrology_auspicious_time','astrology_daily_restrictions_baby',
    'astrology_daily_restrictions_bride','astrology_daily_restrictions_commerce',
    'astrology_daily_restrictions_construction','astrology_daily_restrictions_funerals',
    'astrology_daily_restrictions_general','astrology_daily_restrictions_guest',
    'astrology_daily_restrictions_kinship','astrology_daily_restrictions_military',
    'astrology_daily_restrictions_tombs','astrology_empty_vase','astrology_fire_rituals',
    'astrology_flag_days','astrology_hair_cutting','astrology_horse_death',
    'astrology_naga_days_major','astrology_naga_days_minor','astrology_naga_days_sleep',
    'astrology_torma_offerings',
    'auspicious_days_aprilguru','auspicious_days_augguru','auspicious_days_dakini',
    'auspicious_days_decguru','auspicious_days_dharmaprotector','auspicious_days_febguru',
    'auspicious_days_fullmoon','auspicious_days_janguru','auspicious_days_julyguru',
    'auspicious_days_junguru','auspicious_days_marguru','auspicious_days_mayguru',
    'auspicious_days_medicinebuddha','auspicious_days_newmoon','auspicious_days_novguru',
    'auspicious_days_octguru','auspicious_days_sepguru',
    'birthday_12thgyalwang','birthday_17th_karmapa','birthday_7thdzongchen',
    'birthday_anagarika_dharmapala','birthday_chokyi_nyima','birthday_dilgoyangsi',
    'birthday_drikung_kyabgon','birthday_drubwang','birthday_dzigar_kongtrul',
    'birthday_dzongchen','birthday_kangyur_rinpoche','birthday_kyabgon_gongma',
    'birthday_lama_sonam','birthday_mindrolling_jetsun','birthday_neten-chokling',
    'birthday_shechenrabjam','birthday_yongey_mingyur',
    'black_hat_vajra_dance',"buddha's_descent_from_heaven",'cham_dance',
    'chatral_sangye','chokhor_duchen','dilgo_khyentse','drubchen','dudjom_lingpa',
    'dudjom_rinpoche','dudjom_yangsi_tenzin','dzongsar_khyentse',
    'event_chotrul_duchen','event_gold_medal_westerndate','event_incense',
    'event_jigmelingpa_booklaunch','guru','gutor_commencement','handover',
    'his_holiness_the_14th_dalai_lama','incense','jamyang_khyentse_wangpo',
    'jigme_phuntsok','ju_mipham','kathok_gertse_rinpoche','krodhikali',
    'kyabje_dungse','kyabje_kathok_situ_rinpoche','kyabje_namgye_dawa','kyabje_penor',
    'kyabje_yangshi_dungse_gyana','longchen_rabjam','losar','lparinirvana_lopon_sonam_tsemo',
    'mahatma_gandhi','minlng_terchen','monlam_chenmo','nine_bad_omens','nobel_peace_prize',
    'nyoshul_khen',
    'parinirvana_16th_gyalwang_karmapa','parinirvana_1st_chetsang','parinirvana_1st_dodrupchen',
    'parinirvana_1stchungtsang','parinirvana_1stdzogchen','parinirvana_3rd_jamgon_kongtrul',
    'parinirvana_4th_tsikey_chokling','parinirvana_4thdodrupchen','parinirvana_6thdzogchen',
    'parinirvana_adzom_drukpa','parinirvana_atisa_dipamkara','parinirvana_bairo_rinpoche',
    'parinirvana_birupa','parinirvana_chagdud_tulku','parinirvana_chakdzo_tsewang_paljor',
    'parinirvana_chamchen_choje','parinirvana_chogyam_trungpa','parinirvana_dezhung_rinpoche',
    'parinirvana_do_khyentse','parinirvana_drikung_kyobpa_jigten',
    'parinirvana_dudjom_sangyum_kusho','parinirvana_gaton_ngawang','parinirvana_gelek_rinpoche',
    'parinirvana_gyalton','parinirvana_gyatrul_rinpoche','parinirvana_jamgon_kongtrul',
    'parinirvana_jamyang_khyentse','parinirvana_jamyang_loter_wangpo','parinirvana_jamyang_shyepa',
    'parinirvana_jetsongkhapa','parinirvana_jetsun_milarepa','parinirvana_jetsun_taranatha',
    'parinirvana_jomo_menmo','parinirvana_kalu_rinpoche','parinirvana_kangyur_rinpoche',
    'parinirvana_khamtrul','parinirvana_khandro_tsering_chödrön',
    'parinirvana_khenchen_pema_tsewang','parinirvana_khenpo_akhyuk',
    'parinirvana_khenpo_ngakchung','parinirvana_khenpo_shengpa','parinirvana_khenpoappey',
    'parinirvana_khyungpo','parinirvana_khön_könchok_gyalpo','parinirvana_kunkhyen_pema_karpo',
    'parinirvana_lungtok_shedrup_tenpe_nyima','parinirvana_marpa_lotsawa',
    'parinirvana_mayumrsering','parinirvana_minling_trichen','parinirvana_nam_khai_norbu',
    'parinirvana_neten_chokling','parinirvana_nyala_pema','parinirvana_nyoshul',
    'parinirvana_nyoshul_khenpo','parinirvana_orgyen_terdak_lingpa','parinirvana_patrul_rinpoche',
    'parinirvana_phagmodrupa','parinirvana_rigdzin_jikme','parinirvana_rigdzin_kumaradza',
    'parinirvana_rigdzin_kunzang_sherab','parinirvana_sachen_kunga_nyingpo',
    'parinirvana_sakya_pandita_kunga_gyaltsen','parinirvana_shechen_gyaltsab',
    'parinirvana_sogyal_rinpoche','parinirvana_soktse','parinirvana_taklung',
    'parinirvana_terchen_chokgyur_lingpa','parinirvana_terton_sogyal',
    'parinirvana_tertön_sangye_lingpa','parinirvana_the_great_fifth_dalai_lama',
    'parinirvana_thich_nhat_hanh','parinirvana_thulshek_ripoche','parinirvana_tulku_pegyal',
    'parinirvana_tulku_urgyen','parinirvana_zhenphendawa',
    'sawa_dawa','sawa_dawa_duchen','taklung_tsetrul','terton_mingyur','thinley_norbu',
    'torma_repelling','translated_words_of_the_buddha','tsechu_offering',
    'yangsi_drubwang','yangsi_dudjom','yangthang_rinpoche','zangpo_chu_dzom',
}


def convert_to_webp(src: Path, dest: Path, max_width: int, quality: int) -> bool:
    if not PIL_AVAILABLE:
        # Just copy if Pillow not available
        shutil.copy2(src, dest.with_suffix(src.suffix))
        return False
    try:
        img = PILImage.open(src)
        if img.mode in ('RGBA', 'LA'):
            img = img.convert('RGBA')
        elif img.mode != 'RGB':
            img = img.convert('RGB')
        if img.width > max_width:
            ratio = max_width / img.width
            img = img.resize((max_width, int(img.height * ratio)), PILImage.LANCZOS)
        img.save(dest, 'WEBP', quality=quality, method=6)
        return True
    except Exception as e:
        print(f'  ⚠  convert failed ({e}), copying raw')
        shutil.copy2(src, dest.with_suffix(src.suffix))
        return False


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--dry-run', action='store_true')
    args = parser.parse_args()

    script_dir  = Path(__file__).parent
    project_dir = script_dir.parent
    source_root = project_dir / 'source' / 'images'
    output_dir  = project_dir / 'b2_upload' / 'images'

    if not args.dry_run:
        output_dir.mkdir(parents=True, exist_ok=True)

    staged    = []
    skipped   = []
    not_found = []

    print('=' * 60)
    print('  Stage images → b2_upload/images/')
    print(f'  Source: {source_root}')
    print(f'  Output: {output_dir}')
    if args.dry_run:
        print('  DRY RUN — no files written')
    print('=' * 60)

    # Track which keys get covered
    covered_keys = set()

    for rel_path, image_key in MAPPING.items():
        src = source_root / rel_path
        if not src.exists():
            not_found.append((rel_path, image_key))
            continue

        dest = output_dir / f'{image_key}.webp'
        covered_keys.add(image_key)

        if dest.exists():
            skipped.append(image_key)
            continue

        if args.dry_run:
            print(f'  would stage: {rel_path} → {image_key}.webp')
            staged.append(image_key)
            continue

        ok = convert_to_webp(src, dest, MAX_WIDTH, QUALITY)
        size_kb = dest.stat().st_size // 1024 if dest.exists() else 0
        print(f'  ✅ {image_key}.webp ({size_kb} KB)')
        staged.append(image_key)

    # Report missing source files
    if not_found:
        print(f'\n⚠  {len(not_found)} source files not found on disk:')
        for rel, key in not_found:
            print(f'  {rel}  →  key: {key}')

    # Report keys with no source image at all
    missing_keys = ALL_KEYS - covered_keys
    if missing_keys:
        print(f'\n❌ {len(missing_keys)} image keys have NO source image yet:')
        for k in sorted(missing_keys):
            print(f'  {k}')

    print(f'\n{"─"*60}')
    print(f'  Staged:  {len(staged)}')
    print(f'  Skipped (already exist): {len(skipped)}')
    print(f'  Missing source: {len(not_found)}')
    print(f'  Keys with no image at all: {len(missing_keys)}')
    if not args.dry_run and staged:
        print(f'\nNext: ./scripts/deploy.sh --images')


if __name__ == '__main__':
    main()
