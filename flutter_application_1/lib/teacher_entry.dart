import 'package:flutter/material.dart';
import 'features/teacher/teacher_shell.dart';

/// 기존 앱 어딘가에서 Navigator.push(context, MaterialPageRoute(builder: (_) => teacherEntry()));
/// 로 진입하면 됨.
Widget teacherEntry() => const TeacherShell();
