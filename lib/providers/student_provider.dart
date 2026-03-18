import 'package:flutter/foundation.dart';

import '../models/student_model.dart';
import '../models/subject_model.dart';
import '../services/firestore_service.dart';
import '../utils/gpa_utils.dart';

class StudentProvider extends ChangeNotifier {
  StudentProvider({FirestoreService? firestoreService})
    : _firestoreService = firestoreService ?? FirestoreService();

  final FirestoreService _firestoreService;

  List<StudentModel> _students = <StudentModel>[];

  String _searchQuery = '';
  String? _facultyFilter;
  String? _courseFilter;
  String _academicFilter = 'All';

  String? _selectedStudentId;
  bool _isSaving = false;
  String? _errorMessage;

  Stream<List<StudentModel>> get studentsStream =>
      _firestoreService.streamStudents();

  List<StudentModel> get students => List<StudentModel>.unmodifiable(_students);

  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;

  String get searchQuery => _searchQuery;
  String? get facultyFilter => _facultyFilter;
  String? get courseFilter => _courseFilter;
  String get academicFilter => _academicFilter;

  String? get selectedStudentId => _selectedStudentId;

  StudentModel? get selectedStudent {
    if (_selectedStudentId == null) {
      return null;
    }

    for (final StudentModel student in _students) {
      if (student.id == _selectedStudentId) {
        return student;
      }
    }

    return null;
  }

  void setStudentsFromSnapshot(List<StudentModel> students) {
    _students = students;
  }

  void setSearchQuery(String query) {
    _searchQuery = query.trim().toLowerCase();
    notifyListeners();
  }

  void setFacultyFilter(String? faculty) {
    _facultyFilter = (faculty == null || faculty == 'All') ? null : faculty;
    notifyListeners();
  }

  void setCourseFilter(String? course) {
    _courseFilter = (course == null || course == 'All') ? null : course;
    notifyListeners();
  }

  void setAcademicFilter(String level) {
    _academicFilter = level;
    notifyListeners();
  }

  void clearFilters() {
    _facultyFilter = null;
    _courseFilter = null;
    _academicFilter = 'All';
    _searchQuery = '';
    notifyListeners();
  }

  void selectStudent(String studentId) {
    _selectedStudentId = studentId;
    notifyListeners();
  }

  void clearSelectedStudent() {
    _selectedStudentId = null;
    notifyListeners();
  }

  List<StudentModel> get filteredStudents {
    return _students.where((StudentModel student) {
      final bool matchesSearch =
          _searchQuery.isEmpty ||
          student.name.toLowerCase().contains(_searchQuery) ||
          student.mssv.toLowerCase().contains(_searchQuery);

      final bool matchesFaculty =
          _facultyFilter == null || student.faculty == _facultyFilter;
      final bool matchesCourse =
          _courseFilter == null || student.course == _courseFilter;

      final String studentAcademicLevel = GpaUtils.academicLevelFromGpa4(
        student.gpa4,
      );
      final bool matchesAcademic =
          _academicFilter == 'All' || studentAcademicLevel == _academicFilter;

      return matchesSearch &&
          matchesFaculty &&
          matchesCourse &&
          matchesAcademic;
    }).toList();
  }

  int get totalStudents => _students.length;

  int get scholarshipStudents =>
      _students.where((StudentModel s) => s.gpa4 >= 3.2).length;

  int get warningStudents =>
      _students.where((StudentModel s) => s.gpa4 < 2.0).length;

  List<StudentModel> get currentMonthBirthdays {
    final DateTime now = DateTime.now();
    return _students.where((StudentModel student) {
      return student.birthDate.month == now.month;
    }).toList();
  }

  List<StudentModel> get unpaidTuitionStudents {
    return _students
        .where((StudentModel student) => student.hasUnpaidTuition)
        .toList();
  }

  Map<String, int> get academicDistribution {
    return GpaUtils.academicDistribution(filteredStudents);
  }

  Future<String?> upsertStudent(StudentModel student) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final bool isUnique = await _firestoreService.isMssvUnique(
        mssv: student.mssv,
        excludeStudentId: student.id,
      );

      if (!isUnique) {
        _errorMessage = 'MSSV already exists in the system.';
        return _errorMessage;
      }

      await _firestoreService.upsertStudent(student);
      return null;
    } catch (error) {
      _errorMessage = error.toString().replaceFirst('Exception: ', '');
      return _errorMessage;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<String?> deleteStudent(String studentId) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _firestoreService.deleteStudent(studentId);
      return null;
    } catch (error) {
      _errorMessage = error.toString().replaceFirst('Exception: ', '');
      return _errorMessage;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Stream<List<SubjectModel>> streamSubjectsByStudentId(String studentId) {
    return _firestoreService.streamSubjects(studentId);
  }

  Future<String?> upsertSubject({
    required SubjectModel subject,
    String? studentId,
  }) async {
    final String? resolvedStudentId = studentId ?? _selectedStudentId;
    if (resolvedStudentId == null) {
      return 'No student selected.';
    }

    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _firestoreService.upsertSubject(
        studentId: resolvedStudentId,
        subject: subject,
      );

      final List<SubjectModel> allSubjects = await _firestoreService
          .getSubjects(resolvedStudentId);
      await _recalculateStudentGpa(
        studentId: resolvedStudentId,
        subjects: allSubjects,
      );

      return null;
    } catch (error) {
      _errorMessage = error.toString().replaceFirst('Exception: ', '');
      return _errorMessage;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<String?> deleteSubject({
    required String subjectId,
    String? studentId,
  }) async {
    final String? resolvedStudentId = studentId ?? _selectedStudentId;
    if (resolvedStudentId == null) {
      return 'No student selected.';
    }

    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _firestoreService.deleteSubject(
        studentId: resolvedStudentId,
        subjectId: subjectId,
      );

      final List<SubjectModel> allSubjects = await _firestoreService
          .getSubjects(resolvedStudentId);
      await _recalculateStudentGpa(
        studentId: resolvedStudentId,
        subjects: allSubjects,
      );

      return null;
    } catch (error) {
      _errorMessage = error.toString().replaceFirst('Exception: ', '');
      return _errorMessage;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<void> _recalculateStudentGpa({
    required String studentId,
    required List<SubjectModel> subjects,
  }) async {
    final double gpa10 = GpaUtils.calculateGpa10(subjects);
    final double gpa4 = GpaUtils.convert10To4(gpa10);

    await _firestoreService.updateStudentGpa(
      studentId: studentId,
      gpa10: gpa10,
      gpa4: gpa4,
    );
  }
}
