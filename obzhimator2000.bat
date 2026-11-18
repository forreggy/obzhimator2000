@echo off
chcp 65001 >nul
set "OBZHIMATOR_FILE=%~f0"
powershell -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -Command "try { $c=[IO.File]::ReadAllText($env:OBZHIMATOR_FILE,[Text.Encoding]::UTF8); $i=$c.LastIndexOf('#PSSTART'); if($i -lt 0){throw 'Marker #PSSTART not found'}; Invoke-Expression $c.Substring($i) } catch { Add-Type -AssemblyName System.Windows.Forms; [System.Windows.Forms.MessageBox]::Show(($_ | Out-String), 'Обжиматор-2000 / Obzhimator-2000 - ошибка / error', 'OK', 'Error') | Out-Null; exit 1 }"
exit /b

#PSSTART

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

$script:ScriptRoot = if ($env:OBZHIMATOR_FILE) { Split-Path -LiteralPath $env:OBZHIMATOR_FILE } else { [System.IO.Directory]::GetCurrentDirectory() }

# ---------------------------------------------------------------------------
# Localization: every user-visible string lives in this table (ru / en).
# To add a language, add one more block with the same keys.
# ---------------------------------------------------------------------------
$script:Strings = @{
    ru = @{
        form_title         = 'ОБЖИМАТОР-2000 // Portable Video Compressor'
        grp_files          = '1. Видеофайлы (перетащите сюда мышкой или выберите папку)'
        btn_add_files      = 'Добавить файлы...'
        btn_add_folder     = 'Выбрать папку...'
        btn_clear          = 'Очистить список'
        grp_settings       = '2. Настройки сжатия (пресет «Обжиматор-2000»)'
        lbl_codec          = 'Кодек:'
        codec_hevc         = 'HEVC (H.265) — максимальное сжатие'
        codec_h264         = 'H.264 (AVC) — 100% совместимость'
        hw_detecting       = 'Движок: определение...'
        hw_checking        = 'Проверка GPU...'
        hw_cpu             = 'CPU ({0} — программно)'
        lbl_quality        = 'Качество (CQ/CRF):'
        q_high             = 'Орлиный глаз'
        q_med              = 'Баланс'
        q_low              = 'Минимум веса'
        lbl_custom         = 'Или своё число:'
        btn_start          = '▶ СЖАТЬ ВСЕ ФАЙЛЫ'
        btn_stop           = '⏹ Стоп'
        filter_video       = 'Видеофайлы'
        filter_all         = 'Все файлы'
        msg_no_files       = 'Сначала добавьте файлы или выберите папку!'
        msg_attention      = 'Внимание'
        msg_ffmpeg_missing = "Утилита ffmpeg.exe не найдена.`nУстановите FFmpeg в систему или положите ffmpeg.exe рядом с программой."
        msg_error_title    = 'Обжиматор-2000 — Ошибка'
        err_unknown_engine = 'Неизвестный движок: {0}'
        log_ready          = 'Готов к работе. Движок: {0}'
        log_stopping       = '[!] Остановка по запросу пользователя...'
        log_not_found      = '[{0}/{1}] Файл не найден: {2}'
        log_squeezing      = '[{0}/{1}] Сжимаю (Q={2}): {3}...'
        log_done           = '   Готово: {0} -> {1}'
        log_error_code     = '   [!] Ошибка при обработке файла (код {0}).'
        log_exception      = '   [!] Исключение при запуске/ожидании ffmpeg: {0}'
        log_total          = 'ИТОГО ({0} файл(ов)): {1} -> {2} (-{3}%)'
        log_elapsed        = 'Затрачено времени: {0}'
    }
    en = @{
        form_title         = 'OBZHIMATOR-2000 // Portable Video Compressor'
        grp_files          = '1. Video files (drag them here with the mouse or pick a folder)'
        btn_add_files      = 'Add files...'
        btn_add_folder     = 'Choose folder...'
        btn_clear          = 'Clear list'
        grp_settings       = '2. Compression settings ("Obzhimator-2000" preset)'
        lbl_codec          = 'Codec:'
        codec_hevc         = 'HEVC (H.265) — maximum squeeze'
        codec_h264         = 'H.264 (AVC) — 100% compatible'
        hw_detecting       = 'Engine: detecting...'
        hw_checking        = 'Checking GPU...'
        hw_cpu             = 'CPU ({0} — software)'
        lbl_quality        = 'Quality (CQ/CRF):'
        q_high             = 'Eagle eye'
        q_med              = 'Sweet spot'
        q_low              = 'Inner Scotsman'
        lbl_custom         = 'Or your own number:'
        btn_start          = '▶ SQUEEZE ALL FILES'
        btn_stop           = '⏹ Stop'
        filter_video       = 'Video files'
        filter_all         = 'All files'
        msg_no_files       = 'Add some files or choose a folder first!'
        msg_attention      = 'Attention'
        msg_ffmpeg_missing = "ffmpeg.exe not found.`nInstall FFmpeg system-wide or drop ffmpeg.exe next to the program."
        msg_error_title    = 'Obzhimator-2000 — Error'
        err_unknown_engine = 'Unknown engine: {0}'
        log_ready          = 'Ready to roll. Engine: {0}'
        log_stopping       = '[!] Stopping at user request...'
        log_not_found      = '[{0}/{1}] File not found: {2}'
        log_squeezing      = '[{0}/{1}] Squeezing (Q={2}): {3}...'
        log_done           = '   Done: {0} -> {1}'
        log_error_code     = '   [!] Error while processing the file (code {0}).'
        log_exception      = '   [!] Exception while starting/waiting for ffmpeg: {0}'
        log_total          = 'TOTAL ({0} file(s)): {1} -> {2} (-{3}%)'
        log_elapsed        = 'Time elapsed: {0}'
    }
}

