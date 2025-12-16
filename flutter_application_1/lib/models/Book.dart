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


/** This is an auto generated class representing the Book type in your schema. */
class Book extends amplify_core.Model {
  static const classType = const _BookModelType();
  final String id;
  final String? _title;
  final Subject? _subject;
  final Grade? _grade;
  final int? _year;
  final List<Chapter>? _chapters;
  final amplify_core.TemporalDateTime? _createdAt;
  final amplify_core.TemporalDateTime? _updatedAt;

  @override
  getInstanceType() => classType;
  
  @Deprecated('[getId] is being deprecated in favor of custom primary key feature. Use getter [modelIdentifier] to get model identifier.')
  @override
  String getId() => id;
  
  BookModelIdentifier get modelIdentifier {
      return BookModelIdentifier(
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
  
  Grade get grade {
    try {
      return _grade!;
    } catch(e) {
      throw amplify_core.AmplifyCodeGenModelException(
          amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastExceptionMessage,
          recoverySuggestion:
            amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastRecoverySuggestion,
          underlyingException: e.toString()
          );
    }
  }
  
  int? get year {
    return _year;
  }
  
  List<Chapter>? get chapters {
    return _chapters;
  }
  
  amplify_core.TemporalDateTime? get createdAt {
    return _createdAt;
  }
  
  amplify_core.TemporalDateTime? get updatedAt {
    return _updatedAt;
  }
  
  const Book._internal({required this.id, required title, required subject, required grade, year, chapters, createdAt, updatedAt}): _title = title, _subject = subject, _grade = grade, _year = year, _chapters = chapters, _createdAt = createdAt, _updatedAt = updatedAt;
  
  factory Book({String? id, required String title, required Subject subject, required Grade grade, int? year, List<Chapter>? chapters, amplify_core.TemporalDateTime? createdAt, amplify_core.TemporalDateTime? updatedAt}) {
    return Book._internal(
      id: id == null ? amplify_core.UUID.getUUID() : id,
      title: title,
      subject: subject,
      grade: grade,
      year: year,
      chapters: chapters != null ? List<Chapter>.unmodifiable(chapters) : chapters,
      createdAt: createdAt,
      updatedAt: updatedAt);
  }
  
  bool equals(Object other) {
    return this == other;
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is Book &&
      id == other.id &&
      _title == other._title &&
      _subject == other._subject &&
      _grade == other._grade &&
      _year == other._year &&
      DeepCollectionEquality().equals(_chapters, other._chapters) &&
      _createdAt == other._createdAt &&
      _updatedAt == other._updatedAt;
  }
  
  @override
  int get hashCode => toString().hashCode;
  
  @override
  String toString() {
    var buffer = new StringBuffer();
    
    buffer.write("Book {");
    buffer.write("id=" + "$id" + ", ");
    buffer.write("title=" + "$_title" + ", ");
    buffer.write("subject=" + (_subject != null ? amplify_core.enumToString(_subject)! : "null") + ", ");
    buffer.write("grade=" + (_grade != null ? amplify_core.enumToString(_grade)! : "null") + ", ");
    buffer.write("year=" + (_year != null ? _year!.toString() : "null") + ", ");
    buffer.write("createdAt=" + (_createdAt != null ? _createdAt!.format() : "null") + ", ");
    buffer.write("updatedAt=" + (_updatedAt != null ? _updatedAt!.format() : "null"));
    buffer.write("}");
    
    return buffer.toString();
  }
  
  Book copyWith({String? title, Subject? subject, Grade? grade, int? year, List<Chapter>? chapters, amplify_core.TemporalDateTime? createdAt, amplify_core.TemporalDateTime? updatedAt}) {
    return Book._internal(
      id: id,
      title: title ?? this.title,
      subject: subject ?? this.subject,
      grade: grade ?? this.grade,
      year: year ?? this.year,
      chapters: chapters ?? this.chapters,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt);
  }
  
  Book copyWithModelFieldValues({
    ModelFieldValue<String>? title,
    ModelFieldValue<Subject>? subject,
    ModelFieldValue<Grade>? grade,
    ModelFieldValue<int?>? year,
    ModelFieldValue<List<Chapter>?>? chapters,
    ModelFieldValue<amplify_core.TemporalDateTime?>? createdAt,
    ModelFieldValue<amplify_core.TemporalDateTime?>? updatedAt
  }) {
    return Book._internal(
      id: id,
      title: title == null ? this.title : title.value,
      subject: subject == null ? this.subject : subject.value,
      grade: grade == null ? this.grade : grade.value,
      year: year == null ? this.year : year.value,
      chapters: chapters == null ? this.chapters : chapters.value,
      createdAt: createdAt == null ? this.createdAt : createdAt.value,
      updatedAt: updatedAt == null ? this.updatedAt : updatedAt.value
    );
  }
  
  Book.fromJson(Map<String, dynamic> json)  
    : id = json['id'],
      _title = json['title'],
      _subject = amplify_core.enumFromString<Subject>(json['subject'], Subject.values),
      _grade = amplify_core.enumFromString<Grade>(json['grade'], Grade.values),
      _year = (json['year'] as num?)?.toInt(),
      _chapters = json['chapters']  is Map
        ? (json['chapters']['items'] is List
          ? (json['chapters']['items'] as List)
              .where((e) => e != null)
              .map((e) => Chapter.fromJson(new Map<String, dynamic>.from(e)))
              .toList()
          : null)
        : (json['chapters'] is List
          ? (json['chapters'] as List)
              .where((e) => e?['serializedData'] != null)
              .map((e) => Chapter.fromJson(new Map<String, dynamic>.from(e?['serializedData'])))
              .toList()
          : null),
      _createdAt = json['createdAt'] != null ? amplify_core.TemporalDateTime.fromString(json['createdAt']) : null,
      _updatedAt = json['updatedAt'] != null ? amplify_core.TemporalDateTime.fromString(json['updatedAt']) : null;
  
  Map<String, dynamic> toJson() => {
    'id': id, 'title': _title, 'subject': amplify_core.enumToString(_subject), 'grade': amplify_core.enumToString(_grade), 'year': _year, 'chapters': _chapters?.map((Chapter? e) => e?.toJson()).toList(), 'createdAt': _createdAt?.format(), 'updatedAt': _updatedAt?.format()
  };
  
  Map<String, Object?> toMap() => {
    'id': id,
    'title': _title,
    'subject': _subject,
    'grade': _grade,
    'year': _year,
    'chapters': _chapters,
    'createdAt': _createdAt,
    'updatedAt': _updatedAt
  };

  static final amplify_core.QueryModelIdentifier<BookModelIdentifier> MODEL_IDENTIFIER = amplify_core.QueryModelIdentifier<BookModelIdentifier>();
  static final ID = amplify_core.QueryField(fieldName: "id");
  static final TITLE = amplify_core.QueryField(fieldName: "title");
  static final SUBJECT = amplify_core.QueryField(fieldName: "subject");
  static final GRADE = amplify_core.QueryField(fieldName: "grade");
  static final YEAR = amplify_core.QueryField(fieldName: "year");
  static final CHAPTERS = amplify_core.QueryField(
    fieldName: "chapters",
    fieldType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.model, ofModelName: 'Chapter'));
  static final CREATEDAT = amplify_core.QueryField(fieldName: "createdAt");
  static final UPDATEDAT = amplify_core.QueryField(fieldName: "updatedAt");
  static var schema = amplify_core.Model.defineSchema(define: (amplify_core.ModelSchemaDefinition modelSchemaDefinition) {
    modelSchemaDefinition.name = "Book";
    modelSchemaDefinition.pluralName = "Books";
    
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
      amplify_core.ModelIndex(fields: const ["subject"], name: "bySubject"),
      amplify_core.ModelIndex(fields: const ["grade"], name: "byGrade")
    ];
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.id());
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Book.TITLE,
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Book.SUBJECT,
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.enumeration)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Book.GRADE,
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.enumeration)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Book.YEAR,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.int)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.hasMany(
      key: Book.CHAPTERS,
      isRequired: false,
      ofModelName: 'Chapter',
      associatedKey: Chapter.BOOK
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Book.CREATEDAT,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.dateTime)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Book.UPDATEDAT,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.dateTime)
    ));
  });
}

class _BookModelType extends amplify_core.ModelType<Book> {
  const _BookModelType();
  
  @override
  Book fromJson(Map<String, dynamic> jsonData) {
    return Book.fromJson(jsonData);
  }
  
  @override
  String modelName() {
    return 'Book';
  }
}

/**
 * This is an auto generated class representing the model identifier
 * of [Book] in your schema.
 */
class BookModelIdentifier implements amplify_core.ModelIdentifier<Book> {
  final String id;

  /** Create an instance of BookModelIdentifier using [id] the primary key. */
  const BookModelIdentifier({
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
  String toString() => 'BookModelIdentifier(id: $id)';
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    
    return other is BookModelIdentifier &&
      id == other.id;
  }
  
  @override
  int get hashCode =>
    id.hashCode;
}