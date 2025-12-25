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


/** This is an auto generated class representing the Academy type in your schema. */
class AcademyModel extends amplify_core.Model {
  static const classType = const _AcademyModelModelType();
  final String id;
  final String? _code;
  final String? _name;
  final String? _address;
  final String? _phone;
  final String? _description;
  final amplify_core.TemporalDateTime? _createdAt;
  final amplify_core.TemporalDateTime? _updatedAt;

  @override
  getInstanceType() => classType;

  @Deprecated('[getId] is being deprecated in favor of custom primary key feature. Use getter [modelIdentifier] to get model identifier.')
  @override
  String getId() => id;

  AcademyModelModelIdentifier get modelIdentifier {
      return AcademyModelModelIdentifier(
        id: id
      );
  }

  String get code {
    try {
      return _code!;
    } catch(e) {
      throw amplify_core.AmplifyCodeGenModelException(
          amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastExceptionMessage,
          recoverySuggestion:
            amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastRecoverySuggestion,
          underlyingException: e.toString()
          );
    }
  }

  String get name {
    try {
      return _name!;
    } catch(e) {
      throw amplify_core.AmplifyCodeGenModelException(
          amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastExceptionMessage,
          recoverySuggestion:
            amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastRecoverySuggestion,
          underlyingException: e.toString()
          );
    }
  }

  String? get address {
    return _address;
  }

  String? get phone {
    return _phone;
  }

  String? get description {
    return _description;
  }

  amplify_core.TemporalDateTime? get createdAt {
    return _createdAt;
  }

  amplify_core.TemporalDateTime? get updatedAt {
    return _updatedAt;
  }

  const AcademyModel._internal({
    required this.id,
    required code,
    required name,
    address,
    phone,
    description,
    createdAt,
    updatedAt
  }): _code = code,
      _name = name,
      _address = address,
      _phone = phone,
      _description = description,
      _createdAt = createdAt,
      _updatedAt = updatedAt;

  factory AcademyModel({
    String? id,
    required String code,
    required String name,
    String? address,
    String? phone,
    String? description,
    amplify_core.TemporalDateTime? createdAt,
    amplify_core.TemporalDateTime? updatedAt
  }) {
    return AcademyModel._internal(
      id: id == null ? amplify_core.UUID.getUUID() : id,
      code: code,
      name: name,
      address: address,
      phone: phone,
      description: description,
      createdAt: createdAt,
      updatedAt: updatedAt);
  }

