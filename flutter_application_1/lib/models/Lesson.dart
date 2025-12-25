/*
* Copyright 2021 Amazon.com, Inc. or its affiliates. All Rights Reserved.
*
* Licensed under the Apache License, Version 2.0 (the "License").
* You may not use this file except in compliance with the License.
* A copy of the License is located at
*
*  http://aws.amazon.com/apache2.0
*
* or in the "license" file accompanying this file. This file is distributed
* on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
* express or implied. See the License for the specific language governing
* permissions and limitations under the License.
*/

// NOTE: This file is generated and may not follow lint rules defined in your app
// Generated files can be excluded from analysis in analysis_options.yaml
// For more info, see: https://dart.dev/guides/language/analysis-options#excluding-code-from-analysis

// ignore_for_file: public_member_api_docs, annotate_overrides, dead_code, dead_codepublic_member_api_docs, depend_on_referenced_packages, file_names, library_private_types_in_public_api, no_leading_underscores_for_library_prefixes, no_leading_underscores_for_local_identifiers, non_constant_identifier_names, null_check_on_nullable_type_parameter, override_on_non_overriding_member, prefer_adjacent_string_concatenation, prefer_const_constructors, prefer_if_null_operators, prefer_interpolation_to_compose_strings, slash_for_doc_comments, sort_child_properties_last, unnecessary_const, unnecessary_constructor_name, unnecessary_late, unnecessary_new, unnecessary_null_aware_assignments, unnecessary_nullable_for_final_variable_declarations, unnecessary_string_interpolations, use_build_context_synchronously

import 'ModelProvider.dart';
import 'package:amplify_core/amplify_core.dart' as amplify_core;
import 'package:collection/collection.dart';


/** This is an auto generated class representing the Lesson type in your schema. */
class Lesson extends amplify_core.Model {
  static const classType = const _LessonModelType();
  final String id;
  final String? _title;
  final Subject? _subject;
  final String? _teacherUsername;
  final List<String>? _studentUsernames;
  final String? _bookId;
  final String? _chapterId;
  final amplify_core.TemporalDate? _scheduledDate;
  final amplify_core.TemporalTime? _startTime;
  final amplify_core.TemporalTime? _endTime;
  final int? _duration;
  final LessonStatus? _status;
  final int? _score;
  final amplify_core.TemporalDateTime? _createdAt;
  final amplify_core.TemporalDateTime? _updatedAt;

  @override
  getInstanceType() => classType;
  
  @Deprecated('[getId] is being deprecated in favor of custom primary key feature. Use getter [modelIdentifier] to get model identifier.')
  @override
  String getId() => id;
  
  LessonModelIdentifier get modelIdentifier {
      return LessonModelIdentifier(
        id: id
      );
  }
  
  String get title {
    try {
      return _title!;
    } catch(e) {
      throw amplify_core.AmplifyCodeGenModelException(
          amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastExceptionMessage,
          recoverySuggestion:
            amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastRecoverySuggestion,
          underlyingException: e.toString()
          );
    }
  }
  
  Subject get subject {
    try {
      return _subject!;
    } catch(e) {
      throw amplify_core.AmplifyCodeGenModelException(
          amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastExceptionMessage,
          recoverySuggestion:
            amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastRecoverySuggestion,
          underlyingException: e.toString()
          );
    }
  }
  
  String get teacherUsername {
    try {
      return _teacherUsername!;
    } catch(e) {
      throw amplify_core.AmplifyCodeGenModelException(
          amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastExceptionMessage,
          recoverySuggestion:
            amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastRecoverySuggestion,
          underlyingException: e.toString()
          );
    }
  }
  
  List<String> get studentUsernames {
    try {
      return _studentUsernames!;
    } catch(e) {
      throw amplify_core.AmplifyCodeGenModelException(
          amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastExceptionMessage,
          recoverySuggestion:
            amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastRecoverySuggestion,
          underlyingException: e.toString()
          );
    }
  }
  
