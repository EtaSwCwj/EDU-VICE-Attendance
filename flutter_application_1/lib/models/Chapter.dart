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


/** This is an auto generated class representing the Chapter type in your schema. */
class Chapter extends amplify_core.Model {
  static const classType = const _ChapterModelType();
  final String id;
  final String? _title;
  final int? _orderIndex;
  final int? _startPage;
  final int? _endPage;
  final Book? _book;
  final amplify_core.TemporalDateTime? _createdAt;
  final amplify_core.TemporalDateTime? _updatedAt;

  @override
  getInstanceType() => classType;
  
  @Deprecated('[getId] is being deprecated in favor of custom primary key feature. Use getter [modelIdentifier] to get model identifier.')
  @override
  String getId() => id;
  
  ChapterModelIdentifier get modelIdentifier {
      return ChapterModelIdentifier(
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
  
  int get orderIndex {
    try {
      return _orderIndex!;
    } catch(e) {
      throw amplify_core.AmplifyCodeGenModelException(
          amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastExceptionMessage,
          recoverySuggestion:
            amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastRecoverySuggestion,
          underlyingException: e.toString()
          );
    }
  }
  
  int? get startPage {
    return _startPage;
  }
  
  int? get endPage {
    return _endPage;
  }
  
  Book? get book {
    return _book;
  }
  
  amplify_core.TemporalDateTime? get createdAt {
    return _createdAt;
  }
  
  amplify_core.TemporalDateTime? get updatedAt {
    return _updatedAt;
  }
  
  const Chapter._internal({required this.id, required title, required orderIndex, startPage, endPage, book, createdAt, updatedAt}): _title = title, _orderIndex = orderIndex, _startPage = startPage, _endPage = endPage, _book = book, _createdAt = createdAt, _updatedAt = updatedAt;
  
  factory Chapter({String? id, required String title, required int orderIndex, int? startPage, int? endPage, Book? book, amplify_core.TemporalDateTime? createdAt, amplify_core.TemporalDateTime? updatedAt}) {
    return Chapter._internal(
      id: id == null ? amplify_core.UUID.getUUID() : id,
      title: title,
      orderIndex: orderIndex,
      startPage: startPage,
      endPage: endPage,
      book: book,
      createdAt: createdAt,
      updatedAt: updatedAt);
  }
  
  bool equals(Object other) {
    return this == other;
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is Chapter &&
      id == other.id &&
      _title == other._title &&
      _orderIndex == other._orderIndex &&
      _startPage == other._startPage &&
      _endPage == other._endPage &&
      _book == other._book &&
      _createdAt == other._createdAt &&
      _updatedAt == other._updatedAt;
  }
  
  @override
  int get hashCode => toString().hashCode;
  
  @override
  String toString() {
    var buffer = new StringBuffer();
    
    buffer.write("Chapter {");
    buffer.write("id=" + "$id" + ", ");
    buffer.write("title=" + "$_title" + ", ");
    buffer.write("orderIndex=" + (_orderIndex != null ? _orderIndex!.toString() : "null") + ", ");
    buffer.write("startPage=" + (_startPage != null ? _startPage!.toString() : "null") + ", ");
    buffer.write("endPage=" + (_endPage != null ? _endPage!.toString() : "null") + ", ");
    buffer.write("book=" + (_book != null ? _book!.toString() : "null") + ", ");
    buffer.write("createdAt=" + (_createdAt != null ? _createdAt!.format() : "null") + ", ");
    buffer.write("updatedAt=" + (_updatedAt != null ? _updatedAt!.format() : "null"));
    buffer.write("}");
    
    return buffer.toString();
  }
  
  Chapter copyWith({String? title, int? orderIndex, int? startPage, int? endPage, Book? book, amplify_core.TemporalDateTime? createdAt, amplify_core.TemporalDateTime? updatedAt}) {
    return Chapter._internal(
      id: id,
      title: title ?? this.title,
      orderIndex: orderIndex ?? this.orderIndex,
      startPage: startPage ?? this.startPage,
      endPage: endPage ?? this.endPage,
      book: book ?? this.book,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt);
  }
  
  Chapter copyWithModelFieldValues({
    ModelFieldValue<String>? title,
    ModelFieldValue<int>? orderIndex,
    ModelFieldValue<int?>? startPage,
    ModelFieldValue<int?>? endPage,
    ModelFieldValue<Book?>? book,
    ModelFieldValue<amplify_core.TemporalDateTime?>? createdAt,
    ModelFieldValue<amplify_core.TemporalDateTime?>? updatedAt
  }) {
    return Chapter._internal(
      id: id,
      title: title == null ? this.title : title.value,
      orderIndex: orderIndex == null ? this.orderIndex : orderIndex.value,
      startPage: startPage == null ? this.startPage : startPage.value,
      endPage: endPage == null ? this.endPage : endPage.value,
      book: book == null ? this.book : book.value,
      createdAt: createdAt == null ? this.createdAt : createdAt.value,
      updatedAt: updatedAt == null ? this.updatedAt : updatedAt.value
    );
  }
  
  Chapter.fromJson(Map<String, dynamic> json)  
    : id = json['id'],
      _title = json['title'],
      _orderIndex = (json['orderIndex'] as num?)?.toInt(),
      _startPage = (json['startPage'] as num?)?.toInt(),
      _endPage = (json['endPage'] as num?)?.toInt(),
      _book = json['book'] != null
        ? json['book']['serializedData'] != null
          ? Book.fromJson(new Map<String, dynamic>.from(json['book']['serializedData']))
          : Book.fromJson(new Map<String, dynamic>.from(json['book']))
        : null,
      _createdAt = json['createdAt'] != null ? amplify_core.TemporalDateTime.fromString(json['createdAt']) : null,
      _updatedAt = json['updatedAt'] != null ? amplify_core.TemporalDateTime.fromString(json['updatedAt']) : null;
  
  Map<String, dynamic> toJson() => {
    'id': id, 'title': _title, 'orderIndex': _orderIndex, 'startPage': _startPage, 'endPage': _endPage, 'book': _book?.toJson(), 'createdAt': _createdAt?.format(), 'updatedAt': _updatedAt?.format()
  };
  
  Map<String, Object?> toMap() => {
    'id': id,
    'title': _title,
    'orderIndex': _orderIndex,
    'startPage': _startPage,
    'endPage': _endPage,
    'book': _book,
    'createdAt': _createdAt,
    'updatedAt': _updatedAt
  };

  static final amplify_core.QueryModelIdentifier<ChapterModelIdentifier> MODEL_IDENTIFIER = amplify_core.QueryModelIdentifier<ChapterModelIdentifier>();
  static final ID = amplify_core.QueryField(fieldName: "id");
  static final TITLE = amplify_core.QueryField(fieldName: "title");
  static final ORDERINDEX = amplify_core.QueryField(fieldName: "orderIndex");
  static final STARTPAGE = amplify_core.QueryField(fieldName: "startPage");
  static final ENDPAGE = amplify_core.QueryField(fieldName: "endPage");
  static final BOOK = amplify_core.QueryField(
    fieldName: "book",
    fieldType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.model, ofModelName: 'Book'));
  static final CREATEDAT = amplify_core.QueryField(fieldName: "createdAt");
  static final UPDATEDAT = amplify_core.QueryField(fieldName: "updatedAt");
  static var schema = amplify_core.Model.defineSchema(define: (amplify_core.ModelSchemaDefinition modelSchemaDefinition) {
    modelSchemaDefinition.name = "Chapter";
    modelSchemaDefinition.pluralName = "Chapters";
    
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
      amplify_core.ModelIndex(fields: const ["bookId", "orderIndex"], name: "byBook")
    ];
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.id());
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Chapter.TITLE,
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Chapter.ORDERINDEX,
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.int)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Chapter.STARTPAGE,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.int)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Chapter.ENDPAGE,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.int)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.belongsTo(
      key: Chapter.BOOK,
      isRequired: false,
      targetNames: ['bookId'],
      ofModelName: 'Book'
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Chapter.CREATEDAT,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.dateTime)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Chapter.UPDATEDAT,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.dateTime)
    ));
  });
}

class _ChapterModelType extends amplify_core.ModelType<Chapter> {
  const _ChapterModelType();
  
  @override
  Chapter fromJson(Map<String, dynamic> jsonData) {
    return Chapter.fromJson(jsonData);
  }
  
  @override
  String modelName() {
    return 'Chapter';
  }
}

/**
 * This is an auto generated class representing the model identifier
 * of [Chapter] in your schema.
 */
class ChapterModelIdentifier implements amplify_core.ModelIdentifier<Chapter> {
  final String id;

  /** Create an instance of ChapterModelIdentifier using [id] the primary key. */
  const ChapterModelIdentifier({
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
  String toString() => 'ChapterModelIdentifier(id: $id)';
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    
    return other is ChapterModelIdentifier &&
      id == other.id;
  }
  
  @override
  int get hashCode =>
    id.hashCode;
}