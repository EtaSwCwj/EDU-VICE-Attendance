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


/** This is an auto generated class representing the AppUser type in your schema. */
class AppUser extends amplify_core.Model {
  static const classType = const _AppUserModelType();
  final String id;
  final String? _cognitoUsername;
  final String? _email;
  final String? _name;
  final String? _birthDate;
  final String? _gender;
  final String? _phone;
  final String? _profileImageUrl;
  final amplify_core.TemporalDateTime? _createdAt;
  final amplify_core.TemporalDateTime? _updatedAt;

  @override
  getInstanceType() => classType;
  
  @Deprecated('[getId] is being deprecated in favor of custom primary key feature. Use getter [modelIdentifier] to get model identifier.')
  @override
  String getId() => id;
  
  AppUserModelIdentifier get modelIdentifier {
      return AppUserModelIdentifier(
        id: id
      );
  }
  
  String get cognitoUsername {
    try {
      return _cognitoUsername!;
    } catch(e) {
      throw amplify_core.AmplifyCodeGenModelException(
          amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastExceptionMessage,
          recoverySuggestion:
            amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastRecoverySuggestion,
          underlyingException: e.toString()
          );
    }
  }
  
  String get email {
    try {
      return _email!;
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
  
  String? get birthDate {
    return _birthDate;
  }
  
  String? get gender {
    return _gender;
  }
  
  String? get phone {
    return _phone;
  }
  
  String? get profileImageUrl {
    return _profileImageUrl;
  }
  
  amplify_core.TemporalDateTime? get createdAt {
    return _createdAt;
  }
  
  amplify_core.TemporalDateTime? get updatedAt {
    return _updatedAt;
  }
  
  const AppUser._internal({required this.id, required cognitoUsername, required email, required name, birthDate, gender, phone, profileImageUrl, createdAt, updatedAt}): _cognitoUsername = cognitoUsername, _email = email, _name = name, _birthDate = birthDate, _gender = gender, _phone = phone, _profileImageUrl = profileImageUrl, _createdAt = createdAt, _updatedAt = updatedAt;
  
  factory AppUser({String? id, required String cognitoUsername, required String email, required String name, String? birthDate, String? gender, String? phone, String? profileImageUrl, amplify_core.TemporalDateTime? createdAt, amplify_core.TemporalDateTime? updatedAt}) {
    return AppUser._internal(
      id: id == null ? amplify_core.UUID.getUUID() : id,
      cognitoUsername: cognitoUsername,
      email: email,
      name: name,
      birthDate: birthDate,
      gender: gender,
      phone: phone,
      profileImageUrl: profileImageUrl,
      createdAt: createdAt,
      updatedAt: updatedAt);
  }
  
  bool equals(Object other) {
    return this == other;
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is AppUser &&
      id == other.id &&
      _cognitoUsername == other._cognitoUsername &&
      _email == other._email &&
      _name == other._name &&
      _birthDate == other._birthDate &&
      _gender == other._gender &&
      _phone == other._phone &&
      _profileImageUrl == other._profileImageUrl &&
      _createdAt == other._createdAt &&
      _updatedAt == other._updatedAt;
  }
  
  @override
  int get hashCode => toString().hashCode;
  
  @override
  String toString() {
    var buffer = new StringBuffer();
    
    buffer.write("AppUser {");
    buffer.write("id=" + "$id" + ", ");
    buffer.write("cognitoUsername=" + "$_cognitoUsername" + ", ");
    buffer.write("email=" + "$_email" + ", ");
    buffer.write("name=" + "$_name" + ", ");
    buffer.write("birthDate=" + "$_birthDate" + ", ");
    buffer.write("gender=" + "$_gender" + ", ");
    buffer.write("phone=" + "$_phone" + ", ");
    buffer.write("profileImageUrl=" + "$_profileImageUrl" + ", ");
    buffer.write("createdAt=" + (_createdAt != null ? _createdAt!.format() : "null") + ", ");
    buffer.write("updatedAt=" + (_updatedAt != null ? _updatedAt!.format() : "null"));
    buffer.write("}");
    
    return buffer.toString();
  }
  
  AppUser copyWith({String? cognitoUsername, String? email, String? name, String? birthDate, String? gender, String? phone, String? profileImageUrl, amplify_core.TemporalDateTime? createdAt, amplify_core.TemporalDateTime? updatedAt}) {
    return AppUser._internal(
      id: id,
      cognitoUsername: cognitoUsername ?? this.cognitoUsername,
      email: email ?? this.email,
      name: name ?? this.name,
      birthDate: birthDate ?? this.birthDate,
      gender: gender ?? this.gender,
      phone: phone ?? this.phone,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt);
  }
  
  AppUser copyWithModelFieldValues({
    ModelFieldValue<String>? cognitoUsername,
    ModelFieldValue<String>? email,
    ModelFieldValue<String>? name,
    ModelFieldValue<String?>? birthDate,
    ModelFieldValue<String?>? gender,
    ModelFieldValue<String?>? phone,
    ModelFieldValue<String?>? profileImageUrl,
    ModelFieldValue<amplify_core.TemporalDateTime?>? createdAt,
    ModelFieldValue<amplify_core.TemporalDateTime?>? updatedAt
  }) {
    return AppUser._internal(
      id: id,
      cognitoUsername: cognitoUsername == null ? this.cognitoUsername : cognitoUsername.value,
      email: email == null ? this.email : email.value,
      name: name == null ? this.name : name.value,
      birthDate: birthDate == null ? this.birthDate : birthDate.value,
      gender: gender == null ? this.gender : gender.value,
      phone: phone == null ? this.phone : phone.value,
      profileImageUrl: profileImageUrl == null ? this.profileImageUrl : profileImageUrl.value,
      createdAt: createdAt == null ? this.createdAt : createdAt.value,
      updatedAt: updatedAt == null ? this.updatedAt : updatedAt.value
    );
  }
  
  AppUser.fromJson(Map<String, dynamic> json)  
    : id = json['id'],
      _cognitoUsername = json['cognitoUsername'],
      _email = json['email'],
      _name = json['name'],
      _birthDate = json['birthDate'],
      _gender = json['gender'],
      _phone = json['phone'],
      _profileImageUrl = json['profileImageUrl'],
      _createdAt = json['createdAt'] != null ? amplify_core.TemporalDateTime.fromString(json['createdAt']) : null,
      _updatedAt = json['updatedAt'] != null ? amplify_core.TemporalDateTime.fromString(json['updatedAt']) : null;
  
  Map<String, dynamic> toJson() => {
    'id': id, 'cognitoUsername': _cognitoUsername, 'email': _email, 'name': _name, 'birthDate': _birthDate, 'gender': _gender, 'phone': _phone, 'profileImageUrl': _profileImageUrl, 'createdAt': _createdAt?.format(), 'updatedAt': _updatedAt?.format()
  };
  
  Map<String, Object?> toMap() => {
    'id': id,
    'cognitoUsername': _cognitoUsername,
    'email': _email,
    'name': _name,
    'birthDate': _birthDate,
    'gender': _gender,
    'phone': _phone,
    'profileImageUrl': _profileImageUrl,
    'createdAt': _createdAt,
    'updatedAt': _updatedAt
  };

  static final amplify_core.QueryModelIdentifier<AppUserModelIdentifier> MODEL_IDENTIFIER = amplify_core.QueryModelIdentifier<AppUserModelIdentifier>();
  static final ID = amplify_core.QueryField(fieldName: "id");
  static final COGNITOUSERNAME = amplify_core.QueryField(fieldName: "cognitoUsername");
  static final EMAIL = amplify_core.QueryField(fieldName: "email");
  static final NAME = amplify_core.QueryField(fieldName: "name");
  static final BIRTHDATE = amplify_core.QueryField(fieldName: "birthDate");
  static final GENDER = amplify_core.QueryField(fieldName: "gender");
  static final PHONE = amplify_core.QueryField(fieldName: "phone");
  static final PROFILEIMAGEURL = amplify_core.QueryField(fieldName: "profileImageUrl");
  static final CREATEDAT = amplify_core.QueryField(fieldName: "createdAt");
  static final UPDATEDAT = amplify_core.QueryField(fieldName: "updatedAt");
  static var schema = amplify_core.Model.defineSchema(define: (amplify_core.ModelSchemaDefinition modelSchemaDefinition) {
    modelSchemaDefinition.name = "AppUser";
    modelSchemaDefinition.pluralName = "AppUsers";
    
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
        ownerField: "cognitoUsername",
        identityClaim: "cognito:username",
        provider: amplify_core.AuthRuleProvider.USERPOOLS,
        operations: const [
          amplify_core.ModelOperation.CREATE,
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
      amplify_core.ModelIndex(fields: const ["cognitoUsername"], name: "byCognitoUsername"),
      amplify_core.ModelIndex(fields: const ["email"], name: "byEmail")
    ];
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.id());
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: AppUser.COGNITOUSERNAME,
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: AppUser.EMAIL,
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: AppUser.NAME,
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: AppUser.BIRTHDATE,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: AppUser.GENDER,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: AppUser.PHONE,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: AppUser.PROFILEIMAGEURL,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: AppUser.CREATEDAT,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.dateTime)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: AppUser.UPDATEDAT,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.dateTime)
    ));
  });
}

class _AppUserModelType extends amplify_core.ModelType<AppUser> {
  const _AppUserModelType();
  
  @override
  AppUser fromJson(Map<String, dynamic> jsonData) {
    return AppUser.fromJson(jsonData);
  }
  
  @override
  String modelName() {
    return 'AppUser';
  }
}

/**
 * This is an auto generated class representing the model identifier
 * of [AppUser] in your schema.
 */
class AppUserModelIdentifier implements amplify_core.ModelIdentifier<AppUser> {
  final String id;

  /** Create an instance of AppUserModelIdentifier using [id] the primary key. */
  const AppUserModelIdentifier({
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
  String toString() => 'AppUserModelIdentifier(id: $id)';
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    
    return other is AppUserModelIdentifier &&
      id == other.id;
  }
  
  @override
  int get hashCode =>
    id.hashCode;
}