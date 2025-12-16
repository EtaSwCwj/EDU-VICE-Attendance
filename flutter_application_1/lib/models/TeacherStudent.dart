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


/** This is an auto generated class representing the TeacherStudent type in your schema. */
class TeacherStudent extends amplify_core.Model {
  static const classType = const _TeacherStudentModelType();
  final String id;
  final String? _teacherUsername;
  final String? _studentUsername;
  final List<Subject>? _subjects;
  final amplify_core.TemporalDateTime? _createdAt;
  final amplify_core.TemporalDateTime? _updatedAt;

  @override
  getInstanceType() => classType;
  
  @Deprecated('[getId] is being deprecated in favor of custom primary key feature. Use getter [modelIdentifier] to get model identifier.')
  @override
  String getId() => id;
  
  TeacherStudentModelIdentifier get modelIdentifier {
      return TeacherStudentModelIdentifier(
        id: id
      );
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
  
  String get studentUsername {
    try {
      return _studentUsername!;
    } catch(e) {
      throw amplify_core.AmplifyCodeGenModelException(
          amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastExceptionMessage,
          recoverySuggestion:
            amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastRecoverySuggestion,
          underlyingException: e.toString()
          );
    }
  }
  
  List<Subject>? get subjects {
    return _subjects;
  }
  
  amplify_core.TemporalDateTime? get createdAt {
    return _createdAt;
  }
  
  amplify_core.TemporalDateTime? get updatedAt {
    return _updatedAt;
  }
  
  const TeacherStudent._internal({required this.id, required teacherUsername, required studentUsername, subjects, createdAt, updatedAt}): _teacherUsername = teacherUsername, _studentUsername = studentUsername, _subjects = subjects, _createdAt = createdAt, _updatedAt = updatedAt;
  
  factory TeacherStudent({String? id, required String teacherUsername, required String studentUsername, List<Subject>? subjects, amplify_core.TemporalDateTime? createdAt, amplify_core.TemporalDateTime? updatedAt}) {
    return TeacherStudent._internal(
      id: id == null ? amplify_core.UUID.getUUID() : id,
      teacherUsername: teacherUsername,
      studentUsername: studentUsername,
      subjects: subjects != null ? List<Subject>.unmodifiable(subjects) : subjects,
      createdAt: createdAt,
      updatedAt: updatedAt);
  }
  
  bool equals(Object other) {
    return this == other;
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is TeacherStudent &&
      id == other.id &&
      _teacherUsername == other._teacherUsername &&
      _studentUsername == other._studentUsername &&
      DeepCollectionEquality().equals(_subjects, other._subjects) &&
      _createdAt == other._createdAt &&
      _updatedAt == other._updatedAt;
  }
  
  @override
  int get hashCode => toString().hashCode;
  
  @override
  String toString() {
    var buffer = new StringBuffer();
    
    buffer.write("TeacherStudent {");
    buffer.write("id=" + "$id" + ", ");
    buffer.write("teacherUsername=" + "$_teacherUsername" + ", ");
    buffer.write("studentUsername=" + "$_studentUsername" + ", ");
    buffer.write("subjects=" + (_subjects != null ? _subjects!.map((e) => amplify_core.enumToString(e)).toString() : "null") + ", ");
    buffer.write("createdAt=" + (_createdAt != null ? _createdAt!.format() : "null") + ", ");
    buffer.write("updatedAt=" + (_updatedAt != null ? _updatedAt!.format() : "null"));
    buffer.write("}");
    
    return buffer.toString();
  }
  
  TeacherStudent copyWith({String? teacherUsername, String? studentUsername, List<Subject>? subjects, amplify_core.TemporalDateTime? createdAt, amplify_core.TemporalDateTime? updatedAt}) {
    return TeacherStudent._internal(
      id: id,
      teacherUsername: teacherUsername ?? this.teacherUsername,
      studentUsername: studentUsername ?? this.studentUsername,
      subjects: subjects ?? this.subjects,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt);
  }
  
  TeacherStudent copyWithModelFieldValues({
    ModelFieldValue<String>? teacherUsername,
    ModelFieldValue<String>? studentUsername,
    ModelFieldValue<List<Subject>?>? subjects,
    ModelFieldValue<amplify_core.TemporalDateTime?>? createdAt,
    ModelFieldValue<amplify_core.TemporalDateTime?>? updatedAt
  }) {
    return TeacherStudent._internal(
      id: id,
      teacherUsername: teacherUsername == null ? this.teacherUsername : teacherUsername.value,
      studentUsername: studentUsername == null ? this.studentUsername : studentUsername.value,
      subjects: subjects == null ? this.subjects : subjects.value,
      createdAt: createdAt == null ? this.createdAt : createdAt.value,
      updatedAt: updatedAt == null ? this.updatedAt : updatedAt.value
    );
  }
  
  TeacherStudent.fromJson(Map<String, dynamic> json)  
    : id = json['id'],
      _teacherUsername = json['teacherUsername'],
      _studentUsername = json['studentUsername'],
      _subjects = json['subjects'] is List
        ? (json['subjects'] as List)
          .map((e) => amplify_core.enumFromString<Subject>(e, Subject.values)!)
          .toList()
        : null,
      _createdAt = json['createdAt'] != null ? amplify_core.TemporalDateTime.fromString(json['createdAt']) : null,
      _updatedAt = json['updatedAt'] != null ? amplify_core.TemporalDateTime.fromString(json['updatedAt']) : null;
  
  Map<String, dynamic> toJson() => {
    'id': id, 'teacherUsername': _teacherUsername, 'studentUsername': _studentUsername, 'subjects': _subjects?.map((e) => amplify_core.enumToString(e)).toList(), 'createdAt': _createdAt?.format(), 'updatedAt': _updatedAt?.format()
  };
  
  Map<String, Object?> toMap() => {
    'id': id,
    'teacherUsername': _teacherUsername,
    'studentUsername': _studentUsername,
    'subjects': _subjects,
    'createdAt': _createdAt,
    'updatedAt': _updatedAt
  };

  static final amplify_core.QueryModelIdentifier<TeacherStudentModelIdentifier> MODEL_IDENTIFIER = amplify_core.QueryModelIdentifier<TeacherStudentModelIdentifier>();
  static final ID = amplify_core.QueryField(fieldName: "id");
  static final TEACHERUSERNAME = amplify_core.QueryField(fieldName: "teacherUsername");
  static final STUDENTUSERNAME = amplify_core.QueryField(fieldName: "studentUsername");
  static final SUBJECTS = amplify_core.QueryField(fieldName: "subjects");
  static final CREATEDAT = amplify_core.QueryField(fieldName: "createdAt");
  static final UPDATEDAT = amplify_core.QueryField(fieldName: "updatedAt");
  static var schema = amplify_core.Model.defineSchema(define: (amplify_core.ModelSchemaDefinition modelSchemaDefinition) {
    modelSchemaDefinition.name = "TeacherStudent";
    modelSchemaDefinition.pluralName = "TeacherStudents";
    
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
        authStrategy: amplify_core.AuthStrategy.OWNER,
        ownerField: "studentUsername",
        identityClaim: "cognito:username",
        provider: amplify_core.AuthRuleProvider.USERPOOLS,
        operations: const [
          amplify_core.ModelOperation.READ
        ])
    ];
    
    modelSchemaDefinition.indexes = [
      amplify_core.ModelIndex(fields: const ["teacherUsername", "studentUsername"], name: "byTeacher"),
      amplify_core.ModelIndex(fields: const ["studentUsername", "teacherUsername"], name: "byStudent")
    ];
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.id());
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: TeacherStudent.TEACHERUSERNAME,
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: TeacherStudent.STUDENTUSERNAME,
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: TeacherStudent.SUBJECTS,
      isRequired: false,
      isArray: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.collection, ofModelName: amplify_core.ModelFieldTypeEnum.enumeration.name)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: TeacherStudent.CREATEDAT,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.dateTime)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: TeacherStudent.UPDATEDAT,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.dateTime)
    ));
  });
}

class _TeacherStudentModelType extends amplify_core.ModelType<TeacherStudent> {
  const _TeacherStudentModelType();
  
  @override
  TeacherStudent fromJson(Map<String, dynamic> jsonData) {
    return TeacherStudent.fromJson(jsonData);
  }
  
  @override
  String modelName() {
    return 'TeacherStudent';
  }
}

/**
 * This is an auto generated class representing the model identifier
 * of [TeacherStudent] in your schema.
 */
class TeacherStudentModelIdentifier implements amplify_core.ModelIdentifier<TeacherStudent> {
  final String id;

  /** Create an instance of TeacherStudentModelIdentifier using [id] the primary key. */
  const TeacherStudentModelIdentifier({
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
  String toString() => 'TeacherStudentModelIdentifier(id: $id)';
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    
    return other is TeacherStudentModelIdentifier &&
      id == other.id;
  }
  
  @override
  int get hashCode =>
    id.hashCode;
}