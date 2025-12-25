# --- scrcpy_dev.ps1 (Korean typing upgrade: use UHID keyboard) ---

$links = "$env:LOCALAPPDATA\Microsoft\WinGet\Links"
if (Test-Path $links) { $env:Path += ";$links" }

$scr = "$env:LOCALAPPDATA\Microsoft\WinGet\Packages\Genymobile.scrcpy_Microsoft.Winget.Source_8wekyb3d8bbwe\scrcpy-win64-v3.3.3"
if (Test-Path $scr) { $env:Path += ";$scr" }

# 기존 옵션(유지)
$baseArgs = @(
  "--max-fps", "120",
  "--video-bit-rate", "16M",
  "--turn-screen-off",
  "--stay-awake"
)

# 한글 타이핑 핵심: 폰에 "물리 키보드"로 붙이기(IME 텍스트 주입 사용 안 함)
$extraArgs = @()

try {
  $help = (& scrcpy --help 2>&1 | Out-String)

  # v3.3.3 기준: --keyboard=uhid 지원되는 경우가 많음
  if ($help -match "--keyboard") {
    # 가장 안정적인 물리 키보드 방식
    $extraArgs += @("--keyboard=uhid")
  }

  # (선택) 클립보드 동기화는 유지: 만약 폰 키보드 설정이 아직 안 되어도 Ctrl+V로 우회 가능
  if ($help -match "--clipboard-autosync") {
    $extraArgs += "--clipboard-autosync"
  }
}
catch {
  # help 조회 실패해도 base 실행은 진행
}

& scrcpy @baseArgs @extraArgs
