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


/** This is an auto generated class representing the Problem type in your schema. */
class Problem extends amplify_core.Model {
  static const classType = const _ProblemModelType();
  final String id;
  final String? _textbookId;
  final String? _chapterId;
  final String? _typeId;
  final int? _page;
  final String? _number;
  final Difficulty? _difficulty;
  final ProblemCategory? _category;
  final String? _question;
  final String? _answer;
  final List<String>? _concepts;
  final String? _imageUrl;
  final amplify_core.TemporalDateTime? _createdAt;
  final amplify_core.TemporalDateTime? _updatedAt;

  @override
  getInstanceType() => classType;
  
  @Deprecated('[getId] is being deprecated in favor of custom primary key feature. Use getter [modelIdentifier] to get model identifier.')
  @override
  String getId() => id;
  
  ProblemModelIdentifier get modelIdentifier {
      return ProblemModelIdentifier(
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
  
  String? get typeId {
    return _typeId;
  }
  
  int get page {
    try {
      return _page!;
    } catch(e) {
      throw amplify_core.AmplifyCodeGenModelException(
          amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastExceptionMessage,
          recoverySuggestion:
            amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastRecoverySuggestion,
          underlyingException: e.toString()
          );
    }
  }
  
  String get number {
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
  
  Difficulty get difficulty {
    try {
      return _difficulty!;
    } catch(e) {
      throw amplify_core.AmplifyCodeGenModelException(
          amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastExceptionMessage,
          recoverySuggestion:
            amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastRecoverySuggestion,
          underlyingException: e.toString()
          );
    }
  }
  
  ProblemCategory get category {
    try {
      return _category!;
    } catch(e) {
      throw amplify_core.AmplifyCodeGenModelException(
          amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastExceptionMessage,
          recoverySuggestion:
            amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastRecoverySuggestion,
          underlyingException: e.toString()
          );
    }
  }
  
  String? get question {
    return _question;
  }
  
  String get answer {
    try {
      return _answer!;
    } catch(e) {
      throw amplify_core.AmplifyCodeGenModelException(
          amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastExceptionMessage,
          recoverySuggestion:
            amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastRecoverySuggestion,
          underlyingException: e.toString()
          );
    }
  }
  
  List<String>? get concepts {
    return _concepts;
  }
  
  String? get imageUrl {
    return _imageUrl;
  }
  
  amplify_core.TemporalDateTime? get createdAt {
    return _createdAt;
  }
  
  amplify_core.TemporalDateTime? get updatedAt {
    return _updatedAt;
  }
  
  const Problem._internal({required this.id, required textbookId, required chapterId, typeId, required page, required number, required difficulty, required category, question, required answer, concepts, imageUrl, createdAt, updatedAt}): _textbookId = textbookId, _chapterId = chapterId, _typeId = typeId, _page = page, _number = number, _difficulty = difficulty, _category = category, _question = question, _answer = answer, _concepts = concepts, _imageUrl = imageUrl, _createdAt = createdAt, _updatedAt = updatedAt;
  
  factory Problem({String? id, required String textbookId, required String chapterId, String? typeId, required int page, required String number, required Difficulty difficulty, required ProblemCategory category, String? question, required String answer, List<String>? concepts, String? imageUrl, amplify_core.TemporalDateTime? createdAt, amplify_core.TemporalDateTime? updatedAt}) {
    return Problem._internal(
      id: id == null ? amplify_core.UUID.getUUID() : id,
      textbookId: textbookId,
      chapterId: chapterId,
      typeId: typeId,
      page: page,
      number: number,
      difficulty: difficulty,
      category: category,
      question: question,
      answer: answer,
      concepts: concepts != null ? List<String>.unmodifiable(concepts) : concepts,
      imageUrl: imageUrl,
      createdAt: createdAt,
      updatedAt: updatedAt);
  }
  
  bool equals(Object other) {
    return this == other;
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is Problem &&
      id == other.id &&
      _textbookId == other._textbookId &&
      _chapterId == other._chapterId &&
      _typeId == other._typeId &&
      _page == other._page &&
      _number == other._number &&
      _difficulty == other._difficulty &&
      _category == other._category &&
      _question == other._question &&
      _answer == other._answer &&
      DeepCollectionEquality().equals(_concepts, other._concepts) &&
      _imageUrl == other._imageUrl &&
      _createdAt == other._createdAt &&
      _updatedAt == other._updatedAt;
  }
  
  @override
  int get hashCode => toString().hashCode;
  
  @override
  String toString() {
    var buffer = new StringBuffer();
    
    buffer.write("Problem {");
    buffer.write("id=" + "$id" + ", ");
    buffer.write("textbookId=" + "$_textbookId" + ", ");
    buffer.write("chapterId=" + "$_chapterId" + ", ");
    buffer.write("typeId=" + "$_typeId" + ", ");
    buffer.write("page=" + (_page != null ? _page!.toString() : "null") + ", ");
    buffer.write("number=" + "$_number" + ", ");
    buffer.write("difficulty=" + (_difficulty != null ? amplify_core.enumToString(_difficulty)! : "null") + ", ");
    buffer.write("category=" + (_category != null ? amplify_core.enumToString(_category)! : "null") + ", ");
    buffer.write("question=" + "$_question" + ", ");
    buffer.write("answer=" + "$_answer" + ", ");
    buffer.write("concepts=" + (_concepts != null ? _concepts!.toString() : "null") + ", ");
    buffer.write("imageUrl=" + "$_imageUrl" + ", ");
    buffer.write("createdAt=" + (_createdAt != null ? _createdAt!.format() : "null") + ", ");
    buffer.write("updatedAt=" + (_updatedAt != null ? _updatedAt!.format() : "null"));
    buffer.write("}");
    
    return buffer.toString();
  }
  
  Problem copyWith({String? textbookId, String? chapterId, String? typeId, int? page, String? number, Difficulty? difficulty, ProblemCategory? category, String? question, String? answer, List<String>? concepts, String? imageUrl, amplify_core.TemporalDateTime? createdAt, amplify_core.TemporalDateTime? updatedAt}) {
    return Problem._internal(
      id: id,
      textbookId: textbookId ?? this.textbookId,
      chapterId: chapterId ?? this.chapterId,
      typeId: typeId ?? this.typeId,
      page: page ?? this.page,
      number: number ?? this.number,
      difficulty: difficulty ?? this.difficulty,
      category: category ?? this.category,
      question: question ?? this.question,
      answer: answer ?? this.answer,
      concepts: concepts ?? this.concepts,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt);
  }
  
  Problem copyWithModelFieldValues({
    ModelFieldValue<String>? textbookId,
    ModelFieldValue<String>? chapterId,
    ModelFieldValue<String?>? typeId,
    ModelFieldValue<int>? page,
    ModelFieldValue<String>? number,
    ModelFieldValue<Difficulty>? difficulty,
    ModelFieldValue<ProblemCategory>? category,
    ModelFieldValue<String?>? question,
    ModelFieldValue<String>? answer,
    ModelFieldValue<List<String>?>? concepts,
    ModelFieldValue<String?>? imageUrl,
    ModelFieldValue<amplify_core.TemporalDateTime?>? createdAt,
    ModelFieldValue<amplify_core.TemporalDateTime?>? updatedAt
  }) {
    return Problem._internal(
      id: id,
      textbookId: textbookId == null ? this.textbookId : textbookId.value,
      chapterId: chapterId == null ? this.chapterId : chapterId.value,
      typeId: typeId == null ? this.typeId : typeId.value,
      page: page == null ? this.page : page.value,
      number: number == null ? this.number : number.value,
      difficulty: difficulty == null ? this.difficulty : difficulty.value,
      category: category == null ? this.category : category.value,
      question: question == null ? this.question : question.value,
      answer: answer == null ? this.answer : answer.value,
      concepts: concepts == null ? this.concepts : concepts.value,
      imageUrl: imageUrl == null ? this.imageUrl : imageUrl.value,
      createdAt: createdAt == null ? this.createdAt : createdAt.value,
      updatedAt: updatedAt == null ? this.updatedAt : updatedAt.value
    );
  }
  
  Problem.fromJson(Map<String, dynamic> json)  
    : id = json['id'],
      _textbookId = json['textbookId'],
      _chapterId = json['chapterId'],
      _typeId = json['typeId'],
      _page = (json['page'] as num?)?.toInt(),
      _number = json['number'],
      _difficulty = amplify_core.enumFromString<Difficulty>(json['difficulty'], Difficulty.values),
      _category = amplify_core.enumFromString<ProblemCategory>(json['category'], ProblemCategory.values),
      _question = json['question'],
      _answer = json['answer'],
      _concepts = json['concepts']?.cast<String>(),
      _imageUrl = json['imageUrl'],
      _createdAt = json['createdAt'] != null ? amplify_core.TemporalDateTime.fromString(json['createdAt']) : null,
      _updatedAt = json['updatedAt'] != null ? amplify_core.TemporalDateTime.fromString(json['updatedAt']) : null;
  
  Map<String, dynamic> toJson() => {
    'id': id, 'textbookId': _textbookId, 'chapterId': _chapterId, 'typeId': _typeId, 'page': _page, 'number': _number, 'difficulty': amplify_core.enumToString(_difficulty), 'category': amplify_core.enumToString(_category), 'question': _question, 'answer': _answer, 'concepts': _concepts, 'imageUrl': _imageUrl, 'createdAt': _createdAt?.format(), 'updatedAt': _updatedAt?.format()
  };
  
  Map<String, Object?> toMap() => {
    'id': id,
    'textbookId': _textbookId,
    'chapterId': _chapterId,
    'typeId': _typeId,
    'page': _page,
    'number': _number,
    'difficulty': _difficulty,
    'category': _category,
    'question': _question,
    'answer': _answer,
    'concepts': _concepts,
    'imageUrl': _imageUrl,
    'createdAt': _createdAt,
    'updatedAt': _updatedAt
  };

  static final amplify_core.QueryModelIdentifier<ProblemModelIdentifier> MODEL_IDENTIFIER = amplify_core.QueryModelIdentifier<ProblemModelIdentifier>();
  static final ID = amplify_core.QueryField(fieldName: "id");
  static final TEXTBOOKID = amplify_core.QueryField(fieldName: "textbookId");
  static final CHAPTERID = amplify_core.QueryField(fieldName: "chapterId");
  static final TYPEID = amplify_core.QueryField(fieldName: "typeId");
  static final PAGE = amplify_core.QueryField(fieldName: "page");
  static final NUMBER = amplify_core.QueryField(fieldName: "number");
  static final DIFFICULTY = amplify_core.QueryField(fieldName: "difficulty");
  static final CATEGORY = amplify_core.QueryField(fieldName: "category");
  static final QUESTION = amplify_core.QueryField(fieldName: "question");
  static final ANSWER = amplify_core.QueryField(fieldName: "answer");
  static final CONCEPTS = amplify_core.QueryField(fieldName: "concepts");
  static final IMAGEURL = amplify_core.QueryField(fieldName: "imageUrl");
  static final CREATEDAT = amplify_core.QueryField(fieldName: "createdAt");
  static final UPDATEDAT = amplify_core.QueryField(fieldName: "updatedAt");
  static var schema = amplify_core.Model.defineSchema(define: (amplify_core.ModelSchemaDefinition modelSchemaDefinition) {
    modelSchemaDefinition.name = "Problem";
    modelSchemaDefinition.pluralName = "Problems";
    
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
      amplify_core.ModelIndex(fields: const ["textbookId"], name: "byTextbook"),
      amplify_core.ModelIndex(fields: const ["chapterId", "page"], name: "byChapter"),
      amplify_core.ModelIndex(fields: const ["typeId"], name: "byType")
    ];
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.id());
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Problem.TEXTBOOKID,
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Problem.CHAPTERID,
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Problem.TYPEID,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Problem.PAGE,
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.int)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Problem.NUMBER,
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Problem.DIFFICULTY,
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.enumeration)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Problem.CATEGORY,
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.enumeration)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Problem.QUESTION,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Problem.ANSWER,
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Problem.CONCEPTS,
      isRequired: false,
      isArray: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.collection, ofModelName: amplify_core.ModelFieldTypeEnum.string.name)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Problem.IMAGEURL,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Problem.CREATEDAT,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.dateTime)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Problem.UPDATEDAT,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.dateTime)
    ));
  });
}

class _ProblemModelType extends amplify_core.ModelType<Problem> {
  const _ProblemModelType();
  
  @override
  Problem fromJson(Map<String, dynamic> jsonData) {
    return Problem.fromJson(jsonData);
  }
  
  @override
  String modelName() {
    return 'Problem';
  }
}

/**
 * This is an auto generated class representing the model identifier
 * of [Problem] in your schema.
 */
class ProblemModelIdentifier implements amplify_core.ModelIdentifier<Problem> {
  final String id;

  /** Create an instance of ProblemModelIdentifier using [id] the primary key. */
  const ProblemModelIdentifier({
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
  String toString() => 'ProblemModelIdentifier(id: $id)';
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    
    return other is ProblemModelIdentifier &&
      id == other.id;
  }
  
  @override
  int get hashCode =>
    id.hashCode;
}