  String? get bookId {
    return _bookId;
  }
  
  String? get chapterId {
    return _chapterId;
  }
  
  amplify_core.TemporalDate get scheduledDate {
    try {
      return _scheduledDate!;
    } catch(e) {
      throw amplify_core.AmplifyCodeGenModelException(
          amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastExceptionMessage,
          recoverySuggestion:
            amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastRecoverySuggestion,
          underlyingException: e.toString()
          );
    }
  }
  
  amplify_core.TemporalTime get startTime {
    try {
      return _startTime!;
    } catch(e) {
      throw amplify_core.AmplifyCodeGenModelException(
          amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastExceptionMessage,
          recoverySuggestion:
            amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastRecoverySuggestion,
          underlyingException: e.toString()
          );
    }
  }
  
  amplify_core.TemporalTime? get endTime {
    return _endTime;
  }
  
  int? get duration {
    return _duration;
  }
  
  LessonStatus get status {
    try {
      return _status!;
    } catch(e) {
      throw amplify_core.AmplifyCodeGenModelException(
          amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastExceptionMessage,
          recoverySuggestion:
            amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastRecoverySuggestion,
          underlyingException: e.toString()
          );
    }
  }
  
  int? get score {
    return _score;
  }
  
  amplify_core.TemporalDateTime? get createdAt {
    return _createdAt;
  }
  
  amplify_core.TemporalDateTime? get updatedAt {
    return _updatedAt;
  }
  
  const Lesson._internal({required this.id, required title, required subject, required teacherUsername, required studentUsernames, bookId, chapterId, required scheduledDate, required startTime, endTime, duration, required status, score, createdAt, updatedAt}): _title = title, _subject = subject, _teacherUsername = teacherUsername, _studentUsernames = studentUsernames, _bookId = bookId, _chapterId = chapterId, _scheduledDate = scheduledDate, _startTime = startTime, _endTime = endTime, _duration = duration, _status = status, _score = score, _createdAt = createdAt, _updatedAt = updatedAt;
  
  factory Lesson({String? id, required String title, required Subject subject, required String teacherUsername, required List<String> studentUsernames, String? bookId, String? chapterId, required amplify_core.TemporalDate scheduledDate, required amplify_core.TemporalTime startTime, amplify_core.TemporalTime? endTime, int? duration, required LessonStatus status, int? score, amplify_core.TemporalDateTime? createdAt, amplify_core.TemporalDateTime? updatedAt}) {
    return Lesson._internal(
      id: id == null ? amplify_core.UUID.getUUID() : id,
      title: title,
      subject: subject,
      teacherUsername: teacherUsername,
      studentUsernames: studentUsernames != null ? List<String>.unmodifiable(studentUsernames) : studentUsernames,
      bookId: bookId,
      chapterId: chapterId,
      scheduledDate: scheduledDate,
      startTime: startTime,
      endTime: endTime,
      duration: duration,
      status: status,
      score: score,
      createdAt: createdAt,
      updatedAt: updatedAt);
  }
  
  bool equals(Object other) {
    return this == other;
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is Lesson &&
      id == other.id &&
      _title == other._title &&
      _subject == other._subject &&
      _teacherUsername == other._teacherUsername &&
      DeepCollectionEquality().equals(_studentUsernames, other._studentUsernames) &&
      _bookId == other._bookId &&
      _chapterId == other._chapterId &&
      _scheduledDate == other._scheduledDate &&
      _startTime == other._startTime &&
      _endTime == other._endTime &&
      _duration == other._duration &&
      _status == other._status &&
      _score == other._score &&
      _createdAt == other._createdAt &&
      _updatedAt == other._updatedAt;
  }
  
  @override
  int get hashCode => toString().hashCode;
  
