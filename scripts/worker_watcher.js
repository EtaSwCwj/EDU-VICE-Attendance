/**
 * 후임 Watcher (VSCode Sonnet)
 * 
 * 역할:
 * - smallstep/ 감시 → 실행 → result/ 에 결과 저장
 * 
 * 사용법:
 *   npm run watch:worker
 */

const chokidar = require('chokidar');
const { spawn, exec } = require('child_process');
const path = require('path');
const fs = require('fs');
const os = require('os');

// 경로 설정
const AI_BRIDGE = path.join(__dirname, '..', 'ai_bridge');
const SMALLSTEP_PATH = path.join(AI_BRIDGE, 'smallstep');
const RESULT_PATH = path.join(AI_BRIDGE, 'result');

// 폴더 확인
if (!fs.existsSync(RESULT_PATH)) {
  fs.mkdirSync(RESULT_PATH, { recursive: true });
}

// 처리된 파일 추적
const processedFiles = new Set();
const PROCESSED_FILE = path.join(AI_BRIDGE, '.processed_worker');

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

// 처리 목록 로드
function loadProcessedFiles() {
  try {
    if (fs.existsSync(PROCESSED_FILE)) {
      const data = fs.readFileSync(PROCESSED_FILE, 'utf8');
      data.split('\n').filter(Boolean).forEach(f => processedFiles.add(f));
      console.log(`[Worker] 기존 처리 목록: ${processedFiles.size}개`);
    }
  } catch (e) {
    // 무시
  }
}

function saveProcessedFile(filename) {
  processedFiles.add(filename);
  fs.appendFileSync(PROCESSED_FILE, filename + '\n');
}

// 스몰스텝 실행
function handleSmallstep(filepath) {
  const filename = path.basename(filepath);
  if (processedFiles.has(filename)) {
    console.log(`[Worker] 이미 처리됨: ${filename}`);
    return;
  }
  
  console.log('\n' + '='.repeat(60));
  console.log(`[Worker] 스몰스텝 감지: ${filename}`);
  console.log('[Worker] Sonnet 실행 중...');
  console.log('='.repeat(60) + '\n');
  
  // 지시서 내용 직접 읽기
  const taskContent = fs.readFileSync(filepath, 'utf8');
  
  // 결과 파일명 생성
  const match = filename.match(/SMALL_(\d+)_(\d+)/);
  const resultFilename = match 
    ? `small_${match[1]}_${match[2]}_result.md`
    : `${filename.replace('.md', '_result.md')}`;
  const resultPath = path.join(RESULT_PATH, resultFilename);
  
  // 임시 프롬프트 파일 생성
  const promptFile = path.join(AI_BRIDGE, '.temp_prompt.txt');
  const prompt = `아래 지시를 수행하세요. 설명하지 말고 바로 파일을 생성하세요.

지시 내용:
${taskContent}

작업 완료 후 결과를 ${resultPath} 파일에 저장하세요.`;

  fs.writeFileSync(promptFile, prompt);

  // 파일에서 읽어서 실행
  const cmd = os.platform() === 'win32'
    ? `type "${promptFile}" | claude -p --model claude-sonnet-4-20250514 --dangerously-skip-permissions`
    : `cat "${promptFile}" | claude -p --model claude-sonnet-4-20250514 --dangerously-skip-permissions`;

  exec(cmd, { cwd: path.join(__dirname, '..'), maxBuffer: 10 * 1024 * 1024 }, (error, stdout, stderr) => {
    // 임시 파일 삭제
    try { fs.unlinkSync(promptFile); } catch (e) {}
    
    if (error) {
      console.error(`[Worker] 실행 실패: ${error.message}`);
      playSound(false);
      return;
    }
    
    console.log(stdout);
    if (stderr) console.error(stderr);
    
    console.log(`\n[Worker] 스몰스텝 완료 ✅`);
    saveProcessedFile(filename);
    playSound(true);
  });
}

// 메인
function main() {
  console.log('='.repeat(60));
  console.log('  후임 시스템 (Worker)');
  console.log('  smallstep/ 감시 중...');
  console.log('='.repeat(60));
  console.log(`\n스몰스텝 경로: ${SMALLSTEP_PATH}`);
  console.log(`결과 경로: ${RESULT_PATH}`);
  console.log('\n종료하려면 Ctrl+C\n');
  
  loadProcessedFiles();
  
  // smallstep 감시
  const watcher = chokidar.watch(path.join(SMALLSTEP_PATH, 'SMALL_*.md'), {
    persistent: true,
    ignoreInitial: true,
    awaitWriteFinish: { stabilityThreshold: 1000, pollInterval: 100 }
  });
  
  watcher.on('add', handleSmallstep);
  
  watcher.on('error', (error) => {
    console.error(`[Worker] 에러: ${error}`);
  });
  
  process.on('SIGINT', () => {
    console.log('\n[Worker] 종료');
    watcher.close();
    process.exit(0);
  });
}

main();
