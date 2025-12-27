import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';
import 'book_volume.dart';

class LocalBook extends Equatable {
  final String id;
  final String title;
  final String publisher;
  final String subject; // ENGLISH, MATH, KOREAN, SCIENCE
  final List<BookVolume> volumes;
  final String? coverImagePath; // 로컬 이미지 경로
  final List<int> registeredPages; // 정답지 등록된 페이지들
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
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? const Uuid().v4(),
        volumes = volumes != null && volumes.isNotEmpty
            ? volumes
            : [BookVolume(index: 0, name: '본책')],
        registeredPages = registeredPages ?? [],
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
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory LocalBook.fromJson(Map<String, dynamic> json) {
    final volumesList = (json['volumes'] as List<dynamic>?)
        ?.map((v) => BookVolume.fromJson(v as Map<String, dynamic>))
        .toList();

    final title = json['title'] as String;
    safePrint('[LocalBook] $title volumes 로드: ${volumesList?.length ?? 0}개');

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
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  int get totalPages {
    return volumes.fold(0, (sum, vol) => sum + (vol.totalPages ?? 0));
  }

  double get progress {
    if (totalPages == 0) return 0.0;
    return registeredPages.length / totalPages;
  }

  @override
  List<Object?> get props => [
        id,
        title,
        publisher,
        subject,
        volumes,
        coverImagePath,
        registeredPages,
        createdAt,
        updatedAt,
      ];
}