# Start language: Russian for a Russian system UI, English for everything else.
$script:Lang = if ([System.Globalization.CultureInfo]::CurrentUICulture.TwoLetterISOLanguageName -eq 'ru') { 'ru' } else { 'en' }
$script:Culture = [System.Globalization.CultureInfo]::GetCultureInfo($(if ($script:Lang -eq 'ru') { 'ru-RU' } else { 'en-US' }))
$script:uiBusy = $false

# Look up a string by key in the current language.
function T {
    param([string]$Key)

    $table = $script:Strings[$script:Lang]
    if ($table.ContainsKey($Key)) { return $table[$Key] }
    return $Key
}

# ---------------------------------------------------------------------------
# Locate ffmpeg: in PATH or next to this file
# ---------------------------------------------------------------------------
$script:FfmpegPath = 'ffmpeg'
$ffmpegCmd = Get-Command ffmpeg -ErrorAction SilentlyContinue
if (-not $ffmpegCmd) {
    $localFfmpeg = Join-Path $script:ScriptRoot 'ffmpeg.exe'
    if (Test-Path -LiteralPath $localFfmpeg) {
        $env:PATH = "$script:ScriptRoot;$env:PATH"
        $ffmpegCmd = Get-Command ffmpeg -ErrorAction SilentlyContinue
    }
}

if (-not $ffmpegCmd) {
    [System.Windows.Forms.MessageBox]::Show((T 'msg_ffmpeg_missing'), (T 'msg_error_title'), 'OK', 'Error') | Out-Null
    exit 1
}

$script:FfmpegPath = $ffmpegCmd.Source

# ---------------------------------------------------------------------------
# Global state
# ---------------------------------------------------------------------------
$script:fileList = New-Object System.Collections.Generic.List[string]
$script:currentHw = $null
$script:isCancelled = $false
$script:activeProcess = $null
$script:appClosing = $false

# ---------------------------------------------------------------------------
# Helper functions
# ---------------------------------------------------------------------------
function Get-QuotedPath {
    param([string]$Path)
    return ('"' + $Path + '"')
}

function New-FfmpegStartInfo {
    param([string]$Arguments)

    $psi = New-Object System.Diagnostics.ProcessStartInfo

    if ($script:FfmpegPath -match '\.(cmd|bat)$') {
        $psi.FileName = $env:ComSpec
        $psi.Arguments = '/c {0} {1}' -f (Get-QuotedPath $script:FfmpegPath), $Arguments
    } else {
        $psi.FileName = $script:FfmpegPath
        $psi.Arguments = $Arguments
    }

    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true

    return $psi
}

