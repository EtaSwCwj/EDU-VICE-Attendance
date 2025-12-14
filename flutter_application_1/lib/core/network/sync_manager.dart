// lib/core/network/sync_manager.dart
import 'dart:async';
import 'package:logger/logger.dart';
import 'network_info.dart';

/// 동기화 작업 타입
enum SyncOperation { create, update, delete }

/// 동기화 작업 아이템
class SyncTask {
  final String id;
  final SyncOperation operation;
  final String entityType;
  final Map<String, dynamic> data;
  final DateTime timestamp;
  int retryCount;

  SyncTask({
    required this.id,
    required this.operation,
    required this.entityType,
    required this.data,
    DateTime? timestamp,
    this.retryCount = 0,
  }) : timestamp = timestamp ?? DateTime.now();
}

/// 동기화 매니저 - 로컬과 원격 데이터 소스 간의 동기화를 관리
class SyncManager {
  final NetworkInfo _networkInfo;
  final Logger _logger = Logger();

  final _syncQueue = <SyncTask>[];
  final _syncController = StreamController<SyncTask>.broadcast();
  Timer? _syncTimer;
  bool _isSyncing = false;

  static const int maxRetries = 3;
  static const Duration syncInterval = Duration(seconds: 30);

  SyncManager(this._networkInfo) {
    _initSyncListener();
  }

  /// 동기화 리스너 초기화
  void _initSyncListener() {
    // 네트워크 연결 상태 변경 감지
    _networkInfo.onConnectivityChanged.listen((isConnected) {
      if (isConnected && _syncQueue.isNotEmpty) {
        _logger.i('네트워크 연결됨 - 동기화 시작');
        syncAll();
      }
    });

    // 주기적 동기화
    _syncTimer = Timer.periodic(syncInterval, (_) {
      if (_syncQueue.isNotEmpty) {
        syncAll();
      }
    });
  }

  /// 동기화 작업 예약
  Future<void> scheduleSync(SyncTask task) async {
    _syncQueue.add(task);
    _logger.d('동기화 작업 예약: ${task.entityType} - ${task.operation}');

    // 즉시 동기화 시도 (네트워크가 연결되어 있다면)
    final isConnected = await _networkInfo.isConnected;
    if (isConnected) {
      syncAll();
    }
  }

  /// 모든 대기 중인 작업 동기화
  Future<void> syncAll() async {
    if (_isSyncing || _syncQueue.isEmpty) return;

    _isSyncing = true;
    final isConnected = await _networkInfo.isConnected;

    if (!isConnected) {
      _logger.w('네트워크 연결 없음 - 동기화 지연');
      _isSyncing = false;
      return;
    }

    _logger.i('동기화 시작: ${_syncQueue.length}개 작업');

    final tasksToSync = List<SyncTask>.from(_syncQueue);
    final failedTasks = <SyncTask>[];

    for (final task in tasksToSync) {
      try {
        // 실제 동기화 로직은 각 repository에서 구현
        // 여기서는 이벤트만 발행
        _syncController.add(task);

        // 성공 시 큐에서 제거
        _syncQueue.remove(task);
        _logger.d('동기화 성공: ${task.entityType} ${task.id}');
      } catch (e) {
        _logger.e('동기화 실패: ${task.entityType} ${task.id}', error: e);

        task.retryCount++;
        if (task.retryCount >= maxRetries) {
          _logger.e('최대 재시도 횟수 초과 - 작업 제거: ${task.id}');
          _syncQueue.remove(task);
        } else {
          failedTasks.add(task);
        }
      }
    }

    if (failedTasks.isNotEmpty) {
      _logger.w('${failedTasks.length}개 작업 재시도 예정');
    }

    _isSyncing = false;
  }

  /// 특정 엔티티 타입의 동기화 작업만 실행
  Future<void> syncByType(String entityType) async {
    final tasks = _syncQueue.where((t) => t.entityType == entityType).toList();

    for (final task in tasks) {
      _syncController.add(task);
      _syncQueue.remove(task);
    }
  }

  /// 동기화 이벤트 스트림
  Stream<SyncTask> get onSync => _syncController.stream;

  /// 대기 중인 작업 개수
  int get pendingCount => _syncQueue.length;

  /// 특정 엔티티의 대기 중인 작업 개수
  int getPendingCount(String entityType) {
    return _syncQueue.where((t) => t.entityType == entityType).length;
  }

  /// 리소스 정리
  void dispose() {
    _syncTimer?.cancel();
    _syncController.close();
  }
}
