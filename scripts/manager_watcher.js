/**
 * 중간관리자 Watcher (VSCode Opus) - 파이프라인 버전
 * 
 * 역할:
 * 1. bigstep/ 감시 → 스몰스텝으로 분해 → smallstep/ 생성
 * 2. result/ 감시 → Claude가 판단 → 재지시 or 보고
 * 
 * 사용법:
 *   npm run watch:manager
 */

const chokidar = require('chokidar');
const { exec } = require('child_process');
const path = require('path');
const fs = require('fs');
const os = require('os');

// 경로 설정
const AI_BRIDGE = path.join(__dirname, '..', 'ai_bridge');
const BIGSTEP_PATH = path.join(AI_BRIDGE, 'bigstep');
const SMALLSTEP_PATH = path.join(AI_BRIDGE, 'smallstep');
const RESULT_PATH = path.join(AI_BRIDGE, 'result');
const REPORT_PATH = path.join(AI_BRIDGE, 'report');
const LEARNING_PATH = path.join(AI_BRIDGE, 'learning');

// 폴더 존재 확인 및 생성
[SMALLSTEP_PATH, RESULT_PATH, REPORT_PATH].forEach(dir => {
  if (!fs.existsSync(dir)) {
    fs.mkdirSync(dir, { recursive: true });
  }
});

// 처리된 파일 추적
const processedFiles = new Set();
const PROCESSED_FILE = path.join(AI_BRIDGE, '.processed_manager');

// 알림 소리
function playSound(success = true) {
  if (os.platform() === 'win32') {
    if (success) {
      exec('powershell -c "[console]::beep(800, 300); [console]::beep(1000, 300); [console]::beep(1200, 500)"');
    } else {
      exec('powershell -c "[console]::beep(400, 500); [console]::beep(300, 500)"');
    }
  } else if (os.platform() === 'darwin') {
    const sound = success ? '/System/Library/Sounds/Glass.aiff' : '/System/Library/Sounds/Basso.aiff';
    exec(`afplay ${sound}`);
  }
}

// 처리 목록 로드/저장
function loadProcessedFiles() {
  try {
    if (fs.existsSync(PROCESSED_FILE)) {
      const data = fs.readFileSync(PROCESSED_FILE, 'utf8');
      data.split('\n').filter(Boolean).forEach(f => processedFiles.add(f));
      console.log(`[Manager] 기존 처리 목록: ${processedFiles.size}개`);
    }
  } catch (e) {}
}

function saveProcessedFile(filename) {
  processedFiles.add(filename);
  fs.appendFileSync(PROCESSED_FILE, filename + '\n');
}

// Claude 호출 (파이프라인)
function callClaude(prompt) {
  return new Promise((resolve, reject) => {
    const promptFile = path.join(AI_BRIDGE, '.temp_prompt_manager.txt');
    fs.writeFileSync(promptFile, prompt);

    const cmd = os.platform() === 'win32'
      ? `type "${promptFile}" | claude -p --model claude-sonnet-4-20250514 --dangerously-skip-permissions`
      : `cat "${promptFile}" | claude -p --model claude-sonnet-4-20250514 --dangerously-skip-permissions`;

    exec(cmd, { cwd: path.join(__dirname, '..'), maxBuffer: 10 * 1024 * 1024 }, (error, stdout, stderr) => {
      try { fs.unlinkSync(promptFile); } catch (e) {}
      
      if (error) {
        reject(error);
      } else {
        resolve(stdout);
      }
    });
  });
}

// 빅스텝 처리: 스몰스텝으로 분해
async function handleBigstep(filepath) {
  const filename = path.basename(filepath);
  if (processedFiles.has(filename)) {
    console.log(`[Manager] 이미 처리됨: ${filename}`);
    return;
  }
  
  console.log('\n' + '='.repeat(60));
  console.log(`[Manager] 빅스텝 감지: ${filename}`);
  console.log('='.repeat(60));
  
  const bigstepContent = fs.readFileSync(filepath, 'utf8');
  const bigstepId = filename.match(/BIG_(\d+)/)?.[1] || '000';
  
  // 스몰스텝 파일 직접 생성 (단순 분해)
  const smallstepFilename = `SMALL_${bigstepId}_01_EXECUTE.md`;
  const smallstepPath = path.join(SMALLSTEP_PATH, smallstepFilename);
  const resultPath = path.join(RESULT_PATH, `small_${bigstepId}_01_result.md`);
  
  const smallstepContent = `# ${smallstepFilename}

> **빅스텝**: ${filename}

---

## 📋 작업 내용

${bigstepContent}

---

**결과는 \`${resultPath}\`에 저장할 것.**
`;

  try {
    fs.writeFileSync(smallstepPath, smallstepContent);
    console.log(`[Manager] 스몰스텝 생성: ${smallstepFilename}`);
    console.log(`[Manager] 빅스텝 분해 완료 ✅`);
    saveProcessedFile(filename);
    playSound(true);
  } catch (e) {
    console.error(`[Manager] 스몰스텝 생성 실패: ${e.message}`);
    playSound(false);
  }
}

