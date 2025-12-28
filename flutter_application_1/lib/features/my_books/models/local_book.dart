import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';
import 'book_volume.dart';
import 'page_status.dart';

/// 촬영 기록 모델
class CaptureRecord {
  final List<int> pages;
  final String volumeName;
  final DateTime timestamp;
  final String? imagePath;

  CaptureRecord({
    required this.pages,
    required this.volumeName,
    required this.timestamp,
    this.imagePath,
  });

  Map<String, dynamic> toJson() => {
    'pages': pages,
    'volumeName': volumeName,
    'timestamp': timestamp.toIso8601String(),
    'imagePath': imagePath,
  };

  factory CaptureRecord.fromJson(Map<String, dynamic> json) => CaptureRecord(
    pages: (json['pages'] as List<dynamic>).map((e) => e as int).toList(),
    volumeName: json['volumeName'] as String,
    timestamp: DateTime.parse(json['timestamp'] as String),
    imagePath: json['imagePath'] as String?,
  );

  CaptureRecord copyWith({
    List<int>? pages,
    String? volumeName,
    DateTime? timestamp,
    String? imagePath,
  }) {
    return CaptureRecord(
      pages: pages ?? this.pages,
      volumeName: volumeName ?? this.volumeName,
      timestamp: timestamp ?? this.timestamp,
      imagePath: imagePath ?? this.imagePath,
    );
  }
}

class LocalBook extends Equatable {
  final String id;
  final String title;
  final String publisher;
  final String subject;
  final List<BookVolume> volumes;
  final String? coverImagePath;
  final List<int> registeredPages; // 정답지 등록된 페이지들 (파란색)
  final List<CaptureRecord> captureRecords; // 문제 촬영 기록
  final DateTime createdAt;
  final DateTime updatedAt;