function Test-Encoder {
    param([string]$EncoderTest)

    $psi = New-FfmpegStartInfo "-nostdin -hide_banner -loglevel error $EncoderTest"
    $process = New-Object System.Diagnostics.Process
    $process.StartInfo = $psi

    try {
        [void]$process.Start()

        if (-not $process.WaitForExit(3000)) {
            try { $process.Kill() } catch {}
            return $false
        }

        return ($process.ExitCode -eq 0)
    } catch {
        return $false
    } finally {
        $process.Dispose()
    }
}

# Returns a hashtable with Type (engine id), Name (GPU label) or Encoder (CPU fallback).
function Detect-Hardware {
    param([string]$CodecFamily)

    if ($CodecFamily -eq 'HEVC') {
        $candidates = @(
            @{ Name = 'NVIDIA GPU (hevc_nvenc)'; Test = '-f lavfi -i color=black:s=256x256:d=0.1 -c:v hevc_nvenc -f null -'; Type = 'nvenc_hevc' },
            @{ Name = 'AMD GPU (hevc_amf)'; Test = '-f lavfi -i color=black:s=256x256:d=0.1 -c:v hevc_amf -f null -'; Type = 'amf_hevc' },
            @{ Name = 'Intel GPU (hevc_qsv)'; Test = '-f lavfi -i color=black:s=256x256:d=0.1 -c:v hevc_qsv -f null -'; Type = 'qsv_hevc' }
        )
        $fallback = @{ Name = $null; Encoder = 'libx265'; Type = 'cpu_hevc' }
    } else {
        $candidates = @(
            @{ Name = 'NVIDIA GPU (h264_nvenc)'; Test = '-f lavfi -i color=black:s=256x256:d=0.1 -c:v h264_nvenc -f null -'; Type = 'nvenc_h264' },
            @{ Name = 'AMD GPU (h264_amf)'; Test = '-f lavfi -i color=black:s=256x256:d=0.1 -c:v h264_amf -f null -'; Type = 'amf_h264' },
            @{ Name = 'Intel GPU (h264_qsv)'; Test = '-f lavfi -i color=black:s=256x256:d=0.1 -c:v h264_qsv -f null -'; Type = 'qsv_h264' }
        )
        $fallback = @{ Name = $null; Encoder = 'libx264'; Type = 'cpu_h264' }
    }

    foreach ($candidate in $candidates) {
        if (Test-Encoder $candidate.Test) { return $candidate }
    }

    return $fallback
}

# Display name of the detected engine, in the current language.
function Get-HwName {
    param($Hw)

    if ($Hw.Type -like 'cpu_*') { return ((T 'hw_cpu') -f $Hw.Encoder) }
    return $Hw.Name
}

function Add-Log {
    param([string]$Message)
    if ($script:txtLog -and -not $script:txtLog.IsDisposed) {
        $script:txtLog.AppendText("$Message`r`n")
    }
}

function Add-VideoFile {
    param([string]$FullName, [string]$DisplayName)

    if (-not $script:fileList.Contains($FullName)) {
        $script:fileList.Add($FullName)
        [void]$script:listBox.Items.Add($DisplayName)
    }
}

function Add-VideoPaths {
    param([string[]]$Paths)

    $extensions = @('.mp4', '.mkv', '.mov', '.avi', '.webm')

    foreach ($path in $Paths) {
        if (-not (Test-Path -LiteralPath $path)) { continue }

        if (Test-Path -LiteralPath $path -PathType Container) {
            Get-ChildItem -LiteralPath $path -File |
                Where-Object { $extensions -contains $_.Extension.ToLower() } |
                ForEach-Object { Add-VideoFile $_.FullName $_.Name }
        } else {
            $item = Get-Item -LiteralPath $path
            if ($extensions -contains $item.Extension.ToLower()) {
                Add-VideoFile $item.FullName $item.Name
            }
        }
    }
}

function Update-EngineLabel {
    $family = if ($script:cmbCodec.SelectedIndex -eq 0) { 'HEVC' } else { 'H264' }
    $script:lblHw.Text = T 'hw_checking'
    [System.Windows.Forms.Application]::DoEvents()

    $script:currentHw = Detect-Hardware $family
    $script:lblHw.Text = Get-HwName $script:currentHw
}

