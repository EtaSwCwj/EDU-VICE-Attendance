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


/** This is an auto generated class representing the StudentSupporter type in your schema. */
class StudentSupporter extends amplify_core.Model {
  static const classType = const _StudentSupporterModelType();
  final String id;
  final String? _studentMemberId;
  final String? _supporterUserId;
  final String? _academyId;
  final String? _relationship;
  final amplify_core.TemporalDateTime? _createdAt;
  final amplify_core.TemporalDateTime? _updatedAt;

  @override
  getInstanceType() => classType;
  
  @Deprecated('[getId] is being deprecated in favor of custom primary key feature. Use getter [modelIdentifier] to get model identifier.')
  @override
  String getId() => id;
  
  StudentSupporterModelIdentifier get modelIdentifier {
      return StudentSupporterModelIdentifier(
        id: id
      );
  }
  
  String get studentMemberId {
    try {
      return _studentMemberId!;
    } catch(e) {
      throw amplify_core.AmplifyCodeGenModelException(
          amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastExceptionMessage,
          recoverySuggestion:
            amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastRecoverySuggestion,
          underlyingException: e.toString()
          );
    }
  }
  
  String get supporterUserId {
    try {
      return _supporterUserId!;
    } catch(e) {
      throw amplify_core.AmplifyCodeGenModelException(
          amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastExceptionMessage,
          recoverySuggestion:
            amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastRecoverySuggestion,
          underlyingException: e.toString()
          );
    }
  }
  
  String get academyId {
    try {
      return _academyId!;
    } catch(e) {
      throw amplify_core.AmplifyCodeGenModelException(
          amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastExceptionMessage,
          recoverySuggestion:
            amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastRecoverySuggestion,
          underlyingException: e.toString()
          );
    }
  }
  
  String? get relationship {
    return _relationship;
  }
  
  amplify_core.TemporalDateTime? get createdAt {
    return _createdAt;
  }
  
  amplify_core.TemporalDateTime? get updatedAt {
    return _updatedAt;
  }
  
  const StudentSupporter._internal({required this.id, required studentMemberId, required supporterUserId, required academyId, relationship, createdAt, updatedAt}): _studentMemberId = studentMemberId, _supporterUserId = supporterUserId, _academyId = academyId, _relationship = relationship, _createdAt = createdAt, _updatedAt = updatedAt;
  
  factory StudentSupporter({String? id, required String studentMemberId, required String supporterUserId, required String academyId, String? relationship, amplify_core.TemporalDateTime? createdAt, amplify_core.TemporalDateTime? updatedAt}) {
    return StudentSupporter._internal(
      id: id == null ? amplify_core.UUID.getUUID() : id,
      studentMemberId: studentMemberId,
      supporterUserId: supporterUserId,
      academyId: academyId,
      relationship: relationship,
      createdAt: createdAt,
      updatedAt: updatedAt);
  }
  
  bool equals(Object other) {
    return this == other;
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is StudentSupporter &&
      id == other.id &&
      _studentMemberId == other._studentMemberId &&
      _supporterUserId == other._supporterUserId &&
      _academyId == other._academyId &&
      _relationship == other._relationship &&
      _createdAt == other._createdAt &&
      _updatedAt == other._updatedAt;
  }
  
  @override
  int get hashCode => toString().hashCode;
  
  @override
  String toString() {
    var buffer = new StringBuffer();
    
    buffer.write("StudentSupporter {");
    buffer.write("id=" + "$id" + ", ");
    buffer.write("studentMemberId=" + "$_studentMemberId" + ", ");
    buffer.write("supporterUserId=" + "$_supporterUserId" + ", ");
    buffer.write("academyId=" + "$_academyId" + ", ");
    buffer.write("relationship=" + "$_relationship" + ", ");
    buffer.write("createdAt=" + (_createdAt != null ? _createdAt!.format() : "null") + ", ");
    buffer.write("updatedAt=" + (_updatedAt != null ? _updatedAt!.format() : "null"));
    buffer.write("}");
    
    return buffer.toString();
  }
  
  StudentSupporter copyWith({String? studentMemberId, String? supporterUserId, String? academyId, String? relationship, amplify_core.TemporalDateTime? createdAt, amplify_core.TemporalDateTime? updatedAt}) {
    return StudentSupporter._internal(
      id: id,
      studentMemberId: studentMemberId ?? this.studentMemberId,
      supporterUserId: supporterUserId ?? this.supporterUserId,
      academyId: academyId ?? this.academyId,
      relationship: relationship ?? this.relationship,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt);
  }
  