  LocalBook({
    String? id,
    required this.title,
    required this.publisher,
    required this.subject,
    List<BookVolume>? volumes,
    this.coverImagePath,
    List<int>? registeredPages,
    List<CaptureRecord>? captureRecords,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? const Uuid().v4(),
        volumes = volumes != null && volumes.isNotEmpty
            ? volumes
            : [BookVolume(index: 0, name: '본책')],
        registeredPages = registeredPages ?? [],
        captureRecords = captureRecords ?? [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'publisher': publisher,
      'subject': subject,
      'volumes': volumes.map((v) => v.toJson()).toList(),
      'coverImagePath': coverImagePath,
      'registeredPages': registeredPages,
      'captureRecords': captureRecords.map((r) => r.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory LocalBook.fromJson(Map<String, dynamic> json) {
    final volumesList = (json['volumes'] as List<dynamic>?)
        ?.map((v) => BookVolume.fromJson(v as Map<String, dynamic>))
        .toList();

    final captureList = (json['captureRecords'] as List<dynamic>?)
        ?.map((r) => CaptureRecord.fromJson(r as Map<String, dynamic>))
        .toList();

    final title = json['title'] as String;
    safePrint('[LocalBook] $title volumes 로드: ${volumesList?.length ?? 0}개, 촬영기록: ${captureList?.length ?? 0}건');

    return LocalBook(
      id: json['id'] as String,
      title: title,
      publisher: json['publisher'] as String,
      subject: json['subject'] as String,
      volumes: volumesList,
      coverImagePath: json['coverImagePath'] as String?,
      registeredPages: (json['registeredPages'] as List<dynamic>?)
              ?.map((e) => e as int)
              .toList() ??
          [],
      captureRecords: captureList ?? [],
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  LocalBook copyWith({
    String? id,
    String? title,
    String? publisher,
    String? subject,
    List<BookVolume>? volumes,
    String? coverImagePath,
    List<int>? registeredPages,
    List<CaptureRecord>? captureRecords,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LocalBook(
      id: id ?? this.id,
      title: title ?? this.title,
      publisher: publisher ?? this.publisher,
      subject: subject ?? this.subject,
      volumes: volumes ?? this.volumes,
      coverImagePath: coverImagePath ?? this.coverImagePath,
      registeredPages: registeredPages ?? this.registeredPages,
      captureRecords: captureRecords ?? this.captureRecords,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // ========== 페이지 통계 ==========

  /// 전체 페이지 수 (모든 Volume 합산)
  int get totalPages {
    return volumes.fold(0, (sum, vol) => sum + vol.effectiveTotalPages);
  }

  /// 촬영된 페이지 Set (Volume별로 구분)
  Map<String, Set<int>> get capturedPagesByVolume {
    final result = <String, Set<int>>{};
    for (final record in captureRecords) {
      result.putIfAbsent(record.volumeName, () => <int>{});
      result[record.volumeName]!.addAll(record.pages);
    }
    return result;
  }

  /// 총 촬영된 페이지 수 (중복 제외)
  int get totalCapturedPages {
    int total = 0;
    for (final pages in capturedPagesByVolume.values) {
      total += pages.length;
    }
    return total;
  }

  /// 정답 등록된 페이지 수
  int get totalAnswerPages => registeredPages.length;

  // ========== 페이지 상태 계산 ==========

  /// 특정 페이지의 상태 조회
  PageStatus getPageStatus(String volumeName, int page) {
    final isCaptured = capturedPagesByVolume[volumeName]?.contains(page) ?? false;
    final hasAnswer = registeredPages.contains(page);

    if (isCaptured && hasAnswer) {
      return PageStatus.complete;
    } else if (isCaptured) {
      return PageStatus.problemRegistered;
    } else if (hasAnswer) {
      return PageStatus.answerOnly;
    } else {
      return PageStatus.notRegistered;
    }
  }

  /// Volume의 모든 페이지 상태 맵
  Map<int, PageStatus> getVolumePageStatuses(BookVolume volume) {
    final result = <int, PageStatus>{};
    final pageCount = volume.effectiveTotalPages;
    
    if (pageCount == 0) return result;

    final start = volume.effectiveStartPage;
    for (int page = start; page < start + pageCount; page++) {
      result[page] = getPageStatus(volume.name, page);
    }
    return result;
  }

  // ========== 진행률 계산 ==========

  /// DB 완성도 (0.0 ~ 1.0)
  double get dbCompleteness {
    if (totalPages == 0) return 0.0;

    int score = 0;
    final maxScore = totalPages * 2;

    for (final volume in volumes) {
      final pageCount = volume.effectiveTotalPages;
      final start = volume.effectiveStartPage;
      for (int page = start; page < start + pageCount; page++) {
        final status = getPageStatus(volume.name, page);
        switch (status) {
          case PageStatus.complete:
            score += 2;
            break;
          case PageStatus.problemRegistered:
          case PageStatus.answerOnly:
            score += 1;
            break;
          default:
            break;
        }
      }
    }

    return score / maxScore;
  }

  /// 간단 진행률 (0.0 ~ 1.0)
  double get progress {
    if (totalPages == 0) return 0.0;

    int registeredCount = 0;
    for (final volume in volumes) {
      final pageCount = volume.effectiveTotalPages;
      final start = volume.effectiveStartPage;
      for (int page = start; page < start + pageCount; page++) {
        final status = getPageStatus(volume.name, page);
        if (status != PageStatus.notRegistered) {
          registeredCount++;
        }
      }
    }

    return registeredCount / totalPages;
  }

  /// 진행률 요약 문자열
  String get progressSummary {
    final captured = totalCapturedPages;
    final answers = totalAnswerPages;
    final total = totalPages;
    
    if (total == 0) {
      return '페이지 범위 미설정';
    }
    
    final percent = (progress * 100).toStringAsFixed(0);
    return '$percent% (촬영 $captured, 정답 $answers / $total페이지)';
  }

  @override
  List<Object?> get props => [
        id, title, publisher, subject, volumes,
        coverImagePath, registeredPages, captureRecords,
        createdAt, updatedAt,
      ];
}