function Format-Bytes {
    param([long]$Value)

    if ($Value -ge 1GB) { return (($Value / 1GB).ToString('N2', $script:Culture) + ' GiB') }
    elseif ($Value -ge 1MB) { return (($Value / 1MB).ToString('N2', $script:Culture) + ' MiB') }
    else { return (($Value / 1KB).ToString('N2', $script:Culture) + ' KiB') }
}

# CQ/CRF values for the three radio buttons: high quality, balanced, minimum size.
function Get-CqPresets {
    if ($script:cmbCodec.SelectedIndex -eq 0) { return @(28, 32, 35) }
    return @(25, 28, 31)
}

# Refresh only the radio button captions (used when the language changes).
function Update-CqLabels {
    $n = Get-CqPresets
    $script:rbHigh.Text = '{0} ({1})' -f $n[0], (T 'q_high')
    $script:rbMed.Text = '{0} ({1})' -f $n[1], (T 'q_med')
    $script:rbLow.Text = '{0} ({1})' -f $n[2], (T 'q_low')
}

# Refresh captions and move the custom value to the checked preset (used when the codec changes).
function Set-CqPresetText {
    Update-CqLabels

    $n = Get-CqPresets
    if ($script:rbHigh.Checked) { $script:numCustom.Value = $n[0] }
    elseif ($script:rbMed.Checked) { $script:numCustom.Value = $n[1] }
    elseif ($script:rbLow.Checked) { $script:numCustom.Value = $n[2] }
}

function Get-VideoArgs {
    param([string]$EngineType, [int]$Cq)

    switch ($EngineType) {
        'nvenc_hevc' { return "-c:v hevc_nvenc -preset p7 -tune hq -rc vbr -cq $Cq -b:v 0 -g 250 -spatial-aq 1 -temporal-aq 1 -tag:v hvc1 -pix_fmt yuv420p" }
        'amf_hevc'   { return "-c:v hevc_amf -quality quality -rc cqp -qp_i $Cq -qp_p $Cq -qp_b $Cq -g 250 -tag:v hvc1 -pix_fmt yuv420p" }
        'qsv_hevc'   { return "-c:v hevc_qsv -preset veryslow -global_quality $Cq -g 250 -tag:v hvc1 -pix_fmt nv12" }
        'cpu_hevc'   { return "-c:v libx265 -preset slow -crf $Cq -g 250 -tag:v hvc1 -pix_fmt yuv420p" }
        'nvenc_h264' { return "-c:v h264_nvenc -preset p7 -tune hq -rc vbr -cq $Cq -b:v 0 -spatial-aq 1 -temporal-aq 1 -pix_fmt yuv420p" }
        'amf_h264'   { return "-c:v h264_amf -quality quality -rc cqp -qp_i $Cq -qp_p $Cq -qp_b $Cq -pix_fmt yuv420p" }
        'qsv_h264'   { return "-c:v h264_qsv -preset veryslow -global_quality $Cq -pix_fmt nv12" }
        'cpu_h264'   { return "-c:v libx264 -preset slow -crf $Cq -pix_fmt yuv420p" }
        default { throw ((T 'err_unknown_engine') -f $EngineType) }
    }
}

function Reset-UiAfterEncode {
    if ($script:form -and $script:form.IsDisposed) { return }

    $script:btnStart.Enabled = $true
    $script:btnAddFiles.Enabled = $true
    $script:btnAddFolder.Enabled = $true
    $script:btnClear.Enabled = $true
    $script:cmbCodec.Enabled = $true
    $script:btnStop.Enabled = $false
}

