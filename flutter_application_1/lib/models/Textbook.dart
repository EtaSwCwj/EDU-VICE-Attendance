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


/** This is an auto generated class representing the Textbook type in your schema. */
class Textbook extends amplify_core.Model {
  static const classType = const _TextbookModelType();
  final String id;
  final String? _title;
  final Subject? _subject;
  final String? _grade;
  final String? _semester;
  final String? _publisher;
  final String? _edition;
  final int? _publishYear;
  final int? _totalPages;
  final String? _coverImageUrl;
  final String? _registeredBy;
  final bool? _isVerified;
  final amplify_core.TemporalDateTime? _createdAt;
  final amplify_core.TemporalDateTime? _updatedAt;

  @override
  getInstanceType() => classType;
  
  @Deprecated('[getId] is being deprecated in favor of custom primary key feature. Use getter [modelIdentifier] to get model identifier.')
  @override
  String getId() => id;
  
  TextbookModelIdentifier get modelIdentifier {
      return TextbookModelIdentifier(
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
  
  String get grade {
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
  
  String? get semester {
    return _semester;
  }
  
  String get publisher {
    try {
      return _publisher!;
    } catch(e) {
      throw amplify_core.AmplifyCodeGenModelException(
          amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastExceptionMessage,
          recoverySuggestion:
            amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastRecoverySuggestion,
          underlyingException: e.toString()
          );
    }
  }
  
  String? get edition {
    return _edition;
  }
  
  int get publishYear {
    try {
      return _publishYear!;
    } catch(e) {
      throw amplify_core.AmplifyCodeGenModelException(
          amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastExceptionMessage,
          recoverySuggestion:
            amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastRecoverySuggestion,
          underlyingException: e.toString()
          );
    }
  }
  
  int? get totalPages {
    return _totalPages;
  }
  
  String? get coverImageUrl {
    return _coverImageUrl;
  }
  
  String? get registeredBy {
    return _registeredBy;
  }
  
  bool? get isVerified {
    return _isVerified;
  }
  
  amplify_core.TemporalDateTime? get createdAt {
    return _createdAt;
  }
  
  amplify_core.TemporalDateTime? get updatedAt {
    return _updatedAt;
  }
  
  const Textbook._internal({required this.id, required title, required subject, required grade, semester, required publisher, edition, required publishYear, totalPages, coverImageUrl, registeredBy, isVerified, createdAt, updatedAt}): _title = title, _subject = subject, _grade = grade, _semester = semester, _publisher = publisher, _edition = edition, _publishYear = publishYear, _totalPages = totalPages, _coverImageUrl = coverImageUrl, _registeredBy = registeredBy, _isVerified = isVerified, _createdAt = createdAt, _updatedAt = updatedAt;
  
  factory Textbook({String? id, required String title, required Subject subject, required String grade, String? semester, required String publisher, String? edition, required int publishYear, int? totalPages, String? coverImageUrl, String? registeredBy, bool? isVerified, amplify_core.TemporalDateTime? createdAt, amplify_core.TemporalDateTime? updatedAt}) {
    return Textbook._internal(
      id: id == null ? amplify_core.UUID.getUUID() : id,
      title: title,
      subject: subject,
      grade: grade,
      semester: semester,
      publisher: publisher,
      edition: edition,
      publishYear: publishYear,
      totalPages: totalPages,
      coverImageUrl: coverImageUrl,
      registeredBy: registeredBy,
      isVerified: isVerified,
      createdAt: createdAt,
      updatedAt: updatedAt);
  }
  
  bool equals(Object other) {
    return this == other;
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is Textbook &&
      id == other.id &&
      _title == other._title &&
      _subject == other._subject &&
      _grade == other._grade &&
      _semester == other._semester &&
      _publisher == other._publisher &&
      _edition == other._edition &&
      _publishYear == other._publishYear &&
      _totalPages == other._totalPages &&
      _coverImageUrl == other._coverImageUrl &&
      _registeredBy == other._registeredBy &&
      _isVerified == other._isVerified &&
      _createdAt == other._createdAt &&
      _updatedAt == other._updatedAt;
  }
  
  @override
  int get hashCode => toString().hashCode;
  
  @override
  String toString() {
    var buffer = new StringBuffer();
    
    buffer.write("Textbook {");
    buffer.write("id=" + "$id" + ", ");
    buffer.write("title=" + "$_title" + ", ");
    buffer.write("subject=" + (_subject != null ? amplify_core.enumToString(_subject)! : "null") + ", ");
    buffer.write("grade=" + "$_grade" + ", ");
    buffer.write("semester=" + "$_semester" + ", ");
    buffer.write("publisher=" + "$_publisher" + ", ");
    buffer.write("edition=" + "$_edition" + ", ");
    buffer.write("publishYear=" + (_publishYear != null ? _publishYear!.toString() : "null") + ", ");
    buffer.write("totalPages=" + (_totalPages != null ? _totalPages!.toString() : "null") + ", ");
    buffer.write("coverImageUrl=" + "$_coverImageUrl" + ", ");
    buffer.write("registeredBy=" + "$_registeredBy" + ", ");
    buffer.write("isVerified=" + (_isVerified != null ? _isVerified!.toString() : "null") + ", ");
    buffer.write("createdAt=" + (_createdAt != null ? _createdAt!.format() : "null") + ", ");
    buffer.write("updatedAt=" + (_updatedAt != null ? _updatedAt!.format() : "null"));
    buffer.write("}");
    
    return buffer.toString();
  }
  
  Textbook copyWith({String? title, Subject? subject, String? grade, String? semester, String? publisher, String? edition, int? publishYear, int? totalPages, String? coverImageUrl, String? registeredBy, bool? isVerified, amplify_core.TemporalDateTime? createdAt, amplify_core.TemporalDateTime? updatedAt}) {
    return Textbook._internal(
      id: id,
      title: title ?? this.title,
      subject: subject ?? this.subject,
      grade: grade ?? this.grade,
      semester: semester ?? this.semester,
      publisher: publisher ?? this.publisher,
      edition: edition ?? this.edition,
      publishYear: publishYear ?? this.publishYear,
      totalPages: totalPages ?? this.totalPages,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      registeredBy: registeredBy ?? this.registeredBy,
      isVerified: isVerified ?? this.isVerified,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt);
  }
  
  Textbook copyWithModelFieldValues({
    ModelFieldValue<String>? title,
    ModelFieldValue<Subject>? subject,
    ModelFieldValue<String>? grade,
    ModelFieldValue<String?>? semester,
    ModelFieldValue<String>? publisher,
    ModelFieldValue<String?>? edition,
    ModelFieldValue<int>? publishYear,
    ModelFieldValue<int?>? totalPages,
    ModelFieldValue<String?>? coverImageUrl,
    ModelFieldValue<String?>? registeredBy,
    ModelFieldValue<bool?>? isVerified,
    ModelFieldValue<amplify_core.TemporalDateTime?>? createdAt,
    ModelFieldValue<amplify_core.TemporalDateTime?>? updatedAt
  }) {
    return Textbook._internal(
      id: id,
      title: title == null ? this.title : title.value,
      subject: subject == null ? this.subject : subject.value,
      grade: grade == null ? this.grade : grade.value,
      semester: semester == null ? this.semester : semester.value,
      publisher: publisher == null ? this.publisher : publisher.value,
      edition: edition == null ? this.edition : edition.value,
      publishYear: publishYear == null ? this.publishYear : publishYear.value,
      totalPages: totalPages == null ? this.totalPages : totalPages.value,
      coverImageUrl: coverImageUrl == null ? this.coverImageUrl : coverImageUrl.value,
      registeredBy: registeredBy == null ? this.registeredBy : registeredBy.value,
      isVerified: isVerified == null ? this.isVerified : isVerified.value,
      createdAt: createdAt == null ? this.createdAt : createdAt.value,
      updatedAt: updatedAt == null ? this.updatedAt : updatedAt.value
    );
  }
  
  Textbook.fromJson(Map<String, dynamic> json)  
    : id = json['id'],
      _title = json['title'],
      _subject = amplify_core.enumFromString<Subject>(json['subject'], Subject.values),
      _grade = json['grade'],
      _semester = json['semester'],
      _publisher = json['publisher'],
      _edition = json['edition'],
      _publishYear = (json['publishYear'] as num?)?.toInt(),
      _totalPages = (json['totalPages'] as num?)?.toInt(),
      _coverImageUrl = json['coverImageUrl'],
      _registeredBy = json['registeredBy'],
      _isVerified = json['isVerified'],
      _createdAt = json['createdAt'] != null ? amplify_core.TemporalDateTime.fromString(json['createdAt']) : null,
      _updatedAt = json['updatedAt'] != null ? amplify_core.TemporalDateTime.fromString(json['updatedAt']) : null;
  
  Map<String, dynamic> toJson() => {
    'id': id, 'title': _title, 'subject': amplify_core.enumToString(_subject), 'grade': _grade, 'semester': _semester, 'publisher': _publisher, 'edition': _edition, 'publishYear': _publishYear, 'totalPages': _totalPages, 'coverImageUrl': _coverImageUrl, 'registeredBy': _registeredBy, 'isVerified': _isVerified, 'createdAt': _createdAt?.format(), 'updatedAt': _updatedAt?.format()
  };
  
  Map<String, Object?> toMap() => {
    'id': id,
    'title': _title,
    'subject': _subject,
    'grade': _grade,
    'semester': _semester,
    'publisher': _publisher,
    'edition': _edition,
    'publishYear': _publishYear,
    'totalPages': _totalPages,
    'coverImageUrl': _coverImageUrl,
    'registeredBy': _registeredBy,
    'isVerified': _isVerified,
    'createdAt': _createdAt,
    'updatedAt': _updatedAt
  };

  static final amplify_core.QueryModelIdentifier<TextbookModelIdentifier> MODEL_IDENTIFIER = amplify_core.QueryModelIdentifier<TextbookModelIdentifier>();
  static final ID = amplify_core.QueryField(fieldName: "id");
  static final TITLE = amplify_core.QueryField(fieldName: "title");
  static final SUBJECT = amplify_core.QueryField(fieldName: "subject");
  static final GRADE = amplify_core.QueryField(fieldName: "grade");
  static final SEMESTER = amplify_core.QueryField(fieldName: "semester");
  static final PUBLISHER = amplify_core.QueryField(fieldName: "publisher");
  static final EDITION = amplify_core.QueryField(fieldName: "edition");
  static final PUBLISHYEAR = amplify_core.QueryField(fieldName: "publishYear");
  static final TOTALPAGES = amplify_core.QueryField(fieldName: "totalPages");
  static final COVERIMAGEURL = amplify_core.QueryField(fieldName: "coverImageUrl");
  static final REGISTEREDBY = amplify_core.QueryField(fieldName: "registeredBy");
  static final ISVERIFIED = amplify_core.QueryField(fieldName: "isVerified");
  static final CREATEDAT = amplify_core.QueryField(fieldName: "createdAt");
  static final UPDATEDAT = amplify_core.QueryField(fieldName: "updatedAt");
  static var schema = amplify_core.Model.defineSchema(define: (amplify_core.ModelSchemaDefinition modelSchemaDefinition) {
    modelSchemaDefinition.name = "Textbook";
    modelSchemaDefinition.pluralName = "Textbooks";
    
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
      amplify_core.ModelIndex(fields: const ["title"], name: "byTitle"),
      amplify_core.ModelIndex(fields: const ["subject"], name: "bySubject"),
      amplify_core.ModelIndex(fields: const ["grade"], name: "byGrade")
    ];
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.id());
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Textbook.TITLE,
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Textbook.SUBJECT,
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.enumeration)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Textbook.GRADE,
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Textbook.SEMESTER,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Textbook.PUBLISHER,
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Textbook.EDITION,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Textbook.PUBLISHYEAR,
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.int)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Textbook.TOTALPAGES,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.int)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Textbook.COVERIMAGEURL,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Textbook.REGISTEREDBY,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Textbook.ISVERIFIED,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.bool)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Textbook.CREATEDAT,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.dateTime)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Textbook.UPDATEDAT,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.dateTime)
    ));
  });
}

class _TextbookModelType extends amplify_core.ModelType<Textbook> {
  const _TextbookModelType();
  
  @override
  Textbook fromJson(Map<String, dynamic> jsonData) {
    return Textbook.fromJson(jsonData);
  }
  
  @override
  String modelName() {
    return 'Textbook';
  }
}

/**
 * This is an auto generated class representing the model identifier
 * of [Textbook] in your schema.
 */
class TextbookModelIdentifier implements amplify_core.ModelIdentifier<Textbook> {
  final String id;

  /** Create an instance of TextbookModelIdentifier using [id] the primary key. */
  const TextbookModelIdentifier({
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
  String toString() => 'TextbookModelIdentifier(id: $id)';
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    
    return other is TextbookModelIdentifier &&
      id == other.id;
  }
  
  @override
  int get hashCode =>
    id.hashCode;
}