// 결과 검토: Claude가 판단 → 재지시 or 보고
async function handleResult(filepath) {
  const filename = path.basename(filepath);
  if (processedFiles.has(filename)) {
    console.log(`[Manager] 이미 처리됨: ${filename}`);
    return;
  }
  
  console.log('\n' + '='.repeat(60));
  console.log(`[Manager] 결과 감지: ${filename}`);
  console.log(`[Manager] Claude 판단 중...`);
  console.log('='.repeat(60));
  
  const resultContent = fs.readFileSync(filepath, 'utf8');
  
  // 빅스텝 ID 추출
  const match = filename.match(/small_(\d+)_(\d+)/);
  const bigstepId = match?.[1] || '000';
  const smallstepNum = parseInt(match?.[2] || '1');
  
  // 1단계: Claude가 결과 판단
  const judgmentPrompt = `아래 작업 결과를 분석하고, 딱 한 줄로 판단해.

=== 작업 결과 ===
${resultContent}
=== 결과 끝 ===

판단 기준:
- 작업이 성공적으로 완료되었으면: "SUCCESS"
- 에러가 있거나 작업이 실패했으면: "FAIL: (이유)"

반드시 "SUCCESS" 또는 "FAIL: (이유)" 중 하나로만 응답해. 다른 말 하지 마.`;

  try {
    const judgment = await callClaude(judgmentPrompt);
    console.log(`[Manager] 판단 결과: ${judgment.trim()}`);
    
    if (judgment.toUpperCase().includes('SUCCESS')) {
      // 성공 → 보고서 생성
      const reportFilename = `big_${bigstepId}_report.md`;
      const reportPath = path.join(REPORT_PATH, reportFilename);
      
      const reportContent = `# BIG_${bigstepId} 완료 보고서

> **생성**: 중간관리자 자동 생성
> **시간**: ${new Date().toISOString()}
> **판단**: ✅ SUCCESS

---

## 📋 결과 요약

${resultContent}

---

## ✅ 상태

작업 성공. CP/선임 확인 필요.
`;
      
      fs.writeFileSync(reportPath, reportContent);
      console.log(`[Manager] 보고서 생성: ${reportFilename}`);
      console.log(`[Manager] 결과 검토 완료 ✅`);
      playSound(true);
      
    } else {
      // 실패 → 재지시
      const failReason = judgment.replace(/FAIL:?/i, '').trim();
      const retryFilename = `SMALL_${bigstepId}_${String(smallstepNum + 1).padStart(2, '0')}_RETRY.md`;
      const retryPath = path.join(SMALLSTEP_PATH, retryFilename);
      const retryResultPath = path.join(RESULT_PATH, `small_${bigstepId}_${String(smallstepNum + 1).padStart(2, '0')}_result.md`);
      
      // 원본 빅스텝 읽기
      const bigstepFiles = fs.readdirSync(BIGSTEP_PATH).filter(f => f.includes(`BIG_${bigstepId}`));
      let originalTask = '원본 빅스텝을 찾을 수 없음';
      if (bigstepFiles.length > 0) {
        originalTask = fs.readFileSync(path.join(BIGSTEP_PATH, bigstepFiles[0]), 'utf8');
      }
      
      const retryContent = `# ${retryFilename}

> **재지시**: 이전 작업 실패로 인한 재시도
> **실패 이유**: ${failReason}

---

## 📋 원본 작업

${originalTask}

---

## ⚠️ 이전 실패 내용

${resultContent}

---

## 🔧 수정 지시

이전 실패를 참고해서 다시 작업해. 실패 이유: ${failReason}

---

**결과는 \`${retryResultPath}\`에 저장할 것.**
`;
      
      fs.writeFileSync(retryPath, retryContent);
      console.log(`[Manager] 재지시 생성: ${retryFilename}`);
      console.log(`[Manager] 재지시 완료 ⚠️`);
      playSound(false);
    }
    
    saveProcessedFile(filename);
    
  } catch (e) {
    console.error(`[Manager] 판단 실패: ${e.message}`);
    playSound(false);
  }
}

// 메인
function main() {
  console.log('='.repeat(60));
  console.log('  중간관리자 시스템 (Manager) - 파이프라인 버전');
  console.log('  bigstep/, result/ 감시 중...');
  console.log('='.repeat(60));
  console.log(`\n빅스텝 경로: ${BIGSTEP_PATH}`);
  console.log(`스몰스텝 경로: ${SMALLSTEP_PATH}`);
  console.log(`결과 경로: ${RESULT_PATH}`);
  console.log('\n종료하려면 Ctrl+C\n');
  
  loadProcessedFiles();
  
  // bigstep 감시
  const bigstepWatcher = chokidar.watch(path.join(BIGSTEP_PATH, 'BIG_*.md'), {
    persistent: true,
    ignoreInitial: true,
    awaitWriteFinish: { stabilityThreshold: 1000, pollInterval: 100 }
  });
  
  bigstepWatcher.on('add', handleBigstep);
  
  // result 감시
  const resultWatcher = chokidar.watch(path.join(RESULT_PATH, '*_result.md'), {
    persistent: true,
    ignoreInitial: true,
    awaitWriteFinish: { stabilityThreshold: 1000, pollInterval: 100 }
  });
  
  resultWatcher.on('add', handleResult);
  
  process.on('SIGINT', () => {
    console.log('\n[Manager] 종료');
    bigstepWatcher.close();
    resultWatcher.close();
    process.exit(0);
  });
}

main();