# Apply a language to every control. Safe to call at any time, including during encoding.
function Set-Language {
    param([string]$Lang)

    $script:Lang = $Lang
    $script:Culture = [System.Globalization.CultureInfo]::GetCultureInfo($(if ($Lang -eq 'ru') { 'ru-RU' } else { 'en-US' }))

    # uiBusy silences the change handlers while we rebuild texts and items
    $script:uiBusy = $true
    try {
        $script:form.Text = T 'form_title'
        $script:grpFiles.Text = T 'grp_files'
        $script:btnAddFiles.Text = T 'btn_add_files'
        $script:btnAddFolder.Text = T 'btn_add_folder'
        $script:btnClear.Text = T 'btn_clear'
        $script:grpSettings.Text = T 'grp_settings'
        $script:lblCodec.Text = T 'lbl_codec'
        $script:lblQual.Text = T 'lbl_quality'
        $script:lblCustom.Text = T 'lbl_custom'
        $script:btnStart.Text = T 'btn_start'
        $script:btnStop.Text = T 'btn_stop'

        # The English caption is longer, so keep the number box right after it
        $script:numCustom.Left = $script:lblCustom.Left + $script:lblCustom.PreferredWidth + 8

        # Codec list: rebuild the items, keep the selection
        $idx = $script:cmbCodec.SelectedIndex
        if ($idx -lt 0) { $idx = 0 }
        $script:cmbCodec.Items.Clear()
        [void]$script:cmbCodec.Items.Add((T 'codec_hevc'))
        [void]$script:cmbCodec.Items.Add((T 'codec_h264'))
        $script:cmbCodec.SelectedIndex = $idx

        Update-CqLabels

        if ($script:currentHw) {
            $script:lblHw.Text = Get-HwName $script:currentHw
        } else {
            $script:lblHw.Text = T 'hw_detecting'
        }

        $script:rbEng.Checked = ($Lang -eq 'en')
        $script:rbRu.Checked = ($Lang -eq 'ru')
    } finally {
        $script:uiBusy = $false
    }
}

# ---------------------------------------------------------------------------
# Main window (texts are filled in by Set-Language)
# ---------------------------------------------------------------------------
$script:form = New-Object System.Windows.Forms.Form
$script:form.Size = New-Object System.Drawing.Size(660, 580)
$script:form.StartPosition = 'CenterScreen'
$script:form.FormBorderStyle = 'FixedSingle'
$script:form.MaximizeBox = $false
$script:form.Font = New-Object System.Drawing.Font('Segoe UI', 9.5)
$script:form.AllowDrop = $true

# 1. File selection block
$script:grpFiles = New-Object System.Windows.Forms.GroupBox
$script:grpFiles.Location = New-Object System.Drawing.Point(12, 10)
$script:grpFiles.Size = New-Object System.Drawing.Size(620, 150)
$script:form.Controls.Add($script:grpFiles)

$script:listBox = New-Object System.Windows.Forms.ListBox
$script:listBox.Location = New-Object System.Drawing.Point(10, 22)
$script:listBox.Size = New-Object System.Drawing.Size(450, 115)
$script:listBox.HorizontalScrollbar = $true
$script:grpFiles.Controls.Add($script:listBox)

$script:btnAddFiles = New-Object System.Windows.Forms.Button
$script:btnAddFiles.Location = New-Object System.Drawing.Point(470, 22)
$script:btnAddFiles.Size = New-Object System.Drawing.Size(140, 34)
$script:grpFiles.Controls.Add($script:btnAddFiles)

$script:btnAddFolder = New-Object System.Windows.Forms.Button
$script:btnAddFolder.Location = New-Object System.Drawing.Point(470, 62)
$script:btnAddFolder.Size = New-Object System.Drawing.Size(140, 34)
$script:grpFiles.Controls.Add($script:btnAddFolder)

$script:btnClear = New-Object System.Windows.Forms.Button
$script:btnClear.Location = New-Object System.Drawing.Point(470, 102)
$script:btnClear.Size = New-Object System.Drawing.Size(140, 34)
$script:grpFiles.Controls.Add($script:btnClear)

# 2. Settings block
$script:grpSettings = New-Object System.Windows.Forms.GroupBox
$script:grpSettings.Location = New-Object System.Drawing.Point(12, 168)
$script:grpSettings.Size = New-Object System.Drawing.Size(620, 130)
$script:form.Controls.Add($script:grpSettings)

$script:lblCodec = New-Object System.Windows.Forms.Label
$script:lblCodec.Location = New-Object System.Drawing.Point(12, 26)
$script:lblCodec.AutoSize = $true
$script:grpSettings.Controls.Add($script:lblCodec)

$script:cmbCodec = New-Object System.Windows.Forms.ComboBox
$script:cmbCodec.Location = New-Object System.Drawing.Point(70, 23)
$script:cmbCodec.Size = New-Object System.Drawing.Size(270, 25)
$script:cmbCodec.DropDownStyle = 'DropDownList'
$script:grpSettings.Controls.Add($script:cmbCodec)