  @override
  String toString() {
    var buffer = new StringBuffer();
    
    buffer.write("Lesson {");
    buffer.write("id=" + "$id" + ", ");
    buffer.write("title=" + "$_title" + ", ");
    buffer.write("subject=" + (_subject != null ? amplify_core.enumToString(_subject)! : "null") + ", ");
    buffer.write("teacherUsername=" + "$_teacherUsername" + ", ");
    buffer.write("studentUsernames=" + (_studentUsernames != null ? _studentUsernames!.toString() : "null") + ", ");
    buffer.write("bookId=" + "$_bookId" + ", ");
    buffer.write("chapterId=" + "$_chapterId" + ", ");
    buffer.write("scheduledDate=" + (_scheduledDate != null ? _scheduledDate!.format() : "null") + ", ");
    buffer.write("startTime=" + (_startTime != null ? _startTime!.format() : "null") + ", ");
    buffer.write("endTime=" + (_endTime != null ? _endTime!.format() : "null") + ", ");
    buffer.write("duration=" + (_duration != null ? _duration!.toString() : "null") + ", ");
    buffer.write("status=" + (_status != null ? amplify_core.enumToString(_status)! : "null") + ", ");
    buffer.write("score=" + (_score != null ? _score!.toString() : "null") + ", ");
    buffer.write("createdAt=" + (_createdAt != null ? _createdAt!.format() : "null") + ", ");
    buffer.write("updatedAt=" + (_updatedAt != null ? _updatedAt!.format() : "null"));
    buffer.write("}");
    
    return buffer.toString();
  }
  
  Lesson copyWith({String? title, Subject? subject, String? teacherUsername, List<String>? studentUsernames, String? bookId, String? chapterId, amplify_core.TemporalDate? scheduledDate, amplify_core.TemporalTime? startTime, amplify_core.TemporalTime? endTime, int? duration, LessonStatus? status, int? score, amplify_core.TemporalDateTime? createdAt, amplify_core.TemporalDateTime? updatedAt}) {
    return Lesson._internal(
      id: id,
      title: title ?? this.title,
      subject: subject ?? this.subject,
      teacherUsername: teacherUsername ?? this.teacherUsername,
      studentUsernames: studentUsernames ?? this.studentUsernames,
      bookId: bookId ?? this.bookId,
      chapterId: chapterId ?? this.chapterId,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      duration: duration ?? this.duration,
      status: status ?? this.status,
      score: score ?? this.score,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt);
  }
  
  Lesson copyWithModelFieldValues({
    ModelFieldValue<String>? title,
    ModelFieldValue<Subject>? subject,
    ModelFieldValue<String>? teacherUsername,
    ModelFieldValue<List<String>?>? studentUsernames,
    ModelFieldValue<String?>? bookId,
    ModelFieldValue<String?>? chapterId,
    ModelFieldValue<amplify_core.TemporalDate>? scheduledDate,
    ModelFieldValue<amplify_core.TemporalTime>? startTime,
    ModelFieldValue<amplify_core.TemporalTime?>? endTime,
    ModelFieldValue<int?>? duration,
    ModelFieldValue<LessonStatus>? status,
    ModelFieldValue<int?>? score,
    ModelFieldValue<amplify_core.TemporalDateTime?>? createdAt,
    ModelFieldValue<amplify_core.TemporalDateTime?>? updatedAt
  }) {
    return Lesson._internal(
      id: id,
      title: title == null ? this.title : title.value,
      subject: subject == null ? this.subject : subject.value,
      teacherUsername: teacherUsername == null ? this.teacherUsername : teacherUsername.value,
      studentUsernames: studentUsernames == null ? this.studentUsernames : studentUsernames.value,
      bookId: bookId == null ? this.bookId : bookId.value,
      chapterId: chapterId == null ? this.chapterId : chapterId.value,
      scheduledDate: scheduledDate == null ? this.scheduledDate : scheduledDate.value,
      startTime: startTime == null ? this.startTime : startTime.value,
      endTime: endTime == null ? this.endTime : endTime.value,
      duration: duration == null ? this.duration : duration.value,
      status: status == null ? this.status : status.value,
      score: score == null ? this.score : score.value,
      createdAt: createdAt == null ? this.createdAt : createdAt.value,
      updatedAt: updatedAt == null ? this.updatedAt : updatedAt.value
    );
  }
  
