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


/** This is an auto generated class representing the TextbookChapter type in your schema. */
class TextbookChapter extends amplify_core.Model {
  static const classType = const _TextbookChapterModelType();
  final String id;
  final String? _textbookId;
  final String? _section;
  final int? _number;
  final String? _title;
  final int? _startPage;
  final int? _endPage;
  final amplify_core.TemporalDateTime? _createdAt;
  final amplify_core.TemporalDateTime? _updatedAt;

  @override
  getInstanceType() => classType;
  
  @Deprecated('[getId] is being deprecated in favor of custom primary key feature. Use getter [modelIdentifier] to get model identifier.')
  @override
  String getId() => id;
  
  TextbookChapterModelIdentifier get modelIdentifier {
      return TextbookChapterModelIdentifier(
        id: id
      );
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
  
  String? get section {
    return _section;
  }
  
  int get number {
    try {
      return _number!;
    } catch(e) {
      throw amplify_core.AmplifyCodeGenModelException(
          amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastExceptionMessage,
          recoverySuggestion:
            amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastRecoverySuggestion,
          underlyingException: e.toString()
          );
    }
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
  
  int get startPage {
    try {
      return _startPage!;
    } catch(e) {
      throw amplify_core.AmplifyCodeGenModelException(
          amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastExceptionMessage,
          recoverySuggestion:
            amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastRecoverySuggestion,
          underlyingException: e.toString()
          );
    }
  }
  
  int get endPage {
    try {
      return _endPage!;
    } catch(e) {
      throw amplify_core.AmplifyCodeGenModelException(
          amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastExceptionMessage,
          recoverySuggestion:
            amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastRecoverySuggestion,
          underlyingException: e.toString()
          );
    }
  }
  
  amplify_core.TemporalDateTime? get createdAt {
    return _createdAt;
  }
  
  amplify_core.TemporalDateTime? get updatedAt {
    return _updatedAt;
  }
  
  const TextbookChapter._internal({required this.id, required textbookId, section, required number, required title, required startPage, required endPage, createdAt, updatedAt}): _textbookId = textbookId, _section = section, _number = number, _title = title, _startPage = startPage, _endPage = endPage, _createdAt = createdAt, _updatedAt = updatedAt;
  
  factory TextbookChapter({String? id, required String textbookId, String? section, required int number, required String title, required int startPage, required int endPage, amplify_core.TemporalDateTime? createdAt, amplify_core.TemporalDateTime? updatedAt}) {
    return TextbookChapter._internal(
      id: id == null ? amplify_core.UUID.getUUID() : id,
      textbookId: textbookId,
      section: section,
      number: number,
      title: title,
      startPage: startPage,
      endPage: endPage,
      createdAt: createdAt,
      updatedAt: updatedAt);
  }
  
  bool equals(Object other) {
    return this == other;
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is TextbookChapter &&
      id == other.id &&
      _textbookId == other._textbookId &&
      _section == other._section &&
      _number == other._number &&
      _title == other._title &&
      _startPage == other._startPage &&
      _endPage == other._endPage &&
      _createdAt == other._createdAt &&
      _updatedAt == other._updatedAt;
  }
  
  @override
  int get hashCode => toString().hashCode;
  
  @override
  String toString() {
    var buffer = new StringBuffer();
    
    buffer.write("TextbookChapter {");
    buffer.write("id=" + "$id" + ", ");
    buffer.write("textbookId=" + "$_textbookId" + ", ");
    buffer.write("section=" + "$_section" + ", ");
    buffer.write("number=" + (_number != null ? _number!.toString() : "null") + ", ");
    buffer.write("title=" + "$_title" + ", ");
    buffer.write("startPage=" + (_startPage != null ? _startPage!.toString() : "null") + ", ");
    buffer.write("endPage=" + (_endPage != null ? _endPage!.toString() : "null") + ", ");
    buffer.write("createdAt=" + (_createdAt != null ? _createdAt!.format() : "null") + ", ");
    buffer.write("updatedAt=" + (_updatedAt != null ? _updatedAt!.format() : "null"));
    buffer.write("}");
    
    return buffer.toString();
  }
  
  TextbookChapter copyWith({String? textbookId, String? section, int? number, String? title, int? startPage, int? endPage, amplify_core.TemporalDateTime? createdAt, amplify_core.TemporalDateTime? updatedAt}) {
    return TextbookChapter._internal(
      id: id,
      textbookId: textbookId ?? this.textbookId,
      section: section ?? this.section,
      number: number ?? this.number,
      title: title ?? this.title,
      startPage: startPage ?? this.startPage,
      endPage: endPage ?? this.endPage,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt);
  }
  
  TextbookChapter copyWithModelFieldValues({
    ModelFieldValue<String>? textbookId,
    ModelFieldValue<String?>? section,
    ModelFieldValue<int>? number,
    ModelFieldValue<String>? title,
    ModelFieldValue<int>? startPage,
    ModelFieldValue<int>? endPage,
    ModelFieldValue<amplify_core.TemporalDateTime?>? createdAt,
    ModelFieldValue<amplify_core.TemporalDateTime?>? updatedAt
  }) {
    return TextbookChapter._internal(
      id: id,
      textbookId: textbookId == null ? this.textbookId : textbookId.value,
      section: section == null ? this.section : section.value,
      number: number == null ? this.number : number.value,
      title: title == null ? this.title : title.value,
      startPage: startPage == null ? this.startPage : startPage.value,
      endPage: endPage == null ? this.endPage : endPage.value,
      createdAt: createdAt == null ? this.createdAt : createdAt.value,
      updatedAt: updatedAt == null ? this.updatedAt : updatedAt.value
    );
  }
  
  TextbookChapter.fromJson(Map<String, dynamic> json)  
    : id = json['id'],
      _textbookId = json['textbookId'],
      _section = json['section'],
      _number = (json['number'] as num?)?.toInt(),
      _title = json['title'],
      _startPage = (json['startPage'] as num?)?.toInt(),
      _endPage = (json['endPage'] as num?)?.toInt(),
      _createdAt = json['createdAt'] != null ? amplify_core.TemporalDateTime.fromString(json['createdAt']) : null,
      _updatedAt = json['updatedAt'] != null ? amplify_core.TemporalDateTime.fromString(json['updatedAt']) : null;
  
  Map<String, dynamic> toJson() => {
    'id': id, 'textbookId': _textbookId, 'section': _section, 'number': _number, 'title': _title, 'startPage': _startPage, 'endPage': _endPage, 'createdAt': _createdAt?.format(), 'updatedAt': _updatedAt?.format()
  };
  
  Map<String, Object?> toMap() => {
    'id': id,
    'textbookId': _textbookId,
    'section': _section,
    'number': _number,
    'title': _title,
    'startPage': _startPage,
    'endPage': _endPage,
    'createdAt': _createdAt,
    'updatedAt': _updatedAt
  };

  static final amplify_core.QueryModelIdentifier<TextbookChapterModelIdentifier> MODEL_IDENTIFIER = amplify_core.QueryModelIdentifier<TextbookChapterModelIdentifier>();
  static final ID = amplify_core.QueryField(fieldName: "id");
  static final TEXTBOOKID = amplify_core.QueryField(fieldName: "textbookId");
  static final SECTION = amplify_core.QueryField(fieldName: "section");
  static final NUMBER = amplify_core.QueryField(fieldName: "number");
  static final TITLE = amplify_core.QueryField(fieldName: "title");
  static final STARTPAGE = amplify_core.QueryField(fieldName: "startPage");
  static final ENDPAGE = amplify_core.QueryField(fieldName: "endPage");
  static final CREATEDAT = amplify_core.QueryField(fieldName: "createdAt");
  static final UPDATEDAT = amplify_core.QueryField(fieldName: "updatedAt");
  static var schema = amplify_core.Model.defineSchema(define: (amplify_core.ModelSchemaDefinition modelSchemaDefinition) {
    modelSchemaDefinition.name = "TextbookChapter";
    modelSchemaDefinition.pluralName = "TextbookChapters";
    
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
        authStrategy: amplify_core.AuthStrategy.GROUPS,
        groupClaim: "cognito:groups",
        groups: [ "teachers" ],
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
      amplify_core.ModelIndex(fields: const ["textbookId", "number"], name: "byTextbook")
    ];
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.id());
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: TextbookChapter.TEXTBOOKID,
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: TextbookChapter.SECTION,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: TextbookChapter.NUMBER,
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.int)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: TextbookChapter.TITLE,
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: TextbookChapter.STARTPAGE,
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.int)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: TextbookChapter.ENDPAGE,
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.int)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: TextbookChapter.CREATEDAT,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.dateTime)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: TextbookChapter.UPDATEDAT,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.dateTime)
    ));
  });
}

class _TextbookChapterModelType extends amplify_core.ModelType<TextbookChapter> {
  const _TextbookChapterModelType();
  
  @override
  TextbookChapter fromJson(Map<String, dynamic> jsonData) {
    return TextbookChapter.fromJson(jsonData);
  }
  
  @override
  String modelName() {
    return 'TextbookChapter';
  }
}

/**
 * This is an auto generated class representing the model identifier
 * of [TextbookChapter] in your schema.
 */
class TextbookChapterModelIdentifier implements amplify_core.ModelIdentifier<TextbookChapter> {
  final String id;

  /** Create an instance of TextbookChapterModelIdentifier using [id] the primary key. */
  const TextbookChapterModelIdentifier({
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
  String toString() => 'TextbookChapterModelIdentifier(id: $id)';
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    
    return other is TextbookChapterModelIdentifier &&
      id == other.id;
  }
  
  @override
  int get hashCode =>
    id.hashCode;
}