$script:lblHw = New-Object System.Windows.Forms.Label
$script:lblHw.ForeColor = [System.Drawing.Color]::DarkGreen
$script:lblHw.Location = New-Object System.Drawing.Point(430, 26)
$script:lblHw.Size = New-Object System.Drawing.Size(180, 22)
$script:grpSettings.Controls.Add($script:lblHw)

$script:lblQual = New-Object System.Windows.Forms.Label
$script:lblQual.Location = New-Object System.Drawing.Point(12, 62)
$script:lblQual.AutoSize = $true
$script:grpSettings.Controls.Add($script:lblQual)

$script:rbHigh = New-Object System.Windows.Forms.RadioButton
$script:rbHigh.Location = New-Object System.Drawing.Point(140, 60)
$script:rbHigh.AutoSize = $true
$script:grpSettings.Controls.Add($script:rbHigh)

$script:rbMed = New-Object System.Windows.Forms.RadioButton
$script:rbMed.Location = New-Object System.Drawing.Point(285, 60)
$script:rbMed.AutoSize = $true
$script:rbMed.Checked = $true
$script:grpSettings.Controls.Add($script:rbMed)

$script:rbLow = New-Object System.Windows.Forms.RadioButton
$script:rbLow.Location = New-Object System.Drawing.Point(405, 60)
$script:rbLow.AutoSize = $true
$script:grpSettings.Controls.Add($script:rbLow)

$script:lblCustom = New-Object System.Windows.Forms.Label
$script:lblCustom.Location = New-Object System.Drawing.Point(140, 92)
$script:lblCustom.AutoSize = $true
$script:grpSettings.Controls.Add($script:lblCustom)

$script:numCustom = New-Object System.Windows.Forms.NumericUpDown
$script:numCustom.Location = New-Object System.Drawing.Point(245, 90)
$script:numCustom.Size = New-Object System.Drawing.Size(55, 24)
$script:numCustom.Minimum = 15
$script:numCustom.Maximum = 45
$script:numCustom.Value = 32
$script:grpSettings.Controls.Add($script:numCustom)

# Language switch ENG / RU (its own panel, so it does not share a radio group with the quality buttons)
$script:pnlLang = New-Object System.Windows.Forms.Panel
$script:pnlLang.Location = New-Object System.Drawing.Point(506, 88)
$script:pnlLang.Size = New-Object System.Drawing.Size(104, 28)
$script:grpSettings.Controls.Add($script:pnlLang)

$script:rbEng = New-Object System.Windows.Forms.RadioButton
$script:rbEng.Text = 'ENG'
$script:rbEng.Appearance = 'Button'
$script:rbEng.TextAlign = 'MiddleCenter'
$script:rbEng.Location = New-Object System.Drawing.Point(0, 0)
$script:rbEng.Size = New-Object System.Drawing.Size(50, 28)
$script:pnlLang.Controls.Add($script:rbEng)

$script:rbRu = New-Object System.Windows.Forms.RadioButton
$script:rbRu.Text = 'RU'
$script:rbRu.Appearance = 'Button'
$script:rbRu.TextAlign = 'MiddleCenter'
$script:rbRu.Location = New-Object System.Drawing.Point(54, 0)
$script:rbRu.Size = New-Object System.Drawing.Size(50, 28)
$script:pnlLang.Controls.Add($script:rbRu)

# 3. Progress and log
$script:progressBar = New-Object System.Windows.Forms.ProgressBar
$script:progressBar.Location = New-Object System.Drawing.Point(12, 308)
$script:progressBar.Size = New-Object System.Drawing.Size(620, 22)
$script:form.Controls.Add($script:progressBar)

$script:txtLog = New-Object System.Windows.Forms.TextBox
$script:txtLog.Location = New-Object System.Drawing.Point(12, 338)
$script:txtLog.Size = New-Object System.Drawing.Size(620, 140)
$script:txtLog.Multiline = $true
$script:txtLog.ReadOnly = $true
$script:txtLog.ScrollBars = 'Vertical'
$script:txtLog.BackColor = [System.Drawing.Color]::FromArgb(24, 24, 24)
$script:txtLog.ForeColor = [System.Drawing.Color]::LightGreen
$script:txtLog.Font = New-Object System.Drawing.Font('Consolas', 9)
$script:form.Controls.Add($script:txtLog)

