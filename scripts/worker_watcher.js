/**
 * 후임 Worker (일회성 실행)
 * 
 * 역할:
 * - smallstep/ 에서 미처리 파일 찾기 → 실행 → result/ 저장 → 종료
 * 
 * 사용법:
 *   npm run watch:worker (Manager가 호출)
 */

const { exec } = require('child_process');
const path = require('path');
const fs = require('fs');
const os = require('os');

// 경로 설정
const PROJECT_ROOT = path.join(__dirname, '..');
const AI_BRIDGE = path.join(PROJECT_ROOT, 'ai_bridge');
const SMALLSTEP_PATH = path.join(AI_BRIDGE, 'smallstep');
const RESULT_PATH = path.join(AI_BRIDGE, 'result');

// 폴더 확인
if (!fs.existsSync(RESULT_PATH)) {
  fs.mkdirSync(RESULT_PATH, { recursive: true });
}

// 처리된 파일 추적
const PROCESSED_FILE = path.join(AI_BRIDGE, '.processed_worker');

function getProcessedFiles() {
  try {
    if (fs.existsSync(PROCESSED_FILE)) {
      const data = fs.readFileSync(PROCESSED_FILE, 'utf8');
      return new Set(data.split('\n').filter(Boolean));
    }
  } catch (e) {}
  return new Set();
}

function saveProcessedFile(filename) {
  fs.appendFileSync(PROCESSED_FILE, filename + '\n');
}

// 미처리 스몰스텝 찾기 (가장 최신 파일)
function findPendingSmallstep() {
  const processed = getProcessedFiles();
  const files = fs.readdirSync(SMALLSTEP_PATH)
    .filter(f => f.startsWith('SMALL_') && f.endsWith('.md'))
    .sort((a, b) => {
      // 숫자 추출해서 내림차순 (최신 먼저)
      const numA = parseInt(a.match(/SMALL_(\d+)/)?.[1] || '0');
      const numB = parseInt(b.match(/SMALL_(\d+)/)?.[1] || '0');
      return numB - numA;
    });
  
  for (const file of files) {
    if (!processed.has(file)) {
      return file;
    }
  }
  return null;
}

// 스몰스텝 실행
function executeSmallstep(filename) {
  return new Promise((resolve, reject) => {
    const filepath = path.join(SMALLSTEP_PATH, filename);
    
    console.log('\n' + '='.repeat(60));
    console.log(`[Worker] 스몰스텝 실행: ${filename}`);
    console.log('[Worker] Sonnet 실행 중...');
    console.log('='.repeat(60) + '\n');
    
    // 지시서 내용 읽기
    const taskContent = fs.readFileSync(filepath, 'utf8');
    
    // 결과 파일명 생성
    const match = filename.match(/SMALL_(\d+)_(\d+)/);
    const resultFilename = match 
      ? `small_${match[1]}_${match[2]}_result.md`
      : `${filename.replace('.md', '_result.md')}`;
    const resultPath = path.join(RESULT_PATH, resultFilename);
    
    // 임시 프롬프트 파일 생성
    const promptFile = path.join(AI_BRIDGE, '.temp_prompt.txt');
    const prompt = `아래 지시를 수행하세요. 설명하지 말고 바로 작업하세요.

지시 내용:
${taskContent}

작업 완료 후 결과를 ${resultPath} 파일에 저장하세요.`;

    fs.writeFileSync(promptFile, prompt);

    // 실행 (OS별 claude 경로)
    const claudePath = os.platform() === 'darwin' ? '/opt/homebrew/bin/claude' : 'claude';
    const cmd = os.platform() === 'win32'
      ? `type "${promptFile}" | ${claudePath} -p --model claude-sonnet-4-20250514 --dangerously-skip-permissions`
      : `cat "${promptFile}" | ${claudePath} -p --model claude-sonnet-4-20250514 --dangerously-skip-permissions`;

    exec(cmd, { cwd: PROJECT_ROOT, maxBuffer: 10 * 1024 * 1024 }, (error, stdout, stderr) => {
      // 임시 파일 삭제
      try { fs.unlinkSync(promptFile); } catch (e) {}
      
      if (error) {
        console.error(`[Worker] 실행 실패: ${error.message}`);
        reject(error);
        return;
      }
      
      console.log(stdout);
      if (stderr) console.error(stderr);
      
      console.log(`\n[Worker] 스몰스텝 완료 ✅`);
      saveProcessedFile(filename);
      resolve();
    });
  });
}

// 메인
async function main() {
  console.log('='.repeat(60));
  console.log('  후임 Worker (일회성 실행)');
  console.log('='.repeat(60));
  
  // 미처리 스몰스텝 찾기
  const pending = findPendingSmallstep();
  
  if (!pending) {
    console.log('[Worker] 처리할 스몰스텝 없음. 종료.');
    process.exit(0);
  }
  
  try {
    await executeSmallstep(pending);
    console.log('[Worker] 작업 완료. 종료.');
    process.exit(0);
  } catch (e) {
    console.error('[Worker] 작업 실패. 종료.');
    process.exit(1);
  }
}

main();
