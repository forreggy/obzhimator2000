#!/usr/bin/env bash
# ==============================================================================
#  OBZHIMATOR-2000 // console edition for Linux and WSL2
#  Portable conveyor-belt video squeezer: HEVC (H.265), hardware autodetect,
#  no dependencies except ffmpeg and bash 4+.
#  License: Unlicense (public domain) - see the LICENSE file.
#
#  Usage:  ./obzhimator2000.sh [--lang ru|en] [files...]
#  Messages are shown in Russian or English: taken from $LC_ALL / $LC_MESSAGES /
#  $LANG (Russian locale -> ru, anything else -> en), or forced with --lang.
# ==============================================================================

# ------------------------------------------------------------------------------
# Localization: every user-visible message lives in the S table as <lang>_<key>.
# Values are printf templates (%s = argument, %% = literal percent sign).
# To add a language, add one more block with the same keys.
# ------------------------------------------------------------------------------
declare -A S

S[ru_banner]="  ОБЖИМАТОР-2000 // консольный выпуск // HEVC + автодетект"
S[en_banner]="  OBZHIMATOR-2000 // console edition // HEVC + autodetect"

S[ru_no_ffmpeg]="Ошибка: утилита ffmpeg не установлена в системе."
S[en_no_ffmpeg]="Error: ffmpeg is not installed on this system."
S[ru_no_ffmpeg_hint]="Linux: sudo apt install ffmpeg -y   |   WSL2: тот же рецепт."
S[en_no_ffmpeg_hint]="Linux: sudo apt install ffmpeg -y   |   WSL2: same recipe."

S[ru_no_files]="В этой папке нет подходящих видеофайлов (mp4, mkv, mov, avi, webm)."
S[en_no_files]="No suitable video files in this folder (mp4, mkv, mov, avi, webm)."
S[ru_found]="Найдено файлов для сжатия: %s"
S[en_found]="Files found to squeeze: %s"

S[ru_pick]="Выберите уровень качества HEVC (коэффициент CQ / CRF):"
S[en_pick]="Pick the HEVC quality level (CQ / CRF value):"
S[ru_q28]="  28 — высокая чёткость (файл побольше)"
S[en_q28]="  28 — high clarity (bigger file)"
S[ru_q32]="  32 — баланс качества и размера (фирменный пресет, по умолчанию)"
S[en_q32]="  32 — balance of quality and size (signature preset, default)"
S[ru_q35]="  35 — максимальное сжатие (для длинных лекций и созвонов)"
S[en_q35]="  35 — maximum squeeze (for long lectures and calls)"
S[ru_prompt]="Введите число [Enter = 32]: "
S[en_prompt]="Enter a number [Enter = 32]: "
S[ru_bad_cq]="Ошибка: нужно ввести целое число (например, 28, 32 или 35)."
S[en_bad_cq]="Error: please enter a whole number (for example 28, 32 or 35)."

S[ru_checking_hw]="Проверяю доступное оборудование (кодек HEVC / H.265)..."
S[en_checking_hw]="Checking available hardware (HEVC / H.265 codec)..."
S[ru_hw_cpu]="CPU (libx265 — программное кодирование)"
S[en_hw_cpu]="CPU (libx265 — software encoding)"
S[ru_hw_chosen]="Выбран режим кодирования: %s"
S[en_hw_chosen]="Encoding mode selected: %s"

S[ru_interrupted]="[!] Прервано пользователем. Недожатый огрызок удалён."
S[en_interrupted]="[!] Interrupted by user. The under-squeezed stub was deleted."
S[ru_squeezing]=">>> Сжимаю [%s | Q=%s]: %s"
S[en_squeezing]=">>> Squeezing [%s | Q=%s]: %s"
S[ru_fail]="⚠️ Ошибка при сжатии файла: %s"
S[en_fail]="⚠️ Error while squeezing file: %s"

S[ru_sum_title]="📊 ИТОГОВАЯ СВОДКА (%s файл. обработано)"
S[en_sum_title]="📊 FINAL REPORT (%s file(s) processed)"
S[ru_sum_engine]="  Движок:     %s"
S[en_sum_engine]="  Engine:     %s"
S[ru_sum_before]="  Было:       %s"
S[en_sum_before]="  Before:     %s"
S[ru_sum_after]="  Стало:      %s"
S[en_sum_after]="  After:      %s"
S[ru_sum_saved]="  Экономия:   %s (%s%% меньше)"
S[en_sum_saved]="  Saved:      %s (%s%% smaller)"
S[ru_sum_time]="  Время:      %s (чч:мм:сс)"
S[en_sum_time]="  Time:       %s (hh:mm:ss)"
S[ru_sum_folder]="  Папка:      ./compressed/"
S[en_sum_folder]="  Folder:     ./compressed/"
S[ru_footer]="EOF // HAPPY COMPRESSING! // ОБЖИМАТОР-2000"
S[en_footer]="EOF // HAPPY COMPRESSING! // OBZHIMATOR-2000"

