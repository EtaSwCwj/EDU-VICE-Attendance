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


/** This is an auto generated class representing the StudentProblemRecord type in your schema. */
class StudentProblemRecord extends amplify_core.Model {
  static const classType = const _StudentProblemRecordModelType();
  final String id;
  final String? _studentUserId;
  final String? _problemId;
  final String? _textbookId;
  final String? _chapterId;
  final bool? _isCorrect;
  final String? _studentAnswer;
  final amplify_core.TemporalDateTime? _solvedAt;
  final int? _timeSpent;
  final int? _attempts;
  final amplify_core.TemporalDateTime? _createdAt;
  final amplify_core.TemporalDateTime? _updatedAt;

  @override
  getInstanceType() => classType;
  
  @Deprecated('[getId] is being deprecated in favor of custom primary key feature. Use getter [modelIdentifier] to get model identifier.')
  @override
  String getId() => id;
  
  StudentProblemRecordModelIdentifier get modelIdentifier {
      return StudentProblemRecordModelIdentifier(
        id: id
      );
  }
  
  String get studentUserId {
    try {
      return _studentUserId!;
    } catch(e) {
      throw amplify_core.AmplifyCodeGenModelException(
          amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastExceptionMessage,
          recoverySuggestion:
            amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastRecoverySuggestion,
          underlyingException: e.toString()
          );
    }
  }
  
  String get problemId {
    try {
      return _problemId!;
    } catch(e) {
      throw amplify_core.AmplifyCodeGenModelException(
          amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastExceptionMessage,
          recoverySuggestion:
            amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastRecoverySuggestion,
          underlyingException: e.toString()
          );
    }
  }
  
  String get textbookId {
    try {
      return _textbookId!;
    } catch(e) {
      throw amplify_core.AmplifyCodeGenModelException(
          amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastExceptionMessage,
          recoverySuggestion:
            amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastRecoverySuggestion,
          underlyingException: e.toString()
          );
    }
  }
  
  String get chapterId {
    try {
      return _chapterId!;
    } catch(e) {
      throw amplify_core.AmplifyCodeGenModelException(
          amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastExceptionMessage,
          recoverySuggestion:
            amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastRecoverySuggestion,
          underlyingException: e.toString()
          );
    }
  }
  
  bool get isCorrect {
    try {
      return _isCorrect!;
    } catch(e) {
      throw amplify_core.AmplifyCodeGenModelException(
          amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastExceptionMessage,
          recoverySuggestion:
            amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastRecoverySuggestion,
          underlyingException: e.toString()
          );
    }
  }
  
  String? get studentAnswer {
    return _studentAnswer;
  }
  
  amplify_core.TemporalDateTime get solvedAt {
    try {
      return _solvedAt!;
    } catch(e) {
      throw amplify_core.AmplifyCodeGenModelException(
          amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastExceptionMessage,
          recoverySuggestion:
            amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastRecoverySuggestion,
          underlyingException: e.toString()
          );
    }
  }
  
  int? get timeSpent {
    return _timeSpent;
  }
  
  int? get attempts {
    return _attempts;
  }
  
  amplify_core.TemporalDateTime? get createdAt {
    return _createdAt;
  }
  
  amplify_core.TemporalDateTime? get updatedAt {
    return _updatedAt;
  }
  
  const StudentProblemRecord._internal({required this.id, required studentUserId, required problemId, required textbookId, required chapterId, required isCorrect, studentAnswer, required solvedAt, timeSpent, attempts, createdAt, updatedAt}): _studentUserId = studentUserId, _problemId = problemId, _textbookId = textbookId, _chapterId = chapterId, _isCorrect = isCorrect, _studentAnswer = studentAnswer, _solvedAt = solvedAt, _timeSpent = timeSpent, _attempts = attempts, _createdAt = createdAt, _updatedAt = updatedAt;
  
  factory StudentProblemRecord({String? id, required String studentUserId, required String problemId, required String textbookId, required String chapterId, required bool isCorrect, String? studentAnswer, required amplify_core.TemporalDateTime solvedAt, int? timeSpent, int? attempts, amplify_core.TemporalDateTime? createdAt, amplify_core.TemporalDateTime? updatedAt}) {
    return StudentProblemRecord._internal(
      id: id == null ? amplify_core.UUID.getUUID() : id,
      studentUserId: studentUserId,
      problemId: problemId,
      textbookId: textbookId,
      chapterId: chapterId,
      isCorrect: isCorrect,
      studentAnswer: studentAnswer,
      solvedAt: solvedAt,
      timeSpent: timeSpent,
      attempts: attempts,
      createdAt: createdAt,
      updatedAt: updatedAt);
  }
  
  bool equals(Object other) {
    return this == other;
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is StudentProblemRecord &&
      id == other.id &&
      _studentUserId == other._studentUserId &&
      _problemId == other._problemId &&
      _textbookId == other._textbookId &&
      _chapterId == other._chapterId &&
      _isCorrect == other._isCorrect &&
      _studentAnswer == other._studentAnswer &&
      _solvedAt == other._solvedAt &&
      _timeSpent == other._timeSpent &&
      _attempts == other._attempts &&
      _createdAt == other._createdAt &&
      _updatedAt == other._updatedAt;
  }
  
