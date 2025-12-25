/**
 * 2실린더 자동화 시스템 v6 - Manager (Opus 통합)
 * 
 * 역할:
 * 1. bigstep/ 감시 → Opus가 전체 관리 (분석, 실행, 검증)
 * 2. 실패 시 최대 3회 리트라이
 * 3. 3회 실패 → 중단 및 보고서 작성
 * 
 * AI 구조:
 * - Opus: 전체 관리 (분석 + 실행 + 검증)
 * 
 * 크로스 플랫폼: Windows + Mac 지원
 * 
 * 사용법:
 *   npm run watch:manager
 */

const chokidar = require('chokidar');
const { exec } = require('child_process');
const path = require('path');
const fs = require('fs');
const os = require('os');

// ============================================================
// 경로 설정
// ============================================================
const PROJECT_ROOT = path.join(__dirname, '..');
const AI_BRIDGE = path.join(PROJECT_ROOT, 'ai_bridge');
const FLUTTER_APP = path.join(PROJECT_ROOT, 'flutter_application_1');
const BIGSTEP_PATH = path.join(AI_BRIDGE, 'bigstep');
const REPORT_PATH = path.join(AI_BRIDGE, 'report');

// 폴더 존재 확인 및 생성
[REPORT_PATH].forEach(dir => {
  if (!fs.existsSync(dir)) {
    fs.mkdirSync(dir, { recursive: true });
  }
});

// 처리된 파일 추적
const processedFiles = new Set();
const PROCESSED_FILE = path.join(AI_BRIDGE, '.processed_manager');

// 실패 카운터
const failureCount = {};
const MAX_FAILURES = 3;

// 현재 작업 중인지 체크 (동시 실행 방지)
let isProcessing = false;

// ============================================================
// 유틸리티 함수
// ============================================================

function getShellConfig() {
  if (os.platform() === 'win32') {
    return { shell: 'powershell.exe' };
  } else {
    return { shell: '/bin/bash' };
  }
}

function getClaudePath() {
  return os.platform() === 'darwin' ? '/opt/homebrew/bin/claude' : 'claude';
}

// 알림 소리
function playSound(type = 'success') {
  if (os.platform() === 'win32') {
    const sounds = {
      success: '[console]::beep(800, 300); [console]::beep(1000, 300); [console]::beep(1200, 500)',
      fail: '[console]::beep(400, 500); [console]::beep(300, 500)',
      start: '[console]::beep(600, 200); [console]::beep(800, 200)'
    };
    exec(`powershell -c "${sounds[type] || sounds.start}"`);
  } else if (os.platform() === 'darwin') {
    const sounds = {
      success: '/System/Library/Sounds/Glass.aiff',
      fail: '/System/Library/Sounds/Basso.aiff',
      start: '/System/Library/Sounds/Pop.aiff'
    };
    exec(`afplay ${sounds[type] || sounds.start}`);
  }
}

// 처리 목록 로드
function loadProcessedFiles() {
  try {
    if (fs.existsSync(PROCESSED_FILE)) {
      const data = fs.readFileSync(PROCESSED_FILE, 'utf8');
      data.split('\n').filter(Boolean).forEach(f => processedFiles.add(f));
      console.log(`[Manager] 기존 처리 목록: ${processedFiles.size}개`);
    }
  } catch (e) {}
}

// 처리 목록 저장
function saveProcessedFile(filename) {
  processedFiles.add(filename);
  fs.appendFileSync(PROCESSED_FILE, filename + '\n');
}

// 빅스텝 완료 표시 (_DONE_ 접두사)
function markAsDone(filename) {
  const oldPath = path.join(BIGSTEP_PATH, filename);
  const newPath = path.join(BIGSTEP_PATH, `_DONE_${filename}`);
  try {
    if (fs.existsSync(oldPath) && !fs.existsSync(newPath)) {
      fs.renameSync(oldPath, newPath);
      console.log(`[Manager] 완료 표시: ${filename} → _DONE_${filename}`);
    }
  } catch (e) {
    console.error('[Manager] 파일명 변경 실패:', e.message);
  }
}

// ============================================================
// Opus 통합 호출
// ============================================================

