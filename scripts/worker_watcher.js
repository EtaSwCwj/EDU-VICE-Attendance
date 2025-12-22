/**
 * 2실린더 자동화 시스템 v5 - Worker
 * 
 * 역할:
 * - smallstep/ 에서 미처리 파일 찾기 → Claude(Sonnet) 실행 → result/ 저장 → 종료
 * 
 * AI: Sonnet (작업 수행, 저렴)
 * 
 * 크로스 플랫폼: Windows + Mac 지원
 * 
 * 사용법:
 *   npm run watch:worker (Manager가 호출)
 */

const { exec } = require('child_process');
const path = require('path');
const fs = require('fs');
const os = require('os');

// ============================================================
// 경로 설정
// ============================================================
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

// ============================================================
// 유틸리티 함수
// ============================================================

function getShellConfig() {
  if (os.platform() === 'win32') {
    return { shell: 'powershell.exe', catCmd: 'Get-Content', pipeArg: '-Raw |' };
  } else {
    return { shell: '/bin/bash', catCmd: 'cat', pipeArg: '|' };
  }
}

function getClaudePath() {
  return os.platform() === 'darwin' ? '/opt/homebrew/bin/claude' : 'claude';
}

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

// ============================================================
// 스몰스텝 처리
// ============================================================

// 미처리 스몰스텝 찾기 (가장 최신 파일)
function findPendingSmallstep() {
  const processed = getProcessedFiles();
  const files = fs.readdirSync(SMALLSTEP_PATH)
    .filter(f => f.startsWith('SMALL_') && f.endsWith('.md'))
    .sort((a, b) => {
      // 숫자 추출해서 내림차순 (최신 먼저)
      const numA = parseInt(a.match(/SMALL_(\d+)/)?.[1] || '0');
      const numB = parseInt(b.match(/SMALL_(\d+)/)?.[1] || '0');
      if (numA !== numB) return numB - numA;
      // 같은 빅스텝이면 스텝 번호로
      const stepA = parseInt(a.match(/SMALL_\d+_(\d+)/)?.[1] || '0');
      const stepB = parseInt(b.match(/SMALL_\d+_(\d+)/)?.[1] || '0');
      return stepB - stepA;
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
    const prompt = `프로젝트 경로: ${PROJECT_ROOT}

아래 지시를 수행하세요. 설명하지 말고 바로 작업하세요.

지시 내용:
${taskContent}

작업 규칙:
- 물어보지 말고 끝까지 진행
- 막히면 스스로 해결 시도
- 결과 파일 필수 생성

작업 완료 후 결과를 ${resultPath} 파일에 저장하세요.`;

    fs.writeFileSync(promptFile, prompt);

    // OS별 명령 구성
    const claudePath = getClaudePath();
    const shellConfig = getShellConfig();
    
    let cmd;
    if (os.platform() === 'win32') {
      cmd = `Get-Content "${promptFile}" -Raw | ${claudePath} -p --model claude-sonnet-4-20250514 --dangerously-skip-permissions`;
    } else {
      cmd = `cat "${promptFile}" | ${claudePath} -p --model claude-sonnet-4-20250514 --dangerously-skip-permissions`;
    }

    exec(cmd, { 
      cwd: PROJECT_ROOT, 
      shell: shellConfig.shell,
      maxBuffer: 50 * 1024 * 1024,
      timeout: 600000 // 10분
    }, (error, stdout, stderr) => {
      // 임시 파일 삭제
      try { fs.unlinkSync(promptFile); } catch (e) {}
      
      if (error) {
        console.error(`[Worker] 실행 실패: ${error.message}`);
        reject(error);
        return;
      }
      
      // 출력 (길면 자름)
      if (stdout) {
        const output = stdout.length > 1000 
          ? stdout.substring(0, 1000) + '\n... (truncated)'
          : stdout;
        console.log(output);
      }
      if (stderr) console.error(stderr);
      
      console.log(`\n[Worker] 스몰스텝 완료 ✅`);
      saveProcessedFile(filename);
      resolve();
    });
  });
}

// ============================================================
// 메인
// ============================================================

async function main() {
  console.log('='.repeat(60));
  console.log('  2실린더 자동화 시스템 v5 - Worker (Sonnet)');
  console.log('='.repeat(60));
  console.log(`OS: ${os.platform()}`);
  console.log(`Claude: ${getClaudePath()}`);
  console.log();
  
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
