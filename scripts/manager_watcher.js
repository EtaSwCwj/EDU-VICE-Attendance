/**
 * 중간관리자 Watcher (Manager) - Worker 호출 버전
 * 
 * 역할:
 * 1. bigstep/ 감시 → 스몰스텝 생성 → Worker 호출
 * 2. result/ 감시 → 교차검증 → 재지시시 Worker 다시 호출
 * 
 * Worker는 일회성 실행 후 종료됨
 * 
 * 사용법:
 *   npm run watch:manager
 */

const chokidar = require('chokidar');
const { exec, spawn } = require('child_process');
const path = require('path');
const fs = require('fs');
const os = require('os');

// 경로 설정
const PROJECT_ROOT = path.join(__dirname, '..');
const AI_BRIDGE = path.join(PROJECT_ROOT, 'ai_bridge');
const FLUTTER_APP = path.join(PROJECT_ROOT, 'flutter_application_1');
const BIGSTEP_PATH = path.join(AI_BRIDGE, 'bigstep');
const SMALLSTEP_PATH = path.join(AI_BRIDGE, 'smallstep');
const RESULT_PATH = path.join(AI_BRIDGE, 'result');
const REPORT_PATH = path.join(AI_BRIDGE, 'report');

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

// Worker 호출 (일회성)
function runWorker() {
  return new Promise((resolve, reject) => {
    console.log(`[Manager] Worker 호출 중...`);
    
    const worker = spawn('node', ['scripts/worker_watcher.js'], {
      cwd: PROJECT_ROOT,
      stdio: 'inherit'
    });
    
    worker.on('close', (code) => {
      if (code === 0) {
        console.log(`[Manager] Worker 완료`);
        resolve();
      } else {
        console.log(`[Manager] Worker 실패 (코드: ${code})`);
        reject(new Error(`Worker exited with code ${code}`));
      }
    });
    
    worker.on('error', (err) => {
      console.error(`[Manager] Worker 실행 오류: ${err.message}`);
      reject(err);
    });
  });
}

// Claude 호출 (파이프라인)
function callClaude(prompt) {
  return new Promise((resolve, reject) => {
    const promptFile = path.join(AI_BRIDGE, '.temp_prompt_manager.txt');
    fs.writeFileSync(promptFile, prompt);

    const cmd = os.platform() === 'win32'
      ? `type "${promptFile}" | claude -p --model claude-sonnet-4-20250514 --dangerously-skip-permissions`
      : `cat "${promptFile}" | claude -p --model claude-sonnet-4-20250514 --dangerously-skip-permissions`;

    exec(cmd, { cwd: PROJECT_ROOT, maxBuffer: 10 * 1024 * 1024 }, (error, stdout, stderr) => {
      try { fs.unlinkSync(promptFile); } catch (e) {}
      
      if (error) {
        reject(error);
      } else {
        resolve(stdout);
      }
    });
  });
}

