# claude_code.ps1 - Claude Code 실행 스크립트
# EDU-VICE-Attendance 프로젝트용

$projectRoot = Split-Path -Parent $PSScriptRoot

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Claude Code 시작" -ForegroundColor Cyan
Write-Host "  프로젝트: EDU-VICE-Attendance" -ForegroundColor Gray
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 프로젝트 루트로 이동
Set-Location $projectRoot

# Claude Code 설치 확인
$claudeInstalled = Get-Command claude -ErrorAction SilentlyContinue
if (-not $claudeInstalled) {
    Write-Host "Claude Code가 설치되어 있지 않습니다." -ForegroundColor Red
    Write-Host "설치 명령어: npm install -g @anthropic-ai/claude-code" -ForegroundColor Yellow
    Write-Host ""
    $install = Read-Host "지금 설치할까요? (y/n)"
    if ($install -eq 'y') {
        npm install -g @anthropic-ai/claude-code
    } else {
        exit 1
    }
}

# Claude Code 실행
Write-Host "Claude Code 실행 중..." -ForegroundColor Green
Write-Host "종료하려면: /exit 또는 Ctrl+C" -ForegroundColor Gray
Write-Host ""

claude