  StudentSupporter copyWithModelFieldValues({
    ModelFieldValue<String>? studentMemberId,
    ModelFieldValue<String>? supporterUserId,
    ModelFieldValue<String>? academyId,
    ModelFieldValue<String?>? relationship,
    ModelFieldValue<amplify_core.TemporalDateTime?>? createdAt,
    ModelFieldValue<amplify_core.TemporalDateTime?>? updatedAt
  }) {
    return StudentSupporter._internal(
      id: id,
      studentMemberId: studentMemberId == null ? this.studentMemberId : studentMemberId.value,
      supporterUserId: supporterUserId == null ? this.supporterUserId : supporterUserId.value,
      academyId: academyId == null ? this.academyId : academyId.value,
      relationship: relationship == null ? this.relationship : relationship.value,
      createdAt: createdAt == null ? this.createdAt : createdAt.value,
      updatedAt: updatedAt == null ? this.updatedAt : updatedAt.value
    );
  }
  
  StudentSupporter.fromJson(Map<String, dynamic> json)  
    : id = json['id'],
      _studentMemberId = json['studentMemberId'],
      _supporterUserId = json['supporterUserId'],
      _academyId = json['academyId'],
      _relationship = json['relationship'],
      _createdAt = json['createdAt'] != null ? amplify_core.TemporalDateTime.fromString(json['createdAt']) : null,
      _updatedAt = json['updatedAt'] != null ? amplify_core.TemporalDateTime.fromString(json['updatedAt']) : null;
  
  Map<String, dynamic> toJson() => {
    'id': id, 'studentMemberId': _studentMemberId, 'supporterUserId': _supporterUserId, 'academyId': _academyId, 'relationship': _relationship, 'createdAt': _createdAt?.format(), 'updatedAt': _updatedAt?.format()
  };
  
  Map<String, Object?> toMap() => {
    'id': id,
    'studentMemberId': _studentMemberId,
    'supporterUserId': _supporterUserId,
    'academyId': _academyId,
    'relationship': _relationship,
    'createdAt': _createdAt,
    'updatedAt': _updatedAt
  };

  static final amplify_core.QueryModelIdentifier<StudentSupporterModelIdentifier> MODEL_IDENTIFIER = amplify_core.QueryModelIdentifier<StudentSupporterModelIdentifier>();
  static final ID = amplify_core.QueryField(fieldName: "id");
  static final STUDENTMEMBERID = amplify_core.QueryField(fieldName: "studentMemberId");
  static final SUPPORTERUSERID = amplify_core.QueryField(fieldName: "supporterUserId");
  static final ACADEMYID = amplify_core.QueryField(fieldName: "academyId");
  static final RELATIONSHIP = amplify_core.QueryField(fieldName: "relationship");
  static final CREATEDAT = amplify_core.QueryField(fieldName: "createdAt");
  static final UPDATEDAT = amplify_core.QueryField(fieldName: "updatedAt");
  static var schema = amplify_core.Model.defineSchema(define: (amplify_core.ModelSchemaDefinition modelSchemaDefinition) {
    modelSchemaDefinition.name = "StudentSupporter";
    modelSchemaDefinition.pluralName = "StudentSupporters";
    
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
        authStrategy: amplify_core.AuthStrategy.PRIVATE,
        operations: const [
          amplify_core.ModelOperation.READ
        ])
    ];
    
    modelSchemaDefinition.indexes = [
      amplify_core.ModelIndex(fields: const ["studentMemberId"], name: "byStudent"),
      amplify_core.ModelIndex(fields: const ["supporterUserId"], name: "bySupporter"),
      amplify_core.ModelIndex(fields: const ["academyId"], name: "byAcademy")
    ];
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.id());
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: StudentSupporter.STUDENTMEMBERID,
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: StudentSupporter.SUPPORTERUSERID,
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: StudentSupporter.ACADEMYID,
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: StudentSupporter.RELATIONSHIP,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: StudentSupporter.CREATEDAT,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.dateTime)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: StudentSupporter.UPDATEDAT,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.dateTime)
    ));
  });
}

class _StudentSupporterModelType extends amplify_core.ModelType<StudentSupporter> {
  const _StudentSupporterModelType();
  
  @override
  StudentSupporter fromJson(Map<String, dynamic> jsonData) {
    return StudentSupporter.fromJson(jsonData);
  }
  
  @override
  String modelName() {
    return 'StudentSupporter';
  }
}

/**
 * This is an auto generated class representing the model identifier
 * of [StudentSupporter] in your schema.
 */
class StudentSupporterModelIdentifier implements amplify_core.ModelIdentifier<StudentSupporter> {
  final String id;

  /** Create an instance of StudentSupporterModelIdentifier using [id] the primary key. */
  const StudentSupporterModelIdentifier({
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
  String toString() => 'StudentSupporterModelIdentifier(id: $id)';
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    
    return other is StudentSupporterModelIdentifier &&
      id == other.id;
  }
  
  @override
  int get hashCode =>
    id.hashCode;
}