# 4. Start and stop buttons
$script:btnStart = New-Object System.Windows.Forms.Button
$script:btnStart.Location = New-Object System.Drawing.Point(12, 488)
$script:btnStart.Size = New-Object System.Drawing.Size(470, 38)
$script:btnStart.Font = New-Object System.Drawing.Font('Segoe UI', 10, [System.Drawing.FontStyle]::Bold)
$script:btnStart.BackColor = [System.Drawing.Color]::FromArgb(0, 120, 215)
$script:btnStart.ForeColor = [System.Drawing.Color]::White
$script:btnStart.FlatStyle = 'Flat'
$script:form.Controls.Add($script:btnStart)

$script:btnStop = New-Object System.Windows.Forms.Button
$script:btnStop.Location = New-Object System.Drawing.Point(492, 488)
$script:btnStop.Size = New-Object System.Drawing.Size(140, 38)
$script:btnStop.Enabled = $false
$script:form.Controls.Add($script:btnStop)

# All controls exist: fill in the texts in the starting language
Set-Language $script:Lang

# ---------------------------------------------------------------------------
# UI events
# ---------------------------------------------------------------------------
$script:form.Add_Shown({
    Update-EngineLabel
    Add-Log ((T 'log_ready') -f (Get-HwName $script:currentHw))
})

$script:cmbCodec.Add_SelectedIndexChanged({
    if ($script:uiBusy) { return }
    Set-CqPresetText
    Update-EngineLabel
})

$script:rbEng.Add_CheckedChanged({
    if ($script:uiBusy) { return }
    if ($script:rbEng.Checked) { Set-Language 'en' }
})

$script:rbRu.Add_CheckedChanged({
    if ($script:uiBusy) { return }
    if ($script:rbRu.Checked) { Set-Language 'ru' }
})

$script:rbHigh.Add_CheckedChanged({
    param($sender, $eventArgs)
    if ($sender.Checked) { $script:numCustom.Value = (Get-CqPresets)[0] }
})

$script:rbMed.Add_CheckedChanged({
    param($sender, $eventArgs)
    if ($sender.Checked) { $script:numCustom.Value = (Get-CqPresets)[1] }
})

$script:rbLow.Add_CheckedChanged({
    param($sender, $eventArgs)
    if ($sender.Checked) { $script:numCustom.Value = (Get-CqPresets)[2] }
})

$script:form.Add_DragEnter({
    param($sender, $e)
    if ($e.Data.GetDataPresent([System.Windows.Forms.DataFormats]::FileDrop)) {
        $e.Effect = [System.Windows.Forms.DragDropEffects]::Copy
    }
})

$script:form.Add_DragDrop({
    param($sender, $e)
    Add-VideoPaths @($e.Data.GetData([System.Windows.Forms.DataFormats]::FileDrop))
})

$script:btnAddFiles.Add_Click({
    $ofd = New-Object System.Windows.Forms.OpenFileDialog
    $ofd.Multiselect = $true
    $ofd.Filter = ('{0}|*.mp4;*.mkv;*.mov;*.avi;*.webm|{1}|*.*' -f (T 'filter_video'), (T 'filter_all'))

    if ($ofd.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        Add-VideoPaths $ofd.FileNames
    }
})

$script:btnAddFolder.Add_Click({
    $fbd = New-Object System.Windows.Forms.FolderBrowserDialog

    if ($fbd.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        Add-VideoPaths @($fbd.SelectedPath)
    }
})

$script:btnClear.Add_Click({
    $script:fileList.Clear()
    $script:listBox.Items.Clear()
})

$script:btnStop.Add_Click({
    $script:isCancelled = $true

    if ($script:activeProcess -and -not $script:activeProcess.HasExited) {
        try { $script:activeProcess.Kill() } catch {}
    }

    Add-Log (T 'log_stopping')
})

$script:form.Add_FormClosing({
    param($sender, $e)

    $script:appClosing = $true
    $script:isCancelled = $true

    if ($script:activeProcess -and -not $script:activeProcess.HasExited) {
        try { $script:activeProcess.Kill() } catch {}
    }
})

