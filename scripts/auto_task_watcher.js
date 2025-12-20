/**
 * 선후임 자동화 스크립트
 * 
 * ai_bridge 폴더를 감시하여 새 TASK_*.md 파일이 생성되면
 * Claude Code CLI를 자동으로 호출합니다.
 * 
 * 사용법:
 *   npm run watch:task
 * 
 * 설치:
 *   npm install chokidar
 */

const chokidar = require('chokidar');
const { spawn } = require('child_process');
const path = require('path');
const fs = require('fs');

// 설정
const AI_BRIDGE_PATH = path.join(__dirname, '..', 'ai_bridge');
const WATCH_PATTERN = 'TASK_*.md';
const IGNORE_PATTERNS = ['*_result.md', 'HANDOVER_*.md', 'PROJECT_*.md'];

// 이미 처리한 파일 추적 (중복 실행 방지)
const processedFiles = new Set();

// 처리된 파일 목록 저장 경로
const PROCESSED_FILE = path.join(AI_BRIDGE_PATH, '.processed_tasks');

// 시작 시 기존 처리 목록 로드
function loadProcessedFiles() {
  try {
    if (fs.existsSync(PROCESSED_FILE)) {
      const data = fs.readFileSync(PROCESSED_FILE, 'utf8');
      data.split('\n').filter(Boolean).forEach(f => processedFiles.add(f));
      console.log(`[Watcher] 기존 처리 목록 로드: ${processedFiles.size}개`);
    }
  } catch (e) {
    console.log('[Watcher] 처리 목록 파일 없음 (새로 시작)');
  }
}

// 처리된 파일 저장
function saveProcessedFile(filename) {
  processedFiles.add(filename);
  fs.appendFileSync(PROCESSED_FILE, filename + '\n');
}

// 파일명에서 TASK 번호 추출
function extractTaskName(filepath) {
  const filename = path.basename(filepath);
  const match = filename.match(/^(TASK_\d+[A-Za-z_]*)/);
  return match ? match[1] : null;
}

// 무시할 파일인지 확인
function shouldIgnore(filepath) {
  const filename = path.basename(filepath);
  
  // result 파일 무시
  if (filename.includes('_result')) return true;
  
  // HANDOVER, PROJECT 등 무시
  for (const pattern of IGNORE_PATTERNS) {
    const regex = new RegExp('^' + pattern.replace('*', '.*'));
    if (regex.test(filename)) return true;
  }
  
  return false;
}

// Claude Code CLI 호출
function runClaudeCode(filepath) {
  const filename = path.basename(filepath);
  const taskName = extractTaskName(filepath);
  
  if (!taskName) {
    console.log(`[Watcher] 태스크명 추출 실패: ${filename}`);
    return;
  }
  
  // 이미 처리한 파일인지 확인
  if (processedFiles.has(filename)) {
    console.log(`[Watcher] 이미 처리됨 (스킵): ${filename}`);
    return;
  }
  
  console.log('\n' + '='.repeat(60));
  console.log(`[Watcher] 새 지시서 감지: ${filename}`);
  console.log(`[Watcher] Claude Code 호출 중...`);
  console.log('='.repeat(60) + '\n');
  
  const command = `${taskName} 실행해. ${filepath} 읽고 작업해. 결과는 ai_bridge/${taskName.toLowerCase()}_result.md로 저장해.`;
  
  // Claude Code CLI 호출
  const claude = spawn('claude', [command], {
    stdio: 'inherit',
    shell: true,
    cwd: path.join(__dirname, '..')
  });
  
  claude.on('error', (err) => {
    console.error(`[Watcher] Claude Code 실행 실패: ${err.message}`);
  });
  
  claude.on('close', (code) => {
    if (code === 0) {
      console.log(`\n[Watcher] ${taskName} 완료`);
      saveProcessedFile(filename);
    } else {
      console.log(`\n[Watcher] ${taskName} 종료 (코드: ${code})`);
    }
  });
}

// 메인
function main() {
  console.log('='.repeat(60));
  console.log('  선후임 자동화 시스템');
  console.log('  ai_bridge 폴더 감시 중...');
  console.log('='.repeat(60));
  console.log(`\n감시 경로: ${AI_BRIDGE_PATH}`);
  console.log(`감시 패턴: ${WATCH_PATTERN}`);
  console.log(`무시 패턴: ${IGNORE_PATTERNS.join(', ')}`);
  console.log('\n새 TASK_*.md 파일이 생성되면 자동으로 Claude Code가 실행됩니다.');
  console.log('종료하려면 Ctrl+C를 누르세요.\n');
  
  // 기존 처리 목록 로드
  loadProcessedFiles();
  
  // 파일 감시 시작
  const watcher = chokidar.watch(path.join(AI_BRIDGE_PATH, WATCH_PATTERN), {
    persistent: true,
    ignoreInitial: true,  // 시작 시 기존 파일 무시
    awaitWriteFinish: {   // 파일 쓰기 완료 대기
      stabilityThreshold: 1000,
      pollInterval: 100
    }
  });
  
  watcher
    .on('add', (filepath) => {
      if (!shouldIgnore(filepath)) {
        runClaudeCode(filepath);
      }
    })
    .on('error', (error) => {
      console.error(`[Watcher] 에러: ${error}`);
    });
  
  // Ctrl+C 처리
  process.on('SIGINT', () => {
    console.log('\n[Watcher] 종료합니다.');
    watcher.close();
    process.exit(0);
  });
}

main();