  Lesson.fromJson(Map<String, dynamic> json)  
    : id = json['id'],
      _title = json['title'],
      _subject = amplify_core.enumFromString<Subject>(json['subject'], Subject.values),
      _teacherUsername = json['teacherUsername'],
      _studentUsernames = json['studentUsernames']?.cast<String>(),
      _bookId = json['bookId'],
      _chapterId = json['chapterId'],
      _scheduledDate = json['scheduledDate'] != null ? amplify_core.TemporalDate.fromString(json['scheduledDate']) : null,
      _startTime = json['startTime'] != null ? amplify_core.TemporalTime.fromString(json['startTime']) : null,
      _endTime = json['endTime'] != null ? amplify_core.TemporalTime.fromString(json['endTime']) : null,
      _duration = (json['duration'] as num?)?.toInt(),
      _status = amplify_core.enumFromString<LessonStatus>(json['status'], LessonStatus.values),
      _score = (json['score'] as num?)?.toInt(),
      _createdAt = json['createdAt'] != null ? amplify_core.TemporalDateTime.fromString(json['createdAt']) : null,
      _updatedAt = json['updatedAt'] != null ? amplify_core.TemporalDateTime.fromString(json['updatedAt']) : null;
  
  Map<String, dynamic> toJson() => {
    'id': id, 'title': _title, 'subject': amplify_core.enumToString(_subject), 'teacherUsername': _teacherUsername, 'studentUsernames': _studentUsernames, 'bookId': _bookId, 'chapterId': _chapterId, 'scheduledDate': _scheduledDate?.format(), 'startTime': _startTime?.format(), 'endTime': _endTime?.format(), 'duration': _duration, 'status': amplify_core.enumToString(_status), 'score': _score, 'createdAt': _createdAt?.format(), 'updatedAt': _updatedAt?.format()
  };
  
  Map<String, Object?> toMap() => {
    'id': id,
    'title': _title,
    'subject': _subject,
    'teacherUsername': _teacherUsername,
    'studentUsernames': _studentUsernames,
    'bookId': _bookId,
    'chapterId': _chapterId,
    'scheduledDate': _scheduledDate,
    'startTime': _startTime,
    'endTime': _endTime,
    'duration': _duration,
    'status': _status,
    'score': _score,
    'createdAt': _createdAt,
    'updatedAt': _updatedAt
  };