# ---------------------------------------------------------------------------
# Main encoding loop
# ---------------------------------------------------------------------------
$script:btnStart.Add_Click({
    if ($script:fileList.Count -eq 0) {
        [System.Windows.Forms.MessageBox]::Show((T 'msg_no_files'), (T 'msg_attention'), 'OK', 'Information') | Out-Null
        return
    }

    if (-not $script:currentHw) { Update-EngineLabel }

    $script:isCancelled = $false
    $script:btnStart.Enabled = $false
    $script:btnAddFiles.Enabled = $false
    $script:btnAddFolder.Enabled = $false
    $script:btnClear.Enabled = $false
    $script:cmbCodec.Enabled = $false
    $script:btnStop.Enabled = $true

    $cq = [int]$script:numCustom.Value
    $videoArgs = Get-VideoArgs $script:currentHw.Type $cq

    $totalFiles = $script:fileList.Count
    $script:progressBar.Maximum = $totalFiles
    $script:progressBar.Value = 0

    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    [long]$totalIn = 0
    [long]$totalOut = 0
    [int]$processed = 0

    for ($i = 0; $i -lt $totalFiles; $i++) {
        if ($script:isCancelled) { break }

        $inFile = $script:fileList[$i]

        if (-not (Test-Path -LiteralPath $inFile)) {
            Add-Log ((T 'log_not_found') -f ($i + 1), $totalFiles, $inFile)
            $script:progressBar.Value = $i + 1
            continue
        }

        $item = Get-Item -LiteralPath $inFile
        $outDir = Join-Path $item.DirectoryName 'compressed'

        if (-not (Test-Path -LiteralPath $outDir)) {
            New-Item -ItemType Directory -Path $outDir -Force | Out-Null
        }

        $outFile = Join-Path $outDir ($item.BaseName + '.mp4')

        Add-Log ((T 'log_squeezing') -f ($i + 1), $totalFiles, $cq, $item.Name)

        $arguments = "-nostdin -y -i $(Get-QuotedPath $inFile) -r 25 $videoArgs -c:a aac -b:a 128k -movflags +faststart $(Get-QuotedPath $outFile)"
        $psi = New-FfmpegStartInfo $arguments

        $script:activeProcess = New-Object System.Diagnostics.Process
        $script:activeProcess.StartInfo = $psi

        try {
            [void]$script:activeProcess.Start()

            while (-not $script:activeProcess.HasExited) {
                [System.Windows.Forms.Application]::DoEvents()
                Start-Sleep -Milliseconds 150

                if ($script:appClosing) { break }
            }

            if ($script:isCancelled) {
                if (Test-Path -LiteralPath $outFile) {
                    Remove-Item -LiteralPath $outFile -Force -ErrorAction SilentlyContinue
                }
                break
            }

            if ($script:activeProcess.ExitCode -eq 0 -and (Test-Path -LiteralPath $outFile)) {
                $inSize = $item.Length
                $outSize = (Get-Item -LiteralPath $outFile).Length

                $totalIn += $inSize
                $totalOut += $outSize
                $processed++

                Add-Log ((T 'log_done') -f (Format-Bytes $inSize), (Format-Bytes $outSize))
            } else {
                Add-Log ((T 'log_error_code') -f $script:activeProcess.ExitCode)
            }
        } catch {
            Add-Log ((T 'log_exception') -f $_.Exception.Message)
        } finally {
            if ($script:activeProcess) {
                $script:activeProcess.Dispose()
                $script:activeProcess = $null
            }

            $script:progressBar.Value = $i + 1
        }
    }

    $sw.Stop()

    if ($script:appClosing) { return }

    if ($processed -gt 0 -and $totalIn -gt 0) {
        $pct = ((1 - ($totalOut / $totalIn)) * 100).ToString('N2', $script:Culture)

        Add-Log '=========================================='
        Add-Log ((T 'log_total') -f $processed, (Format-Bytes $totalIn), (Format-Bytes $totalOut), $pct)
        Add-Log ((T 'log_elapsed') -f $sw.Elapsed.ToString('hh\:mm\:ss'))
        Add-Log '=========================================='
    }

    Reset-UiAfterEncode
})

[System.Windows.Forms.Application]::Run($script:form) | Out-Null
