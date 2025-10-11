# --- pack_flutter_save.ps1 (output beside app folder) ---
# ZIP 루트: .vscode  (리포 루트의 것)
# ZIP 루트: flutter_application_1/  (그 안에 lib/ + flutter_application_1 루트의 *.yaml)
# ZIP 저장 위치: flutter_application_1의 상위 폴더(= 같은 위치)
# 압축 성공 시 임시 폴더 삭제

param(
  # scripts 폴더 옆의 flutter_application_1 경로를 기본값으로 사용
  [string]$ProjectPath = (Join-Path $PSScriptRoot "..\flutter_application_1")
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path $ProjectPath)) {
  Write-Error "Project not found: $ProjectPath"
  exit 1
}

# 경로 계산
$RepoRoot     = (Split-Path -Parent $ProjectPath)           # 리포 루트
$OutDir       = $RepoRoot                                   # ✅ ZIP을 app 폴더와 같은 위치에 생성
$Stamp        = Get-Date -Format "yyyyMMdd_HHmmss"
$ZipPath      = Join-Path $OutDir ("flutter_application_1_$Stamp.zip")

# 임시 작업 폴더 (flutter_application_1 안에 생성)
$TempRoot     = Join-Path $ProjectPath "_save_for_zip"
$InnerAppDir  = Join-Path $TempRoot   "flutter_application_1"  # ZIP 안에 들어갈 앱 폴더

# 깨끗이 시작
if (Test-Path $TempRoot) { Remove-Item $TempRoot -Recurse -Force }
New-Item -ItemType Directory -Path $InnerAppDir -Force | Out-Null

# 1) ZIP 루트에 들어갈 .vscode (리포 루트의 것)
$rootVscode = Join-Path $RepoRoot ".vscode"
if (Test-Path $rootVscode) {
  Copy-Item -Path $rootVscode -Destination $TempRoot -Recurse -Force
}

# 2) flutter_application_1/lib 전체 복사 → ZIP의 flutter_application_1/lib
$srcLib = Join-Path $ProjectPath "lib"
if (Test-Path $srcLib) {
  Copy-Item -Path $srcLib -Destination $InnerAppDir -Recurse -Force
}

# 3) flutter_application_1 루트의 *.yaml 파일들만 복사 → ZIP의 flutter_application_1/ 바로 아래
Get-ChildItem -Path $ProjectPath -File -Filter *.yaml | ForEach-Object {
  Copy-Item -Path $_.FullName -Destination $InnerAppDir -Force
}

# 4) 압축 생성 (폴더 구조 유지 위해 TempRoot 기준 상대경로로 압축)
if (Test-Path $ZipPath) { Remove-Item $ZipPath -Force }

Push-Location $TempRoot
try {
  Compress-Archive -Path * -DestinationPath $ZipPath -Force
}
finally {
  Pop-Location
}

# 5) 성공 시 임시 폴더 삭제
if (Test-Path $ZipPath) {
  Remove-Item $TempRoot -Recurse -Force
  Write-Host "📦 Created: $ZipPath"
} else {
  Write-Error "Compression failed. Temp folder left at: $TempRoot"
  exit 1
}


#  powershell -ExecutionPolicy Bypass -File .\scripts\pack_flutter_save.ps1