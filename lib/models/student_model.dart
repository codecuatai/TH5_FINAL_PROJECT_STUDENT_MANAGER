import 'package:cloud_firestore/cloud_firestore.dart';

import 'subject_model.dart';

class StudentModel {
  const StudentModel({
    required this.id,
    required this.name,
    required this.mssv,
    required this.email,
    required this.phone,
    required this.className,
    required this.faculty,
    required this.course,
    required this.birthDate,
    required this.gpa10,
    required this.gpa4,
    required this.gender,
    required this.hasUnpaidTuition,
    this.subjects = const <SubjectModel>[],
  });

  final String id;
  final String name;
  final String mssv;
  final String email;
  final String phone;
  final String className;
  final String faculty;
  final String course;
  final DateTime birthDate;
  final double gpa10;
  final double gpa4;
  final String gender;
  final bool hasUnpaidTuition;
  final List<SubjectModel> subjects;

  StudentModel copyWith({
    String? id,
    String? name,
    String? mssv,
    String? email,
    String? phone,
    String? className,
    String? faculty,
    String? course,
    DateTime? birthDate,
    double? gpa10,
    double? gpa4,
    String? gender,
    bool? hasUnpaidTuition,
    List<SubjectModel>? subjects,
  }) {
    return StudentModel(
      id: id ?? this.id,
      name: name ?? this.name,
      mssv: mssv ?? this.mssv,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      className: className ?? this.className,
      faculty: faculty ?? this.faculty,
      course: course ?? this.course,
      birthDate: birthDate ?? this.birthDate,
      gpa10: gpa10 ?? this.gpa10,
      gpa4: gpa4 ?? this.gpa4,
      gender: gender ?? this.gender,
      hasUnpaidTuition: hasUnpaidTuition ?? this.hasUnpaidTuition,
      subjects: subjects ?? this.subjects,
    );
  }

  factory StudentModel.fromMap(Map<String, dynamic> map) {
    final dynamic rawBirthDate = map['birthDate'];
    DateTime resolvedBirthDate;
    if (rawBirthDate is Timestamp) {
      resolvedBirthDate = rawBirthDate.toDate();
    } else if (rawBirthDate is String) {
      resolvedBirthDate =
          DateTime.tryParse(rawBirthDate) ?? DateTime(2000, 1, 1);
    } else if (rawBirthDate is DateTime) {
      resolvedBirthDate = rawBirthDate;
    } else {
      resolvedBirthDate = DateTime(2000, 1, 1);
    }

    final List<SubjectModel> parsedSubjects =
        (map['subjects'] as List<dynamic>? ?? <dynamic>[])
            .whereType<Map<String, dynamic>>()
            .map(SubjectModel.fromMap)
            .toList();

    return StudentModel(
      id: (map['id'] as String?) ?? '',
      name: (map['name'] as String?) ?? '',
      mssv: (map['mssv'] as String?) ?? '',
      email: (map['email'] as String?) ?? '',
      phone: (map['phone'] as String?) ?? '',
      className: (map['className'] as String?) ?? '',
      faculty: (map['faculty'] as String?) ?? '',
      course: (map['course'] as String?) ?? 'K66',
      birthDate: resolvedBirthDate,
      gpa10: (map['gpa10'] as num?)?.toDouble() ?? 0,
      gpa4: (map['gpa4'] as num?)?.toDouble() ?? 0,
      gender: (map['gender'] as String?) ?? 'other',
      hasUnpaidTuition: (map['hasUnpaidTuition'] as bool?) ?? false,
      subjects: parsedSubjects,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'mssv': mssv,
      'email': email,
      'phone': phone,
      'className': className,
      'faculty': faculty,
      'course': course,
      'birthDate': Timestamp.fromDate(birthDate),
      'gpa10': gpa10,
      'gpa4': gpa4,
      'gender': gender,
      'hasUnpaidTuition': hasUnpaidTuition,
      'subjects': subjects.map((subject) => subject.toMap()).toList(),
    };
  }
}
