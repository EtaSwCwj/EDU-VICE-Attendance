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


/** This is an auto generated class representing the Invitation type in your schema. */
class Invitation extends amplify_core.Model {
  static const classType = const _InvitationModelType();
  final String id;
  final String? _academyId;
  final String? _inviterUserId;
  final String? _inviteeEmail;
  final String? _inviteeUserId;
  final String? _role;
  final String? _status;
  final String? _inviteCode;
  final amplify_core.TemporalDateTime? _expiresAt;
  final amplify_core.TemporalDateTime? _usedAt;
  final String? _usedBy;
  final amplify_core.TemporalDateTime? _createdAt;
  final amplify_core.TemporalDateTime? _updatedAt;

  @override
  getInstanceType() => classType;
  
  @Deprecated('[getId] is being deprecated in favor of custom primary key feature. Use getter [modelIdentifier] to get model identifier.')
  @override
  String getId() => id;
  
  InvitationModelIdentifier get modelIdentifier {
      return InvitationModelIdentifier(
        id: id
      );
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
  
  String get inviterUserId {
    try {
      return _inviterUserId!;
    } catch(e) {
      throw amplify_core.AmplifyCodeGenModelException(
          amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastExceptionMessage,
          recoverySuggestion:
            amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastRecoverySuggestion,
          underlyingException: e.toString()
          );
    }
  }
  
  String get inviteeEmail {
    try {
      return _inviteeEmail!;
    } catch(e) {
      throw amplify_core.AmplifyCodeGenModelException(
          amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastExceptionMessage,
          recoverySuggestion:
            amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastRecoverySuggestion,
          underlyingException: e.toString()
          );
    }
  }
  
  String? get inviteeUserId {
    return _inviteeUserId;
  }
  
  String get role {
    try {
      return _role!;
    } catch(e) {
      throw amplify_core.AmplifyCodeGenModelException(
          amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastExceptionMessage,
          recoverySuggestion:
            amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastRecoverySuggestion,
          underlyingException: e.toString()
          );
    }
  }
  
  String get status {
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
  
  String get inviteCode {
    try {
      return _inviteCode!;
    } catch(e) {
      throw amplify_core.AmplifyCodeGenModelException(
          amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastExceptionMessage,
          recoverySuggestion:
            amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastRecoverySuggestion,
          underlyingException: e.toString()
          );
    }
  }
  
  amplify_core.TemporalDateTime get expiresAt {
    try {
      return _expiresAt!;
    } catch(e) {
      throw amplify_core.AmplifyCodeGenModelException(
          amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastExceptionMessage,
          recoverySuggestion:
            amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastRecoverySuggestion,
          underlyingException: e.toString()
          );
    }
  }
  
  amplify_core.TemporalDateTime? get usedAt {
    return _usedAt;
  }
  
  String? get usedBy {
    return _usedBy;
  }
  
  amplify_core.TemporalDateTime? get createdAt {
    return _createdAt;
  }
  
  amplify_core.TemporalDateTime? get updatedAt {
    return _updatedAt;
  }
  
  const Invitation._internal({required this.id, required academyId, required inviterUserId, required inviteeEmail, inviteeUserId, required role, required status, required inviteCode, required expiresAt, usedAt, usedBy, createdAt, updatedAt}): _academyId = academyId, _inviterUserId = inviterUserId, _inviteeEmail = inviteeEmail, _inviteeUserId = inviteeUserId, _role = role, _status = status, _inviteCode = inviteCode, _expiresAt = expiresAt, _usedAt = usedAt, _usedBy = usedBy, _createdAt = createdAt, _updatedAt = updatedAt;
  
  factory Invitation({String? id, required String academyId, required String inviterUserId, required String inviteeEmail, String? inviteeUserId, required String role, required String status, required String inviteCode, required amplify_core.TemporalDateTime expiresAt, amplify_core.TemporalDateTime? usedAt, String? usedBy, amplify_core.TemporalDateTime? createdAt, amplify_core.TemporalDateTime? updatedAt}) {
    return Invitation._internal(
      id: id == null ? amplify_core.UUID.getUUID() : id,
      academyId: academyId,
      inviterUserId: inviterUserId,
      inviteeEmail: inviteeEmail,
      inviteeUserId: inviteeUserId,
      role: role,
      status: status,
      inviteCode: inviteCode,
      expiresAt: expiresAt,
      usedAt: usedAt,
      usedBy: usedBy,
      createdAt: createdAt,
      updatedAt: updatedAt);
  }
  
  bool equals(Object other) {
    return this == other;
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is Invitation &&
      id == other.id &&
      _academyId == other._academyId &&
      _inviterUserId == other._inviterUserId &&
      _inviteeEmail == other._inviteeEmail &&
      _inviteeUserId == other._inviteeUserId &&
      _role == other._role &&
      _status == other._status &&
      _inviteCode == other._inviteCode &&
      _expiresAt == other._expiresAt &&
      _usedAt == other._usedAt &&
      _usedBy == other._usedBy &&
      _createdAt == other._createdAt &&
      _updatedAt == other._updatedAt;
  }
  
  @override
  int get hashCode => toString().hashCode;
  
  @override
  String toString() {
    var buffer = new StringBuffer();
    
    buffer.write("Invitation {");
    buffer.write("id=" + "$id" + ", ");
    buffer.write("academyId=" + "$_academyId" + ", ");
    buffer.write("inviterUserId=" + "$_inviterUserId" + ", ");
    buffer.write("inviteeEmail=" + "$_inviteeEmail" + ", ");
    buffer.write("inviteeUserId=" + "$_inviteeUserId" + ", ");
    buffer.write("role=" + "$_role" + ", ");
    buffer.write("status=" + "$_status" + ", ");
    buffer.write("inviteCode=" + "$_inviteCode" + ", ");
    buffer.write("expiresAt=" + (_expiresAt != null ? _expiresAt!.format() : "null") + ", ");
    buffer.write("usedAt=" + (_usedAt != null ? _usedAt!.format() : "null") + ", ");
    buffer.write("usedBy=" + "$_usedBy" + ", ");
    buffer.write("createdAt=" + (_createdAt != null ? _createdAt!.format() : "null") + ", ");
    buffer.write("updatedAt=" + (_updatedAt != null ? _updatedAt!.format() : "null"));
    buffer.write("}");
    
    return buffer.toString();
  }
  
  Invitation copyWith({String? academyId, String? inviterUserId, String? inviteeEmail, String? inviteeUserId, String? role, String? status, String? inviteCode, amplify_core.TemporalDateTime? expiresAt, amplify_core.TemporalDateTime? usedAt, String? usedBy, amplify_core.TemporalDateTime? createdAt, amplify_core.TemporalDateTime? updatedAt}) {
    return Invitation._internal(
      id: id,
      academyId: academyId ?? this.academyId,
      inviterUserId: inviterUserId ?? this.inviterUserId,
      inviteeEmail: inviteeEmail ?? this.inviteeEmail,
      inviteeUserId: inviteeUserId ?? this.inviteeUserId,
      role: role ?? this.role,
      status: status ?? this.status,
      inviteCode: inviteCode ?? this.inviteCode,
      expiresAt: expiresAt ?? this.expiresAt,
      usedAt: usedAt ?? this.usedAt,
      usedBy: usedBy ?? this.usedBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt);
  }
  
  Invitation copyWithModelFieldValues({
    ModelFieldValue<String>? academyId,
    ModelFieldValue<String>? inviterUserId,
    ModelFieldValue<String>? inviteeEmail,
    ModelFieldValue<String?>? inviteeUserId,
    ModelFieldValue<String>? role,
    ModelFieldValue<String>? status,
    ModelFieldValue<String>? inviteCode,
    ModelFieldValue<amplify_core.TemporalDateTime>? expiresAt,
    ModelFieldValue<amplify_core.TemporalDateTime?>? usedAt,
    ModelFieldValue<String?>? usedBy,
    ModelFieldValue<amplify_core.TemporalDateTime?>? createdAt,
    ModelFieldValue<amplify_core.TemporalDateTime?>? updatedAt
  }) {
    return Invitation._internal(
      id: id,
      academyId: academyId == null ? this.academyId : academyId.value,
      inviterUserId: inviterUserId == null ? this.inviterUserId : inviterUserId.value,
      inviteeEmail: inviteeEmail == null ? this.inviteeEmail : inviteeEmail.value,
      inviteeUserId: inviteeUserId == null ? this.inviteeUserId : inviteeUserId.value,
      role: role == null ? this.role : role.value,
      status: status == null ? this.status : status.value,
      inviteCode: inviteCode == null ? this.inviteCode : inviteCode.value,
      expiresAt: expiresAt == null ? this.expiresAt : expiresAt.value,
      usedAt: usedAt == null ? this.usedAt : usedAt.value,
      usedBy: usedBy == null ? this.usedBy : usedBy.value,
      createdAt: createdAt == null ? this.createdAt : createdAt.value,
      updatedAt: updatedAt == null ? this.updatedAt : updatedAt.value
    );
  }
  
  Invitation.fromJson(Map<String, dynamic> json)  
    : id = json['id'],
      _academyId = json['academyId'],
      _inviterUserId = json['inviterUserId'],
      _inviteeEmail = json['inviteeEmail'],
      _inviteeUserId = json['inviteeUserId'],
      _role = json['role'],
      _status = json['status'],
      _inviteCode = json['inviteCode'],
      _expiresAt = json['expiresAt'] != null ? amplify_core.TemporalDateTime.fromString(json['expiresAt']) : null,
      _usedAt = json['usedAt'] != null ? amplify_core.TemporalDateTime.fromString(json['usedAt']) : null,
      _usedBy = json['usedBy'],
      _createdAt = json['createdAt'] != null ? amplify_core.TemporalDateTime.fromString(json['createdAt']) : null,
      _updatedAt = json['updatedAt'] != null ? amplify_core.TemporalDateTime.fromString(json['updatedAt']) : null;
  
  Map<String, dynamic> toJson() => {
    'id': id, 'academyId': _academyId, 'inviterUserId': _inviterUserId, 'inviteeEmail': _inviteeEmail, 'inviteeUserId': _inviteeUserId, 'role': _role, 'status': _status, 'inviteCode': _inviteCode, 'expiresAt': _expiresAt?.format(), 'usedAt': _usedAt?.format(), 'usedBy': _usedBy, 'createdAt': _createdAt?.format(), 'updatedAt': _updatedAt?.format()
  };
  
  Map<String, Object?> toMap() => {
    'id': id,
    'academyId': _academyId,
    'inviterUserId': _inviterUserId,
    'inviteeEmail': _inviteeEmail,
    'inviteeUserId': _inviteeUserId,
    'role': _role,
    'status': _status,
    'inviteCode': _inviteCode,
    'expiresAt': _expiresAt,
    'usedAt': _usedAt,
    'usedBy': _usedBy,
    'createdAt': _createdAt,
    'updatedAt': _updatedAt
  };

  static final amplify_core.QueryModelIdentifier<InvitationModelIdentifier> MODEL_IDENTIFIER = amplify_core.QueryModelIdentifier<InvitationModelIdentifier>();
  static final ID = amplify_core.QueryField(fieldName: "id");
  static final ACADEMYID = amplify_core.QueryField(fieldName: "academyId");
  static final INVITERUSERID = amplify_core.QueryField(fieldName: "inviterUserId");
  static final INVITEEEMAIL = amplify_core.QueryField(fieldName: "inviteeEmail");
  static final INVITEEUSERID = amplify_core.QueryField(fieldName: "inviteeUserId");
  static final ROLE = amplify_core.QueryField(fieldName: "role");
  static final STATUS = amplify_core.QueryField(fieldName: "status");
  static final INVITECODE = amplify_core.QueryField(fieldName: "inviteCode");
  static final EXPIRESAT = amplify_core.QueryField(fieldName: "expiresAt");
  static final USEDAT = amplify_core.QueryField(fieldName: "usedAt");
  static final USEDBY = amplify_core.QueryField(fieldName: "usedBy");
  static final CREATEDAT = amplify_core.QueryField(fieldName: "createdAt");
  static final UPDATEDAT = amplify_core.QueryField(fieldName: "updatedAt");
  static var schema = amplify_core.Model.defineSchema(define: (amplify_core.ModelSchemaDefinition modelSchemaDefinition) {
    modelSchemaDefinition.name = "Invitation";
    modelSchemaDefinition.pluralName = "Invitations";
    
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
        ownerField: "inviteeUserId",
        identityClaim: "cognito:username",
        provider: amplify_core.AuthRuleProvider.USERPOOLS,
        operations: const [
          amplify_core.ModelOperation.READ,
          amplify_core.ModelOperation.UPDATE
        ]),
      amplify_core.AuthRule(
        authStrategy: amplify_core.AuthStrategy.PRIVATE,
        operations: const [
          amplify_core.ModelOperation.READ
        ])
    ];
    
    modelSchemaDefinition.indexes = [
      amplify_core.ModelIndex(fields: const ["academyId"], name: "byAcademy"),
      amplify_core.ModelIndex(fields: const ["inviteeEmail"], name: "byInviteeEmail"),
      amplify_core.ModelIndex(fields: const ["status"], name: "byStatus"),
      amplify_core.ModelIndex(fields: const ["inviteCode"], name: "byInviteCode")
    ];
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.id());
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Invitation.ACADEMYID,
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Invitation.INVITERUSERID,
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Invitation.INVITEEEMAIL,
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Invitation.INVITEEUSERID,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Invitation.ROLE,
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Invitation.STATUS,
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Invitation.INVITECODE,
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Invitation.EXPIRESAT,
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.dateTime)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Invitation.USEDAT,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.dateTime)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Invitation.USEDBY,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Invitation.CREATEDAT,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.dateTime)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Invitation.UPDATEDAT,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.dateTime)
    ));
  });
}

class _InvitationModelType extends amplify_core.ModelType<Invitation> {
  const _InvitationModelType();
  
  @override
  Invitation fromJson(Map<String, dynamic> jsonData) {
    return Invitation.fromJson(jsonData);
  }
  
  @override
  String modelName() {
    return 'Invitation';
  }
}

/**
 * This is an auto generated class representing the model identifier
 * of [Invitation] in your schema.
 */
class InvitationModelIdentifier implements amplify_core.ModelIdentifier<Invitation> {
  final String id;

  /** Create an instance of InvitationModelIdentifier using [id] the primary key. */
  const InvitationModelIdentifier({
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
  String toString() => 'InvitationModelIdentifier(id: $id)';
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    
    return other is InvitationModelIdentifier &&
      id == other.id;
  }
  
  @override
  int get hashCode =>
    id.hashCode;
}