function callOpusManager(bigstepContent, filename, retryCount = 0) {
  return new Promise((resolve, reject) => {
    const claudePath = getClaudePath();
    const shellConfig = getShellConfig();
    const bigstepId = filename.match(/BIG_(\d+)/)?.[1] || '000';
    
    // 디바이스 정보
    const phoneDevice = os.platform() === 'win32' ? 'RFCY40MNBLL' : 'auto';
    
    const prompt = `당신은 EDU-VICE-Attendance 프로젝트의 Manager(Opus)입니다.

## 프로젝트 정보
- 프로젝트 경로: ${PROJECT_ROOT}
- Flutter 앱 경로: ${FLUTTER_APP}
- 폰 디바이스 ID: ${phoneDevice}
- OS: ${os.platform()}

## 빅스텝 요청 (BIG_${bigstepId})
${bigstepContent}

## 리트라이 정보
- 현재 시도: ${retryCount + 1}/${MAX_FAILURES}
${retryCount > 0 ? '- 이전 시도가 실패했습니다. 다른 방법을 시도하세요.' : ''}

## 당신의 역할
1. 빅스텝 내용을 분석하세요
2. 필요한 작업을 직접 수행하세요:
   - 코드 수정이면 → 직접 파일 수정
   - 듀얼 디버깅이면 → flutter run 명령 실행 (폰: -d ${phoneDevice}, 웹: -d chrome --web-port=8080)
   - 커밋이면 → git 명령 실행
   - 분석이면 → 분석 후 결과 보고
3. 작업 결과를 검증하세요
4. 최종 결과를 보고하세요

## 중요 규칙
- 물어보지 말고 직접 수행
- 막히면 다른 방법 시도
- 실패하면 이유를 명확히 보고
- 듀얼 디버깅: 두 앱이 모두 빌드 완료될 때까지 대기

## 응답 형식 (마지막에 반드시 포함)
---
RESULT: SUCCESS 또는 FAIL
SUMMARY: 수행한 작업 요약 (1-2문장)
`;

    const promptFile = path.join(AI_BRIDGE, '.temp_opus_manager.txt');
    fs.writeFileSync(promptFile, prompt);

    let cmd, args;
    if (os.platform() === 'win32') {
      cmd = 'powershell.exe';
      args = ['-Command', `Get-Content "${promptFile}" -Raw | ${claudePath} -p --model claude-opus-4-20250514 --dangerously-skip-permissions`];
    } else {
      cmd = '/bin/bash';
      args = ['-c', `cat "${promptFile}" | ${claudePath} -p --model claude-opus-4-20250514 --dangerously-skip-permissions`];
    }

    console.log(`[Manager] Opus 호출 중... (시도 ${retryCount + 1}/${MAX_FAILURES})`);
    console.log('[Manager] --- Opus 작업 중 (1~5분 소요) ---');

    const { spawn } = require('child_process');
    const child = spawn(cmd, args, {
      cwd: PROJECT_ROOT,
      stdio: ['pipe', 'pipe', 'pipe']
    });

    let stdout = '';
    let stderr = '';

    // 실시간 출력
    child.stdout.on('data', (data) => {
      const text = data.toString();
      stdout += text;
      // 한 줄씩 출력 (진행상황 보여주기)
      text.split('\n').forEach(line => {
        if (line.trim()) {
          console.log(`  ${line.substring(0, 100)}${line.length > 100 ? '...' : ''}`);
        }
      });
    });

    child.stderr.on('data', (data) => {
      stderr += data.toString();
    });

    child.on('close', (code) => {
      try { fs.unlinkSync(promptFile); } catch (e) {}
      
      console.log('[Manager] --- Opus 작업 완료 ---');
      
      if (code !== 0) {
        console.error(`[Manager] Opus 에러 (exit code: ${code})`);
        reject({ success: false, error: stderr || `exit code ${code}`, output: stdout });
        return;
      }
      
      // 결과 파싱
      const resultMatch = stdout.match(/RESULT:\s*(SUCCESS|FAIL)/i);
      const summaryMatch = stdout.match(/SUMMARY:\s*(.+?)(?:\n|$)/is);
      
      const success = resultMatch && resultMatch[1].toUpperCase() === 'SUCCESS';
      const summary = summaryMatch ? summaryMatch[1].trim() : '요약 없음';
      
      console.log(`[Manager] Opus 결과: ${success ? 'SUCCESS ✅' : 'FAIL ❌'}`);
      console.log(`[Manager] 요약: ${summary}`);
      
      resolve({ success, summary, output: stdout });
    });

    child.on('error', (err) => {
      try { fs.unlinkSync(promptFile); } catch (e) {}
      console.error(`[Manager] Opus 실행 에러:`, err.message);
      reject({ success: false, error: err.message, output: '' });
    });

    // 15분 타임아웃
    setTimeout(() => {
      child.kill();
      reject({ success: false, error: 'Timeout (15분)', output: stdout });
    }, 900000);
  });
}

// ============================================================
// 빅스텝 처리
// ============================================================