S[ru_bad_lang]="Неизвестный язык: '%s' (допустимо: ru, en)"
S[en_bad_lang]="Unknown language: '%s' (allowed: ru, en)"
S[ru_bad_opt]="Неизвестный ключ: %s (справка: --help)"
S[en_bad_opt]="Unknown option: %s (help: --help)"
S[ru_usage]=$'Использование: ./obzhimator2000.sh [--lang ru|en] [файлы...]\n  Без файлов — сжимает все видео в папке со скриптом.\n  --lang ru|en   язык сообщений (по умолчанию — по локали системы)\n  -h, --help     эта справка'
S[en_usage]=$'Usage: ./obzhimator2000.sh [--lang ru|en] [files...]\n  No files - squeezes every video in the script folder.\n  --lang ru|en   message language (default: from the system locale)\n  -h, --help     this help'

# Pick the starting language from the environment.
detect_lang() {
    local loc="${LC_ALL:-${LC_MESSAGES:-${LANG:-}}}"
    case "${loc,,}" in
        ru*) echo "ru" ;;
        *)   echo "en" ;;
    esac
}
LANG_CODE="$(detect_lang)"

# t KEY  - print the string as is (no newline), e.g. for read -p
# say KEY [ARGS...] - printf-style output of the string plus a newline
t()   { printf '%s' "${S[${LANG_CODE}_$1]}"; }
say() { local key="$1"; shift; printf -- "${S[${LANG_CODE}_${key}]}\n" "$@"; }

# ------------------------------------------------------------------------------
# Command line: --lang, --help, then file names
# ------------------------------------------------------------------------------
lang_req=""
show_help=0
files=()
while (( $# )); do
    case "$1" in
        --lang=*)  lang_req="${1#--lang=}"; shift ;;
        --lang)    shift; lang_req="${1:-}"; (( $# )) && shift ;;
        -h|--help) show_help=1; shift ;;
        --)        shift; files+=("$@"); break ;;
        -*)        say bad_opt "$1" >&2; exit 2 ;;
        *)         files+=("$1"); shift ;;
    esac
done

if [[ -n "$lang_req" ]]; then
    case "${lang_req,,}" in
        ru|en) LANG_CODE="${lang_req,,}" ;;
        *)     say bad_lang "$lang_req" >&2; exit 2 ;;
    esac
fi

if (( show_help )); then
    say usage
    exit 0
fi

# ------------------------------------------------------------------------------
# Preparation
# ------------------------------------------------------------------------------
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
cd "$SCRIPT_DIR" || exit 1

if ! command -v ffmpeg &> /dev/null; then
    say no_ffmpeg
    say no_ffmpeg_hint
    exit 1
fi