  @override
  int get hashCode => toString().hashCode;
  
  @override
  String toString() {
    var buffer = new StringBuffer();
    
    buffer.write("StudentProblemRecord {");
    buffer.write("id=" + "$id" + ", ");
    buffer.write("studentUserId=" + "$_studentUserId" + ", ");
    buffer.write("problemId=" + "$_problemId" + ", ");
    buffer.write("textbookId=" + "$_textbookId" + ", ");
    buffer.write("chapterId=" + "$_chapterId" + ", ");
    buffer.write("isCorrect=" + (_isCorrect != null ? _isCorrect!.toString() : "null") + ", ");
    buffer.write("studentAnswer=" + "$_studentAnswer" + ", ");
    buffer.write("solvedAt=" + (_solvedAt != null ? _solvedAt!.format() : "null") + ", ");
    buffer.write("timeSpent=" + (_timeSpent != null ? _timeSpent!.toString() : "null") + ", ");
    buffer.write("attempts=" + (_attempts != null ? _attempts!.toString() : "null") + ", ");
    buffer.write("createdAt=" + (_createdAt != null ? _createdAt!.format() : "null") + ", ");
    buffer.write("updatedAt=" + (_updatedAt != null ? _updatedAt!.format() : "null"));
    buffer.write("}");
    
    return buffer.toString();
  }
  
  StudentProblemRecord copyWith({String? studentUserId, String? problemId, String? textbookId, String? chapterId, bool? isCorrect, String? studentAnswer, amplify_core.TemporalDateTime? solvedAt, int? timeSpent, int? attempts, amplify_core.TemporalDateTime? createdAt, amplify_core.TemporalDateTime? updatedAt}) {
    return StudentProblemRecord._internal(
      id: id,
      studentUserId: studentUserId ?? this.studentUserId,
      problemId: problemId ?? this.problemId,
      textbookId: textbookId ?? this.textbookId,
      chapterId: chapterId ?? this.chapterId,
      isCorrect: isCorrect ?? this.isCorrect,
      studentAnswer: studentAnswer ?? this.studentAnswer,
      solvedAt: solvedAt ?? this.solvedAt,
      timeSpent: timeSpent ?? this.timeSpent,
      attempts: attempts ?? this.attempts,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt);
  }
  
  StudentProblemRecord copyWithModelFieldValues({
    ModelFieldValue<String>? studentUserId,
    ModelFieldValue<String>? problemId,
    ModelFieldValue<String>? textbookId,
    ModelFieldValue<String>? chapterId,
    ModelFieldValue<bool>? isCorrect,
    ModelFieldValue<String?>? studentAnswer,
    ModelFieldValue<amplify_core.TemporalDateTime>? solvedAt,
    ModelFieldValue<int?>? timeSpent,
    ModelFieldValue<int?>? attempts,
    ModelFieldValue<amplify_core.TemporalDateTime?>? createdAt,
    ModelFieldValue<amplify_core.TemporalDateTime?>? updatedAt
  }) {
    return StudentProblemRecord._internal(
      id: id,
      studentUserId: studentUserId == null ? this.studentUserId : studentUserId.value,
      problemId: problemId == null ? this.problemId : problemId.value,
      textbookId: textbookId == null ? this.textbookId : textbookId.value,
      chapterId: chapterId == null ? this.chapterId : chapterId.value,
      isCorrect: isCorrect == null ? this.isCorrect : isCorrect.value,
      studentAnswer: studentAnswer == null ? this.studentAnswer : studentAnswer.value,
      solvedAt: solvedAt == null ? this.solvedAt : solvedAt.value,
      timeSpent: timeSpent == null ? this.timeSpent : timeSpent.value,
      attempts: attempts == null ? this.attempts : attempts.value,
      createdAt: createdAt == null ? this.createdAt : createdAt.value,
      updatedAt: updatedAt == null ? this.updatedAt : updatedAt.value
    );
  }
  
  StudentProblemRecord.fromJson(Map<String, dynamic> json)  
    : id = json['id'],
      _studentUserId = json['studentUserId'],
      _problemId = json['problemId'],
      _textbookId = json['textbookId'],
      _chapterId = json['chapterId'],
      _isCorrect = json['isCorrect'],
      _studentAnswer = json['studentAnswer'],
      _solvedAt = json['solvedAt'] != null ? amplify_core.TemporalDateTime.fromString(json['solvedAt']) : null,
      _timeSpent = (json['timeSpent'] as num?)?.toInt(),
      _attempts = (json['attempts'] as num?)?.toInt(),
      _createdAt = json['createdAt'] != null ? amplify_core.TemporalDateTime.fromString(json['createdAt']) : null,
      _updatedAt = json['updatedAt'] != null ? amplify_core.TemporalDateTime.fromString(json['updatedAt']) : null;
  