async function handleBigstep(filepath) {
  const filename = path.basename(filepath);
  
  // _DONE_ 파일 무시
  if (filename.startsWith('_DONE_')) return;
  if (processedFiles.has(filename)) return;
  
  // 파일 존재 확인
  if (!fs.existsSync(filepath)) return;
  
  // 동시 실행 방지
  if (isProcessing) {
    console.log(`[Manager] 이미 작업 중, 대기: ${filename}`);
    return;
  }
  
  isProcessing = true;
  
  console.log('\n' + '='.repeat(60));
  console.log(`[Manager] 빅스텝 감지: ${filename}`);
  console.log('='.repeat(60));
  
  playSound('start');
  
  const bigstepContent = fs.readFileSync(filepath, 'utf8');
  const bigstepId = filename.match(/BIG_(\d+)/)?.[1] || '000';
  
  // 실패 카운터 초기화
  if (!failureCount[filename]) {
    failureCount[filename] = 0;
  }
  
  let success = false;
  let lastResult = null;
  
  // 최대 3회 시도
  while (failureCount[filename] < MAX_FAILURES && !success) {
    try {
      lastResult = await callOpusManager(bigstepContent, filename, failureCount[filename]);
      success = lastResult.success;
      
      if (!success) {
        failureCount[filename]++;
        console.log(`[Manager] 실패 (${failureCount[filename]}/${MAX_FAILURES})`);
        
        if (failureCount[filename] < MAX_FAILURES) {
          console.log(`[Manager] 리트라이 중...`);
          playSound('fail');
        }
      }
    } catch (e) {
      failureCount[filename]++;
      console.error(`[Manager] 에러: ${e.error || e.message}`);
      lastResult = { success: false, summary: e.error || e.message, output: '' };
      
      if (failureCount[filename] < MAX_FAILURES) {
        console.log(`[Manager] 리트라이 중...`);
        playSound('fail');
      }
    }
  }
  
  // 결과 처리
  if (success) {
    console.log(`[Manager] ✅ 빅스텝 완료!`);
    saveProcessedFile(filename);
    markAsDone(filename);
    playSound('success');
  } else {
    console.log(`[Manager] ❌ 빅스텝 실패 (${MAX_FAILURES}회 시도 후 중단)`);
    
    // 실패 보고서 작성
    const reportFilename = `big_${bigstepId}_FAIL_report.md`;
    const reportPath = path.join(REPORT_PATH, reportFilename);
    
    const failReport = `# BIG_${bigstepId} 실패 보고서

## 📋 요청 사항
${bigstepContent}

## ❌ 실패 정보
- 시도 횟수: ${MAX_FAILURES}회
- 마지막 요약: ${lastResult?.summary || '없음'}

## 📝 마지막 출력
\`\`\`
${(lastResult?.output || '').substring(0, 2000)}
\`\`\`

---
> **생성**: Manager 자동 생성
> **시간**: ${new Date().toISOString()}
`;
    
    fs.writeFileSync(reportPath, failReport);
    console.log(`[Manager] 실패 보고서: ${reportFilename}`);
    
    saveProcessedFile(filename);
    markAsDone(filename);
    playSound('fail');
  }
  
  isProcessing = false;
}

// ============================================================
// 메인
// ============================================================

function main() {
  console.log('='.repeat(60));
  console.log('  2실린더 자동화 시스템 v6 - Manager (Opus 통합)');
  console.log('  ');
  console.log('  AI 구조:');
  console.log('  - Opus: 전체 관리 (분석 + 실행 + 검증)');
  console.log('  ');
  console.log('  기능:');
  console.log('  - Opus 통합 관리');
  console.log('  - _DONE_ 완료 표시');
  console.log('  - 최대 리트라이: ' + MAX_FAILURES + '회');
  console.log('  - 실패 시 보고서 작성');
  console.log('='.repeat(60));
  console.log();
  console.log(`빅스텝 경로: ${BIGSTEP_PATH}`);
  console.log(`OS: ${os.platform()}`);
  console.log();
  console.log('종료하려면 Ctrl+C');
  console.log();

  loadProcessedFiles();

  // 빅스텝 감시
  const bigstepWatcher = chokidar.watch(BIGSTEP_PATH, {
    persistent: true,
    ignoreInitial: false,
    awaitWriteFinish: { stabilityThreshold: 1000, pollInterval: 100 }
  });

  // 이미 처리된 파일 카운터
  let skippedCount = 0;

  bigstepWatcher.on('add', (filepath) => {
    const filename = path.basename(filepath);
    if (filename.startsWith('BIG_') && filename.endsWith('.md') && !filename.startsWith('_DONE_')) {
      if (processedFiles.has(filename)) {
        skippedCount++;
        if (skippedCount <= 5) {
          console.log(`[Manager] 이미 처리됨: ${filename}`);
        } else if (skippedCount === 6) {
          console.log(`[Manager] ... (나머지는 생략)`);
        }
        return;
      }
      setTimeout(() => handleBigstep(filepath), 500);
    }
  });

  bigstepWatcher.on('ready', () => {
    if (skippedCount > 0) {
      console.log(`[Manager] 총 ${skippedCount}개 파일 이미 처리됨`);
    }
    console.log('[Manager] 감시 대기 중... 새 빅스텝을 기다립니다.\n');
  });

  process.on('SIGINT', () => {
    console.log('\n[Manager] 종료');
    bigstepWatcher.close();
    process.exit(0);
  });
}

main();