  static final amplify_core.QueryModelIdentifier<LessonModelIdentifier> MODEL_IDENTIFIER = amplify_core.QueryModelIdentifier<LessonModelIdentifier>();
  static final ID = amplify_core.QueryField(fieldName: "id");
  static final TITLE = amplify_core.QueryField(fieldName: "title");
  static final SUBJECT = amplify_core.QueryField(fieldName: "subject");
  static final TEACHERUSERNAME = amplify_core.QueryField(fieldName: "teacherUsername");
  static final STUDENTUSERNAMES = amplify_core.QueryField(fieldName: "studentUsernames");
  static final BOOKID = amplify_core.QueryField(fieldName: "bookId");
  static final CHAPTERID = amplify_core.QueryField(fieldName: "chapterId");
  static final SCHEDULEDDATE = amplify_core.QueryField(fieldName: "scheduledDate");
  static final STARTTIME = amplify_core.QueryField(fieldName: "startTime");
  static final ENDTIME = amplify_core.QueryField(fieldName: "endTime");
  static final DURATION = amplify_core.QueryField(fieldName: "duration");
  static final STATUS = amplify_core.QueryField(fieldName: "status");
  static final SCORE = amplify_core.QueryField(fieldName: "score");
  static final CREATEDAT = amplify_core.QueryField(fieldName: "createdAt");
  static final UPDATEDAT = amplify_core.QueryField(fieldName: "updatedAt");
  static var schema = amplify_core.Model.defineSchema(define: (amplify_core.ModelSchemaDefinition modelSchemaDefinition) {
    modelSchemaDefinition.name = "Lesson";
    modelSchemaDefinition.pluralName = "Lessons";
    
    modelSchemaDefinition.authRules = [
      amplify_core.AuthRule(
        authStrategy: amplify_core.AuthStrategy.GROUPS,
        groupClaim: "cognito:groups",
        groups: [ "owners" ],
        provider: amplify_core.AuthRuleProvider.USERPOOLS,
        operations: const [
          amplify_core.ModelOperation.CREATE,
          amplify_core.ModelOperation.READ,
          amplify_core.ModelOperation.UPDATE,
          amplify_core.ModelOperation.DELETE
        ]),
      amplify_core.AuthRule(
        authStrategy: amplify_core.AuthStrategy.OWNER,
        ownerField: "teacherUsername",
        identityClaim: "cognito:username",
        provider: amplify_core.AuthRuleProvider.USERPOOLS,
        operations: const [
          amplify_core.ModelOperation.CREATE,
          amplify_core.ModelOperation.READ,
          amplify_core.ModelOperation.UPDATE,
          amplify_core.ModelOperation.DELETE
        ]),
      amplify_core.AuthRule(
        authStrategy: amplify_core.AuthStrategy.GROUPS,
        groupClaim: "cognito:groups",
        groups: [ "students" ],
        provider: amplify_core.AuthRuleProvider.USERPOOLS,
        operations: const [
          amplify_core.ModelOperation.READ
        ])
    ];
    
    modelSchemaDefinition.indexes = [
      amplify_core.ModelIndex(fields: const ["teacherUsername", "scheduledDate"], name: "byTeacher"),
      amplify_core.ModelIndex(fields: const ["bookId"], name: "byBook"),
      amplify_core.ModelIndex(fields: const ["scheduledDate", "startTime"], name: "byDate")
    ];
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.id());
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Lesson.TITLE,
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Lesson.SUBJECT,
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.enumeration)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Lesson.TEACHERUSERNAME,
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Lesson.STUDENTUSERNAMES,
      isRequired: true,
      isArray: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.collection, ofModelName: amplify_core.ModelFieldTypeEnum.string.name)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Lesson.BOOKID,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Lesson.CHAPTERID,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Lesson.SCHEDULEDDATE,
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.date)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Lesson.STARTTIME,
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.time)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Lesson.ENDTIME,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.time)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Lesson.DURATION,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.int)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Lesson.STATUS,
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.enumeration)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Lesson.SCORE,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.int)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Lesson.CREATEDAT,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.dateTime)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Lesson.UPDATEDAT,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.dateTime)
    ));
  });
}

class _LessonModelType extends amplify_core.ModelType<Lesson> {
  const _LessonModelType();
  
  @override
  Lesson fromJson(Map<String, dynamic> jsonData) {
    return Lesson.fromJson(jsonData);
  }
  
  @override
  String modelName() {
    return 'Lesson';
  }
}

/**
 * This is an auto generated class representing the model identifier
 * of [Lesson] in your schema.
 */
class LessonModelIdentifier implements amplify_core.ModelIdentifier<Lesson> {
  final String id;

  /** Create an instance of LessonModelIdentifier using [id] the primary key. */
  const LessonModelIdentifier({
    required this.id});
  
  @override
  Map<String, dynamic> serializeAsMap() => (<String, dynamic>{
    'id': id
  });
  
  @override
  List<Map<String, dynamic>> serializeAsList() => serializeAsMap()
    .entries
    .map((entry) => (<String, dynamic>{ entry.key: entry.value }))
    .toList();
  
  @override
  String serializeAsString() => serializeAsMap().values.join('#');
  
  @override
  String toString() => 'LessonModelIdentifier(id: $id)';
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    
    return other is LessonModelIdentifier &&
      id == other.id;
  }
  
  @override
  int get hashCode =>
    id.hashCode;
}