  Map<String, dynamic> toJson() => {
    'id': id, 'studentUserId': _studentUserId, 'problemId': _problemId, 'textbookId': _textbookId, 'chapterId': _chapterId, 'isCorrect': _isCorrect, 'studentAnswer': _studentAnswer, 'solvedAt': _solvedAt?.format(), 'timeSpent': _timeSpent, 'attempts': _attempts, 'createdAt': _createdAt?.format(), 'updatedAt': _updatedAt?.format()
  };
  
  Map<String, Object?> toMap() => {
    'id': id,
    'studentUserId': _studentUserId,
    'problemId': _problemId,
    'textbookId': _textbookId,
    'chapterId': _chapterId,
    'isCorrect': _isCorrect,
    'studentAnswer': _studentAnswer,
    'solvedAt': _solvedAt,
    'timeSpent': _timeSpent,
    'attempts': _attempts,
    'createdAt': _createdAt,
    'updatedAt': _updatedAt
  };

  static final amplify_core.QueryModelIdentifier<StudentProblemRecordModelIdentifier> MODEL_IDENTIFIER = amplify_core.QueryModelIdentifier<StudentProblemRecordModelIdentifier>();
  static final ID = amplify_core.QueryField(fieldName: "id");
  static final STUDENTUSERID = amplify_core.QueryField(fieldName: "studentUserId");
  static final PROBLEMID = amplify_core.QueryField(fieldName: "problemId");
  static final TEXTBOOKID = amplify_core.QueryField(fieldName: "textbookId");
  static final CHAPTERID = amplify_core.QueryField(fieldName: "chapterId");
  static final ISCORRECT = amplify_core.QueryField(fieldName: "isCorrect");
  static final STUDENTANSWER = amplify_core.QueryField(fieldName: "studentAnswer");
  static final SOLVEDAT = amplify_core.QueryField(fieldName: "solvedAt");
  static final TIMESPENT = amplify_core.QueryField(fieldName: "timeSpent");
  static final ATTEMPTS = amplify_core.QueryField(fieldName: "attempts");
  static final CREATEDAT = amplify_core.QueryField(fieldName: "createdAt");
  static final UPDATEDAT = amplify_core.QueryField(fieldName: "updatedAt");
  static var schema = amplify_core.Model.defineSchema(define: (amplify_core.ModelSchemaDefinition modelSchemaDefinition) {
    modelSchemaDefinition.name = "StudentProblemRecord";
    modelSchemaDefinition.pluralName = "StudentProblemRecords";
    
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
        ownerField: "studentUserId",
        identityClaim: "cognito:username",
        provider: amplify_core.AuthRuleProvider.USERPOOLS,
        operations: const [
          amplify_core.ModelOperation.CREATE,
          amplify_core.ModelOperation.READ,
          amplify_core.ModelOperation.UPDATE
        ]),
      amplify_core.AuthRule(
        authStrategy: amplify_core.AuthStrategy.GROUPS,
        groupClaim: "cognito:groups",
        groups: [ "teachers" ],
        provider: amplify_core.AuthRuleProvider.USERPOOLS,
        operations: const [
          amplify_core.ModelOperation.READ
        ])
    ];
    
    modelSchemaDefinition.indexes = [
      amplify_core.ModelIndex(fields: const ["studentUserId", "solvedAt"], name: "byStudent"),
      amplify_core.ModelIndex(fields: const ["problemId"], name: "byProblem"),
      amplify_core.ModelIndex(fields: const ["textbookId"], name: "byTextbook"),
      amplify_core.ModelIndex(fields: const ["chapterId"], name: "byChapter")
    ];
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.id());
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: StudentProblemRecord.STUDENTUSERID,
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: StudentProblemRecord.PROBLEMID,
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: StudentProblemRecord.TEXTBOOKID,
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: StudentProblemRecord.CHAPTERID,
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: StudentProblemRecord.ISCORRECT,
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.bool)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: StudentProblemRecord.STUDENTANSWER,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: StudentProblemRecord.SOLVEDAT,
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.dateTime)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: StudentProblemRecord.TIMESPENT,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.int)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: StudentProblemRecord.ATTEMPTS,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.int)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: StudentProblemRecord.CREATEDAT,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.dateTime)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: StudentProblemRecord.UPDATEDAT,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.dateTime)
    ));
  });
}

class _StudentProblemRecordModelType extends amplify_core.ModelType<StudentProblemRecord> {
  const _StudentProblemRecordModelType();
  
  @override
  StudentProblemRecord fromJson(Map<String, dynamic> jsonData) {
    return StudentProblemRecord.fromJson(jsonData);
  }
  
  @override
  String modelName() {
    return 'StudentProblemRecord';
  }
}

/**
 * This is an auto generated class representing the model identifier
 * of [StudentProblemRecord] in your schema.
 */
class StudentProblemRecordModelIdentifier implements amplify_core.ModelIdentifier<StudentProblemRecord> {
  final String id;

  /** Create an instance of StudentProblemRecordModelIdentifier using [id] the primary key. */
  const StudentProblemRecordModelIdentifier({
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
  String toString() => 'StudentProblemRecordModelIdentifier(id: $id)';
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    
    return other is StudentProblemRecordModelIdentifier &&
      id == other.id;
  }
  
  @override
  int get hashCode =>
    id.hashCode;
}