  bool equals(Object other) {
    return this == other;
  }

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is AcademyModel &&
      id == other.id &&
      _code == other._code &&
      _name == other._name &&
      _address == other._address &&
      _phone == other._phone &&
      _description == other._description &&
      _createdAt == other._createdAt &&
      _updatedAt == other._updatedAt;
  }

  @override
  int get hashCode => toString().hashCode;

  @override
  String toString() {
    var buffer = new StringBuffer();

    buffer.write("AcademyModel {");
    buffer.write("id=" + "$id" + ", ");
    buffer.write("code=" + "$_code" + ", ");
    buffer.write("name=" + "$_name" + ", ");
    buffer.write("address=" + "$_address" + ", ");
    buffer.write("phone=" + "$_phone" + ", ");
    buffer.write("description=" + "$_description" + ", ");
    buffer.write("createdAt=" + (_createdAt != null ? _createdAt!.format() : "null") + ", ");
    buffer.write("updatedAt=" + (_updatedAt != null ? _updatedAt!.format() : "null"));
    buffer.write("}");

    return buffer.toString();
  }

  AcademyModel copyWith({
    String? code,
    String? name,
    String? address,
    String? phone,
    String? description,
    amplify_core.TemporalDateTime? createdAt,
    amplify_core.TemporalDateTime? updatedAt
  }) {
    return AcademyModel._internal(
      id: id,
      code: code ?? this.code,
      name: name ?? this.name,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt);
  }

  AcademyModel.fromJson(Map<String, dynamic> json)
    : id = json['id'],
      _code = json['code'],
      _name = json['name'],
      _address = json['address'],
      _phone = json['phone'],
      _description = json['description'],
      _createdAt = json['createdAt'] != null ? amplify_core.TemporalDateTime.fromString(json['createdAt']) : null,
      _updatedAt = json['updatedAt'] != null ? amplify_core.TemporalDateTime.fromString(json['updatedAt']) : null;

  Map<String, dynamic> toJson() => {
    'id': id,
    'code': _code,
    'name': _name,
    'address': _address,
    'phone': _phone,
    'description': _description,
    'createdAt': _createdAt?.format(),
    'updatedAt': _updatedAt?.format()
  };

  Map<String, Object?> toMap() => {
    'id': id,
    'code': _code,
    'name': _name,
    'address': _address,
    'phone': _phone,
    'description': _description,
    'createdAt': _createdAt,
    'updatedAt': _updatedAt
  };

  static final amplify_core.QueryModelIdentifier<AcademyModelModelIdentifier> MODEL_IDENTIFIER = amplify_core.QueryModelIdentifier<AcademyModelModelIdentifier>();
  static final ID = amplify_core.QueryField(fieldName: "id");
  static final CODE = amplify_core.QueryField(fieldName: "code");
  static final NAME = amplify_core.QueryField(fieldName: "name");
  static final ADDRESS = amplify_core.QueryField(fieldName: "address");
  static final PHONE = amplify_core.QueryField(fieldName: "phone");
  static final DESCRIPTION = amplify_core.QueryField(fieldName: "description");
  static final CREATEDAT = amplify_core.QueryField(fieldName: "createdAt");
  static final UPDATEDAT = amplify_core.QueryField(fieldName: "updatedAt");

  static var schema = amplify_core.Model.defineSchema(define: (amplify_core.ModelSchemaDefinition modelSchemaDefinition) {
    modelSchemaDefinition.name = "Academy";
    modelSchemaDefinition.pluralName = "Academies";

    modelSchemaDefinition.authRules = [
      amplify_core.AuthRule(
        authStrategy: amplify_core.AuthStrategy.GROUPS,
        groupClaim: "cognito:groups",
        groups: [ "users" ],
        provider: amplify_core.AuthRuleProvider.USERPOOLS,
        operations: const [
          amplify_core.ModelOperation.READ
        ])
    ];

    modelSchemaDefinition.indexes = [
      amplify_core.ModelIndex(fields: const ["code"], name: "byCode")
    ];

    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.id());

    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: AcademyModel.CODE,
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));

    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: AcademyModel.NAME,
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));

    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: AcademyModel.ADDRESS,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));

    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: AcademyModel.PHONE,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));

    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: AcademyModel.DESCRIPTION,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));

    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: AcademyModel.CREATEDAT,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.dateTime)
    ));

    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: AcademyModel.UPDATEDAT,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.dateTime)
    ));
  });
}

class _AcademyModelModelType extends amplify_core.ModelType<AcademyModel> {
  const _AcademyModelModelType();

  @override
  AcademyModel fromJson(Map<String, dynamic> jsonData) {
    return AcademyModel.fromJson(jsonData);
  }

  @override
  String modelName() {
    return 'Academy';
  }
}

/**
 * This is an auto generated class representing the model identifier
 * of [AcademyModel] in your schema.
 */
class AcademyModelModelIdentifier implements amplify_core.ModelIdentifier<AcademyModel> {
  final String id;

  /** Create an instance of AcademyModelModelIdentifier using [id] the primary key. */
  const AcademyModelModelIdentifier({
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
  String toString() => 'AcademyModelModelIdentifier(id: $id)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is AcademyModelModelIdentifier &&
      id == other.id;
  }

  @override
  int get hashCode =>
    id.hashCode;
}
