# scripts/pack_flutter_save.ps1
# ZIP 루트: .vscode (리포 루트)
# ZIP 루트: flutter_application_1/  -> 그 안에 lib/ + flutter_application_1 루트의 *.yaml
# ZIP 저장 위치: flutter_application_1의 상위 폴더(같은 위치)

param(
  [string]$ProjectPath = (Join-Path $PSScriptRoot "..\flutter_application_1")
)

$ErrorActionPreference = "Stop"

# ---- 콘솔/출력 인코딩 UTF-8 고정 (한글 깨짐 방지) ----
try {
  [Console]::OutputEncoding = New-Object System.Text.UTF8Encoding($false)
  $env:DOTNET_CLI_UI_LANGUAGE = "ko"
} catch {}

if (-not (Test-Path $ProjectPath)) {
  Write-Host "❌ Project not found: $ProjectPath" -ForegroundColor Red
  exit 1
}

# 경로 계산
$RepoRoot = (Split-Path -Parent (Resolve-Path $ProjectPath))
$OutDir   = $RepoRoot
$Stamp    = Get-Date -Format "yyyyMMdd_HHmmss"
$ZipPath  = Join-Path $OutDir ("flutter_application_1_{0}.zip" -f $Stamp)

# 임시 작업 폴더
$TempRoot    = Join-Path $OutDir "__pack_tmp_$Stamp"
$ZipRootDir  = $TempRoot                         # ZIP의 루트 역할
$InnerAppDir = Join-Path $ZipRootDir "flutter_application_1"

# 깨끗이 시작
if (Test-Path $TempRoot) { Remove-Item $TempRoot -Recurse -Force }
New-Item -ItemType Directory -Path $InnerAppDir -Force | Out-Null

# 1) ZIP 루트에 .vscode (리포 루트의 것) 추가
$RootVscode = Join-Path $RepoRoot ".vscode"
if (Test-Path $RootVscode) {
  Copy-Item -Path $RootVscode -Destination $ZipRootDir -Recurse -Force
  Write-Host "Copy: .vscode" -ForegroundColor Cyan
}

# 2) flutter_application_1/lib 전체 복사
$SrcLib = Join-Path $ProjectPath "lib"
if (Test-Path $SrcLib) {
  Copy-Item -Path $SrcLib -Destination $InnerAppDir -Recurse -Force
  Write-Host "Copy: flutter_application_1\lib" -ForegroundColor Cyan
} else {
  Write-Host "⚠ lib 폴더가 없습니다: $SrcLib" -ForegroundColor Yellow
}

# 3) flutter_application_1 루트의 *.yaml만 복사
Get-ChildItem -Path $ProjectPath -File -Filter *.yaml | ForEach-Object {
  Copy-Item -Path $_.FullName -Destination $InnerAppDir -Force
  Write-Host ("Copy yaml: {0}" -f $_.Name) -ForegroundColor Cyan
}

# ❌ 복사하지 않을 것들 (우리는 위에서 명시적으로 필요한 것만 복사하므로 별도 제외 절차 불필요)
#   amplify/, android/, ios/, web/, windows/, macos/, linux/, build/, .dart_tool/ 등은 복사 안 함

# 4) 압축 생성
if (Test-Path $ZipPath) { Remove-Item $ZipPath -Force }

Push-Location $TempRoot
try {
  Compress-Archive -Path * -DestinationPath $ZipPath -Force
} finally {
  Pop-Location
}

# 5) 정리
if (Test-Path $ZipPath) {
  Remove-Item $TempRoot -Recurse -Force
  Write-Host ("📦 Created: {0}" -f $ZipPath) -ForegroundColor Green
} else {
  Write-Host "❌ Compression failed. Temp folder kept: $TempRoot" -ForegroundColor Red
  exit 1
}