shopt -s nullglob nocaseglob
if (( ${#files[@]} == 0 )); then
    files=(*.mp4 *.mkv *.mov *.avi *.webm)
fi
shopt -u nullglob nocaseglob

if (( ${#files[@]} == 0 )); then
    say no_files
    exit 1
fi

echo "=========================================================="
say banner
echo "=========================================================="
say found "${#files[@]}"
say pick
say q28
say q32
say q35
read -rp "$(t prompt)" cq
cq=${cq:-32}
if [[ ! "$cq" =~ ^[0-9]+$ ]]; then
    say bad_cq
    exit 1
fi

# ------------------------------------------------------------------------------
# Hardware autodetect: NVENC -> QSV -> VAAPI -> CPU
# ------------------------------------------------------------------------------
echo ""
say checking_hw
HW_MODE="CPU"
INPUT_ARGS=()
VIDEO_ARGS=()

# 1. NVIDIA NVENC (HEVC)
if ffmpeg -nostdin -hide_banner -loglevel error -f lavfi -i color=black:s=256x256:d=0.1 -c:v hevc_nvenc -f null - 2>/dev/null; then
    HW_MODE="NVIDIA GPU (hevc_nvenc)"
    VIDEO_ARGS=(-c:v hevc_nvenc -preset p7 -tune hq -rc vbr -cq "$cq" -b:v 0 -g 250 -spatial-aq 1 -temporal-aq 1 -tag:v hvc1 -pix_fmt yuv420p)
# 2. Intel QuickSync (QSV HEVC)
elif ffmpeg -nostdin -hide_banner -loglevel error -f lavfi -i color=black:s=256x256:d=0.1 -c:v hevc_qsv -f null - 2>/dev/null; then
    HW_MODE="Intel GPU (hevc_qsv)"
    VIDEO_ARGS=(-c:v hevc_qsv -preset veryslow -global_quality "$cq" -g 250 -tag:v hvc1 -pix_fmt nv12)
# 3. AMD / Intel via VAAPI (Linux HEVC)
elif [[ -e /dev/dri/renderD128 ]] && ffmpeg -nostdin -hide_banner -loglevel error -vaapi_device /dev/dri/renderD128 -f lavfi -i color=black:s=256x256:d=0.1 -vf 'format=nv12,hwupload' -c:v hevc_vaapi -f null - 2>/dev/null; then
    HW_MODE="AMD / Intel GPU (hevc_vaapi)"
    INPUT_ARGS=(-vaapi_device /dev/dri/renderD128)
    VIDEO_ARGS=(-vf 'format=nv12,hwupload' -c:v hevc_vaapi -qp "$cq" -g 250 -tag:v hvc1)
# 4. CPU fallback (libx265)
else
    HW_MODE="$(t hw_cpu)"
    VIDEO_ARGS=(-c:v libx265 -preset slow -crf "$cq" -g 250 -tag:v hvc1 -pix_fmt yuv420p)
fi

say hw_chosen "$HW_MODE"
echo ""

# ------------------------------------------------------------------------------
# Helpers
# ------------------------------------------------------------------------------
SECONDS=0
mkdir -p compressed
total_in=0
total_out=0
processed=0
current_out=""

# Ctrl-C: clean up the half-made file and exit like a grown-up
on_interrupt() {
    echo ""
    say interrupted
    if [[ -n "$current_out" ]]; then rm -f "$current_out"; fi
    exit 130
}
trap on_interrupt INT TERM

# Ru uses a decimal comma (like the GUI version), en keeps the dot.
localize_num() {
    if [[ "$LANG_CODE" == "ru" ]]; then printf '%s' "${1/./,}"; else printf '%s' "$1"; fi
}

human_size() {
    local s
    s=$(LC_ALL=C awk -v bytes="$1" 'BEGIN {
        split("B KiB MiB GiB TiB", unit, " ");
        i = 1;
        while (bytes >= 1024 && i < 5) { bytes /= 1024; i++; }
        printf "%.2f %s", bytes, unit[i];
    }')
    localize_num "$s"
}

# ------------------------------------------------------------------------------
# Main loop
# ------------------------------------------------------------------------------
for f in "${files[@]}"; do
    [[ -f "$f" ]] || continue
    filename=$(basename -- "$f")
    base="${filename%.*}"
    out_file="compressed/${base}.mp4"
    current_out="$out_file"

    echo "=========================================="
    say squeezing "$HW_MODE" "$cq" "$filename"
    echo "=========================================="

    # -y: on a re-run the old result is silently overwritten;
    # without it ffmpeg with -nostdin trips over an already existing file
    if ffmpeg -nostdin -y "${INPUT_ARGS[@]}" -i "$f" -r 25 "${VIDEO_ARGS[@]}" -c:a aac -b:a 128k -movflags +faststart "$out_file"; then
        in_size=$(wc -c < "$f" | tr -d '[:space:]')
        out_size=$(wc -c < "$out_file" | tr -d '[:space:]')
        (( total_in += in_size ))
        (( total_out += out_size ))
        (( processed++ ))
    else
        say fail "$filename"
        rm -f "$out_file"   # no broken stubs left behind, same as in the GUI version
    fi
done
current_out=""

# ------------------------------------------------------------------------------
# Final report
# ------------------------------------------------------------------------------
if (( processed > 0 && total_in > 0 )); then
    in_hr=$(human_size "$total_in")
    out_hr=$(human_size "$total_out")
    saved_hr=$(human_size $(( total_in - total_out )))
    percent=$(LC_ALL=C awk -v o="$total_out" -v i="$total_in" 'BEGIN { printf "%.2f", (1 - o / i) * 100 }')
    percent=$(localize_num "$percent")
    elapsed=$SECONDS
    hours=$(( elapsed / 3600 ))
    mins=$(( (elapsed % 3600) / 60 ))
    secs=$(( elapsed % 60 ))
    printf -v time_str "%02d:%02d:%02d" "$hours" "$mins" "$secs"
    echo ""
    echo "=========================================="
    say sum_title "$processed"
    echo "=========================================="
    say sum_engine "$HW_MODE"
    say sum_before "$in_hr"
    say sum_after "$out_hr"
    say sum_saved "$saved_hr" "$percent"
    say sum_time "$time_str"
    say sum_folder
    echo "=========================================="
    say footer
fi
