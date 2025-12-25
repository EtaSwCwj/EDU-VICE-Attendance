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

import 'package:amplify_core/amplify_core.dart' as amplify_core;
import 'Academy.dart';
import 'AcademyMember.dart';
import 'AppUser.dart';
import 'Assignment.dart';
import 'Book.dart';
import 'Chapter.dart';
import 'Invitation.dart';
import 'Lesson.dart';
import 'Problem.dart';
import 'ProblemType.dart';
import 'Student.dart';
import 'StudentProblemRecord.dart';
import 'StudentSupporter.dart';
import 'Teacher.dart';
import 'TeacherStudent.dart';
import 'Textbook.dart';
import 'TextbookChapter.dart';

export 'Academy.dart';
export 'AcademyMember.dart';
export 'AppUser.dart';
export 'Assignment.dart';
export 'AssignmentStatus.dart';
export 'Book.dart';
export 'Chapter.dart';
export 'Difficulty.dart';
export 'Grade.dart';
export 'Invitation.dart';
export 'Lesson.dart';
export 'LessonStatus.dart';
export 'Problem.dart';
export 'ProblemCategory.dart';
export 'ProblemType.dart';
export 'Student.dart';
export 'StudentProblemRecord.dart';
export 'StudentSupporter.dart';
export 'Subject.dart';
export 'Teacher.dart';
export 'TeacherStudent.dart';
export 'Textbook.dart';
export 'TextbookChapter.dart';

class ModelProvider implements amplify_core.ModelProviderInterface {
  @override
  String version = "e357f252e2dde47ae7bfc5f9b616eb89";
  @override
  List<amplify_core.ModelSchema> modelSchemas = [Academy.schema, AcademyMember.schema, AppUser.schema, Assignment.schema, Book.schema, Chapter.schema, Invitation.schema, Lesson.schema, Problem.schema, ProblemType.schema, Student.schema, StudentProblemRecord.schema, StudentSupporter.schema, Teacher.schema, TeacherStudent.schema, Textbook.schema, TextbookChapter.schema];
  @override
  List<amplify_core.ModelSchema> customTypeSchemas = [];
  static final ModelProvider _instance = ModelProvider();

  static ModelProvider get instance => _instance;
  
  amplify_core.ModelType getModelTypeByModelName(String modelName) {
    switch(modelName) {
      case "Academy":
        return Academy.classType;
      case "AcademyMember":
        return AcademyMember.classType;
      case "AppUser":
        return AppUser.classType;
      case "Assignment":
        return Assignment.classType;
      case "Book":
        return Book.classType;
      case "Chapter":
        return Chapter.classType;
      case "Invitation":
        return Invitation.classType;
      case "Lesson":
        return Lesson.classType;
      case "Problem":
        return Problem.classType;
      case "ProblemType":
        return ProblemType.classType;
      case "Student":
        return Student.classType;
      case "StudentProblemRecord":
        return StudentProblemRecord.classType;
      case "StudentSupporter":
        return StudentSupporter.classType;
      case "Teacher":
        return Teacher.classType;
      case "TeacherStudent":
        return TeacherStudent.classType;
      case "Textbook":
        return Textbook.classType;
      case "TextbookChapter":
        return TextbookChapter.classType;
      default:
        throw Exception("Failed to find model in model provider for model name: " + modelName);
    }
  }
}


class ModelFieldValue<T> {
  const ModelFieldValue.value(this.value);

  final T value;
}
