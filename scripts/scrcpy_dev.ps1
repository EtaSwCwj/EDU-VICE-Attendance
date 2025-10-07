# --- scrcpy_dev.ps1 ---
$links = "$env:LOCALAPPDATA\Microsoft\WinGet\Links"
if (Test-Path $links) { $env:Path += ";$links" }

$scr = "$env:LOCALAPPDATA\Microsoft\WinGet\Packages\Genymobile.scrcpy_Microsoft.Winget.Source_8wekyb3d8bbwe\scrcpy-win64-v3.3.3"
if (Test-Path $scr) { $env:Path += ";$scr" }

#scrcpy --max-fps 120 --video-bit-rate 16M --turn-screen-off --stay-awake --always-on-top
scrcpy --max-fps 120 --video-bit-rate 16M --turn-screen-off --stay-awake
