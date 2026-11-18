**English** | [Русский](README.ru.md)

```text
════════════════════════════════════════════════════════════════════════════
  ___  ____ ______   _ ___ __  __    _  _____ ___  ____
 / _ \| __ )__  / | | |_ _|  \/  |  / \|_   _/ _ \|  _ \
| | | |  _ \ / /| |_| || || |\/| | / _ \ | || | | | |_) |
| |_| | |_) / /_|  _  || || |  | |/ ___ \| || |_| |  _ <
 \___/|____/____|_| |_|___|_|  |_/_/   \_\_| \___/|_| \_\

OBZHIMATOR-2000 // PORTABLE VIDEO COMPRESSOR // HEVC EDITION
POWERED BY FFMPEG // ZERO BLOATWARE // MAXIMUM COMPRESSION
════════════════════════════════════════════════════════════════════════════

[0x01] WHAT IS THIS BEAST?
--------------------------
Stop feeding bloated GUI combines with telemetry, subscriptions and
half-screen buttons! OBZHIMATOR-2000 is a portable conveyor-belt video
squeezer on steroids: HEVC (H.265) codec, zero installs, and your files
lose 90-96% of their weight. Born in WSL2 on Windows 11 as a plain
console script, it later grew a window with buttons for those who
break into a nervous tic around black terminals.
Two tools in the box:
  - obzhimator2000.sh  - console daemon for Linux and WSL2;
  - obzhimator2000.bat - a window with buttons for Windows (a polyglot
    .bat + PowerShell, no installs whatsoever).
The preset is inspired by Ironclad from CompressO (props to the authors),
but the name is ours now, home-grown.
Sources are NOT touched (we are not savages). Finished files are neatly
placed into ./compressed/ next to the originals.

[0x02] SYSTEM REQUIREMENTS (DEPENDENCIES)
-----------------------------------------
1. A working pair of hands (optional - a GUI was added for the paw-owners).
2. FFmpeg in the system:
   - Linux / WSL2:  sudo apt update && sudo apt install ffmpeg -y
   - Windows:       winget install Gyan.FFmpeg  (or drop ffmpeg.exe next
                    to obzhimator2000.bat - it will find it itself).
3. Windows 10/11 with built-in PowerShell 5.1 for the GUI version;
   bash 4+ for the console one.
4. Fresh GPU drivers if you want hardware acceleration.
   No GPU? No problem: it will squeeze on the CPU, just slower.

[0x03] CONSOLE MODE: obzhimator2000.sh (FOR TRUE HACKERS AND LINUX FOLKS)
-------------------------------------------------------------------------
Drop the script into a folder with your videos (.mp4, .mkv, .mov, .avi,
.webm) and run:
1. Grant execute permission once (if the script lives on a Linux
   partition):
   $ chmod +x obzhimator2000.sh
2. Here we go:
   $ ./obzhimator2000.sh
   Want to squeeze only selected files? Pass them as arguments:
   $ ./obzhimator2000.sh lecture1.mp4 lecture2.mkv
   No arguments - it takes every video file in the current folder.
   Language: messages follow your system locale (Russian -> ru, anything
   else -> en). Force it with a flag:
   $ ./obzhimator2000.sh --lang ru
3. If your videos live on a Windows drive (/mnt/c/...) under WSL2, run:
   $ bash obzhimator2000.sh
The script asks for the quality level, detects your hardware on its own
(NVENC -> QSV -> VAAPI -> CPU), and prints the final report. Ctrl-C stops
the conveyor and deletes the under-squeezed stub.
Note: editing the file in a Windows editor? Save with LF line endings,
or bash on Linux will choke on an invisible \r and refuse to work.

[0x04] GUI MODE: obzhimator2000.bat (FOR WINDOWS FOLKS WITH PAWS)
-----------------------------------------------------------------
If the command line makes your palms sweat and typing numbers triggers
a mild existential crisis - for you specifically we assembled a polyglot
monster a couple dozen kilobytes heavy: a PowerShell script lives inside
the .bat, while outside it is just a double-click (no Python, no .NET
downloaders, nothing).
1. Double-click obzhimator2000.bat.
2. Drag videos or a whole folder straight into the window
   (yes, we shipped Drag & Drop).
3. Pick a codec (HEVC for feather-weight, H.264 for ancient toasters)
   and click a quality radio button.
4. Press the big blue "SQUEEZE ALL FILES" button and go make a smoothie.
5. Changed your mind? Press "Stop" - the program kills the process and
   cleans up the half-squeezed broken stub after itself.
6. The window does not resize. Not a bug, a retro feature: FixedSingle.
7. The interface is bilingual: flip the ENG/RU switch in the window
   corner and everything speaks your language.

[0x05] QUALITY SETTINGS (MAGIC CQ / CRF NUMBERS)
------------------------------------------------
Don't be silly, pick your squeeze level wisely:
28  - "EAGLE EYE" MODE. Maximum clarity; tiny text on screencasts stays
      razor-sharp. Heavier file, but still a fraction of the original
      weight.
32  - THE SWEET SPOT (default). Your eyes won't spot the difference,
      while a 6 GB screencast collapses into ~200-300 MB (90-96% savings).
      Covers 99% of use cases.
35  - "THE INNER SCOTSMAN" MODE (still perfectly watchable). For long
      lectures, conference calls and messenger sends - whenever every
      megabyte counts and your inner Scotsman applauds standing up.
For H.264 the numbers are their own, more humane: 25 / 28 / 31 -
the program substitutes them itself.
The GUI has an "Or your own number" field (15-45); the console takes
whatever you type.

[0x06] FEATURES UNDER THE HOOD
------------------------------
[+] HEVC (H.265) codec + -g 250 key: a keyframe once per 10 seconds -
    a static screen UI does not inflate the file, text stays crisp.
[+] hvc1 compatibility tag: .mp4 videos open natively in Windows,
    macOS, iOS, Android, VLC and Telegram - no voodoo rituals required.
[+] Smart hardware autodetect: runs a 1-frame micro-test in memory and
    picks the best engine (NVENC -> QSV -> VAAPI -> CPU libx265/libx264).
[+] Conveyor processing: squeezes 1 file or 100 in a row without your
    participation.
[+] Cleanliness: error or Ctrl-C - the under-squeezed stub is deleted,
    no broken files accumulate in ./compressed/.
[+] Final report: how many gigs you saved and how many minutes of your
    life you got back.

[0x07] GOTCHAS (READ TO AVOID SURPRISES)
----------------------------------------
[-] Output is always .mp4 into ./compressed/ next to the original.
[-] Audio is re-squeezed to AAC 128k - plenty for speech and screencasts.
[-] Frame rate is forcibly 25 fps (-r 25 in the scripts): hello from the
    2000s. Don't need it? Find the -r 25 line and delete it, nobody will
    be offended.
[-] Re-running over the same folder silently overwrites results (-y).
[-] Editing .bat - save as UTF-8 without BOM; editing .sh - save with LF.
    Otherwise: mojibake and "bad interpreter", respectively.

[0x08] EMERGENCY ROLLBACK TO H.264 (FOR JURASSIC-ERA BOXES AND BROWSERS)
------------------------------------------------------------------------
If a squeezed HEVC file must be opened on a Jurassic-era computer or in
an old web player that cannot into H.265 - re-encode that file back to
classic H.264 (audio is copied instantly, without re-encoding):
```

On CPU (100% compatibility):

```bash
ffmpeg -i "video_hevc.mp4" -c:v libx264 -preset medium -crf 23 -pix_fmt yuv420p -c:a copy -movflags +faststart "video_h264.mp4"
```

On NVIDIA GPU (in a couple of seconds):

```bash
ffmpeg -i "video_hevc.mp4" -c:v h264_nvenc -preset p5 -rc vbr -cq 25 -pix_fmt yuv420p -c:a copy -movflags +faststart "video_h264.mp4"
```

```text
[0x09] LICENSE: GIVEN TO EVERYONE FOREVER
------------------------------------------
Public domain (Unlicense). Copy, modify, sell, embed in commercial
products, fork, publish under your own name - everything is allowed,
forever, free of charge, without asking and without reporting.
The author deliberately renounced all rights in favor of humanity.
No warranties whatsoever: if your GPU takes off from joy - that's your
personal relationship with your GPU.
Full text lives in the LICENSE file next to this README.

[0x0A] DISCLAIMER
-----------------
The scripts are written for educational and strictly peaceful purposes,
to save your SSDs from obesity. Make backups, hacker!
================================================================================
EOF // HAPPY COMPRESSING! // OBZHIMATOR-2000 FOREVER
================================================================================
```