// result에서 변경된 파일 경로 추출
function extractChangedFiles(resultContent) {
  const files = [];
  
  const patterns = [
    /flutter_application_1\/lib\/[^\s\`\"\'\)]+\.dart/g,
    /lib\/[^\s\`\"\'\)]+\.dart/g,
    /ai_bridge\/[^\s\`\"\'\)]+\.(txt|md)/g,
  ];
  
  patterns.forEach(pattern => {
    const matches = resultContent.match(pattern);
    if (matches) {
      matches.forEach(m => {
        const fullPath = m.startsWith('flutter_application_1') || m.startsWith('ai_bridge')
          ? path.join(PROJECT_ROOT, m)
          : path.join(FLUTTER_APP, m);
        if (!files.includes(fullPath)) {
          files.push(fullPath);
        }
      });
    }
  });
  
  return files;
}

// 실제 코드 파일 읽기
function readCodeFiles(filePaths) {
  let codeContent = '';
  
  filePaths.forEach(filePath => {
    try {
      if (fs.existsSync(filePath)) {
        const content = fs.readFileSync(filePath, 'utf8');
        const relativePath = path.relative(PROJECT_ROOT, filePath);
        codeContent += `\n\n=== ${relativePath} ===\n${content.substring(0, 2000)}${content.length > 2000 ? '\n... (truncated)' : ''}\n`;
      }
    } catch (e) {
      codeContent += `\n\n=== ${filePath} ===\n[읽기 실패: ${e.message}]\n`;
    }
  });
  
  return codeContent;
}

// 빅스텝 처리
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
    saveProcessedFile(filename);
    
    // Worker 호출
    await runWorker();
    console.log(`[Manager] 빅스텝 분해 완료 ✅`);
    
  } catch (e) {
    console.error(`[Manager] 처리 실패: ${e.message}`);
    playSound(false);
  }
}

// 결과 교차검증
async function handleResult(filepath) {
  const filename = path.basename(filepath);
  if (processedFiles.has(filename)) {
    console.log(`[Manager] 이미 처리됨: ${filename}`);
    return;
  }
  
  console.log('\n' + '='.repeat(60));
  console.log(`[Manager] 결과 감지: ${filename}`);
  console.log(`[Manager] 교차검증 중...`);
  console.log('='.repeat(60));
  
  const resultContent = fs.readFileSync(filepath, 'utf8');
  
  const changedFiles = extractChangedFiles(resultContent);
  const actualCode = readCodeFiles(changedFiles);
  
  console.log(`[Manager] 검토 대상 파일: ${changedFiles.length}개`);
  
  const match = filename.match(/small_(\d+)_(\d+)/);
  const bigstepId = match?.[1] || '000';
  const smallstepNum = parseInt(match?.[2] || '1');
  
  const bigstepFiles = fs.readdirSync(BIGSTEP_PATH).filter(f => f.includes(`BIG_${bigstepId}`));
  let originalTask = '';
  if (bigstepFiles.length > 0) {
    originalTask = fs.readFileSync(path.join(BIGSTEP_PATH, bigstepFiles[0]), 'utf8');
  }
  
  // 작업 유형 판단
  const taskLower = originalTask.toLowerCase();
  let taskType = 'code';
  
  if (taskLower.includes('분석') || taskLower.includes('analysis') || taskLower.includes('상태 확인') || taskLower.includes('파악') || taskLower.includes('검토')) {
    taskType = 'analysis';
  } else if (taskLower.includes('커밋') || taskLower.includes('commit') || taskLower.includes('push') || taskLower.includes('git add')) {
    taskType = 'commit';
  } else if (taskLower.includes('삭제') || taskLower.includes('delete') || taskLower.includes('정리') || taskLower.includes('cleanup')) {
    taskType = 'cleanup';
  }
  
  console.log(`[Manager] 작업 유형: ${taskType}`);
  
  let judgmentCriteria = '';
  switch (taskType) {
    case 'analysis':
      judgmentCriteria = `=== 교차검증 기준 (분석 작업) ===
1. 요청한 분석 항목을 모두 다뤘는가?
2. 분석 내용이 구체적이고 정확한가?
3. 존재하지 않는 파일을 "구현 완료"라고 거짓 보고하지 않았는가?
4. 결론과 다음 단계 권장사항이 명확한가?`;
      break;
    case 'commit':
      judgmentCriteria = `=== 교차검증 기준 (커밋 작업) ===
1. git commit이 성공했는가?
2. git push가 성공했는가?
3. 커밋 메시지가 적절한가?`;
      break;
    case 'cleanup':
      judgmentCriteria = `=== 교차검증 기준 (정리 작업) ===
1. 요청한 파일들이 삭제되었는가?
2. 삭제하면 안 되는 파일을 삭제하지 않았는가?
3. flutter analyze 에러가 없는가?`;
      break;
    default:
      judgmentCriteria = `=== 교차검증 기준 (코드 작업) ===
1. 빅스텝 요청사항을 모두 수행했는가?
2. flutter analyze 에러가 있는가? (error가 1개라도 있으면 FAIL)
3. 실제 코드가 보고 내용과 일치하는가?
4. 코드 품질에 문제가 없는가? (문법, 구조, 네이밍)`;
  }
  
  const judgmentPrompt = `당신은 중간관리자입니다. 후임의 작업을 교차검증하세요.

=== 원본 빅스텝 요청 ===
${originalTask}

=== 후임의 작업 보고 ===
${resultContent}

=== 실제 코드 (직접 확인) ===
${actualCode || '(변경된 코드 파일 없음)'}

${judgmentCriteria}

=== 판단 ===
모든 기준을 통과하면: "SUCCESS"
하나라도 실패하면: "FAIL: (구체적 이유)"

반드시 한 줄로만 응답. 다른 말 하지 마.`;

  try {
    const judgment = await callClaude(judgmentPrompt);
    console.log(`[Manager] 판단 결과: ${judgment.trim()}`);
    
    if (judgment.toUpperCase().includes('SUCCESS')) {
      const reportPrompt = `당신은 중간관리자입니다. CP/선임에게 보고할 최종 보고서를 작성하세요.

=== 원본 빅스텝 요청 ===
${originalTask}

=== 후임 작업 결과 ===
${resultContent}

=== 실제 코드 (직접 확인) ===
${actualCode || '(변경된 코드 파일 없음)'}

=== 보고서 형식 ===
# BIG_${bigstepId} 완료 보고서

## 📋 요청 사항
(빅스텝에서 요청한 내용 요약)

## ✅ 수행 결과
(무엇을 했는지)

## 🔍 교차검증 결과
- 실제 코드 직접 확인: ✅
- 요청사항 충족: ✅
- flutter analyze 에러: 0개
- 코드 품질: (간단한 평가)

## 📁 변경된 파일
(파일 목록)

## 💬 중간관리자 의견
(한두 줄로 간단히)

---
위 형식으로 보고서를 작성하세요.`;

      const report = await callClaude(reportPrompt);
      
      const reportFilename = `big_${bigstepId}_report.md`;
      const reportPath = path.join(REPORT_PATH, reportFilename);
      
      const finalReport = `${report}

---
> **생성**: 중간관리자 자동 생성
> **시간**: ${new Date().toISOString()}
> **교차검증**: ✅ 실제 코드 직접 확인 완료
`;
      
      fs.writeFileSync(reportPath, finalReport);
      console.log(`[Manager] 보고서 생성: ${reportFilename}`);
      console.log(`[Manager] 결과 검토 완료 ✅`);
      playSound(true);
      
    } else {
      // 실패 → 재지시 생성 → Worker 다시 호출
      const failReason = judgment.replace(/FAIL:?/i, '').trim();
      const retryFilename = `SMALL_${bigstepId}_${String(smallstepNum + 1).padStart(2, '0')}_RETRY.md`;
      const retryPath = path.join(SMALLSTEP_PATH, retryFilename);
      const retryResultPath = path.join(RESULT_PATH, `small_${bigstepId}_${String(smallstepNum + 1).padStart(2, '0')}_result.md`);
      
      const retryContent = `# ${retryFilename}

> **재지시**: 교차검증 실패
> **실패 이유**: ${failReason}

---

## 📋 원본 작업

${originalTask}

---

## ⚠️ 이전 결과 (실패)

${resultContent}

---

## 🔍 중간관리자 교차검증 결과

실제 코드를 직접 확인한 결과: **${failReason}**

---

## 🔧 수정 지시

위 문제를 수정하세요. 반드시:
1. flutter analyze 에러 0개
2. 요청사항 모두 충족
3. 코드 품질 확보

---

**결과는 \`${retryResultPath}\`에 저장할 것.**
`;
      
      fs.writeFileSync(retryPath, retryContent);
      console.log(`[Manager] 재지시 생성: ${retryFilename}`);
      
      // Worker 다시 호출
      await runWorker();
      console.log(`[Manager] 재지시 완료 ⚠️`);
      playSound(false);
    }
    
    saveProcessedFile(filename);
    
  } catch (e) {
    console.error(`[Manager] 검증 실패: ${e.message}`);
    playSound(false);
  }
}

// 메인
function main() {
  console.log('='.repeat(60));
  console.log('  중간관리자 시스템 (Manager) - Worker 호출 버전');
  console.log('  bigstep/, result/ 감시 중...');
  console.log('='.repeat(60));
  console.log(`\n빅스텝 경로: ${BIGSTEP_PATH}`);
  console.log(`스몰스텝 경로: ${SMALLSTEP_PATH}`);
  console.log(`결과 경로: ${RESULT_PATH}`);
  console.log('\n종료하려면 Ctrl+C\n');
  
  loadProcessedFiles();
  
  const bigstepWatcher = chokidar.watch(path.join(BIGSTEP_PATH, 'BIG_*.md'), {
    persistent: true,
    ignoreInitial: true,
    awaitWriteFinish: { stabilityThreshold: 1000, pollInterval: 100 }
  });
  
  bigstepWatcher.on('add', handleBigstep);
  
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
