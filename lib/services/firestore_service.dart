import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/student_model.dart';
import '../models/subject_model.dart';

class FirestoreService {
  FirestoreService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _studentsRef =>
      _firestore.collection('students');

  Stream<List<StudentModel>> streamStudents() {
    try {
      return _studentsRef.orderBy('name').snapshots().map((
        QuerySnapshot<Map<String, dynamic>> snapshot,
      ) {
        return snapshot.docs.map((
          QueryDocumentSnapshot<Map<String, dynamic>> doc,
        ) {
          final Map<String, dynamic> data = doc.data();
          data['id'] ??= doc.id;
          return StudentModel.fromMap(data);
        }).toList();
      });
    } catch (error) {
      return Stream<List<StudentModel>>.error(
        Exception('Không thể tải danh sách sinh viên: $error'),
      );
    }
  }

  Future<StudentModel?> getStudentById(String studentId) async {
    try {
      final DocumentSnapshot<Map<String, dynamic>> snapshot = await _studentsRef
          .doc(studentId)
          .get();
      if (!snapshot.exists || snapshot.data() == null) {
        return null;
      }

      final Map<String, dynamic> data = snapshot.data()!;
      data['id'] ??= snapshot.id;
      return StudentModel.fromMap(data);
    } catch (error) {
      throw Exception('Không thể lấy thông tin sinh viên: $error');
    }
  }

  Future<void> upsertStudent(StudentModel student) async {
    try {
      await _studentsRef
          .doc(student.id)
          .set(
            student.toMap()..addAll(<String, dynamic>{
              'updatedAt': FieldValue.serverTimestamp(),
            }),
            SetOptions(merge: true),
          );
    } catch (error) {
      throw Exception('Không thể lưu sinh viên: $error');
    }
  }

  Future<void> deleteStudent(String studentId) async {
    try {
      final CollectionReference<Map<String, dynamic>> subjectsRef = _studentsRef
          .doc(studentId)
          .collection('subjects');
      final QuerySnapshot<Map<String, dynamic>> subjectSnapshots =
          await subjectsRef.get();

      final WriteBatch batch = _firestore.batch();
      for (final QueryDocumentSnapshot<Map<String, dynamic>> doc
          in subjectSnapshots.docs) {
        batch.delete(doc.reference);
      }
      batch.delete(_studentsRef.doc(studentId));
      await batch.commit();
    } catch (error) {
      throw Exception('Không thể xóa sinh viên: $error');
    }
  }

  Future<bool> isMssvUnique({
    required String mssv,
    String? excludeStudentId,
  }) async {
    try {
      final QuerySnapshot<Map<String, dynamic>> snapshot = await _studentsRef
          .where('mssv', isEqualTo: mssv.trim())
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        return true;
      }

      if (excludeStudentId != null &&
          snapshot.docs.first.id == excludeStudentId) {
        return true;
      }

      return false;
    } catch (error) {
      throw Exception('Không thể kiểm tra MSSV: $error');
    }
  }

  Stream<List<SubjectModel>> streamSubjects(String studentId) {
    try {
      return _studentsRef
          .doc(studentId)
          .collection('subjects')
          .orderBy('semester')
          .snapshots()
          .map((QuerySnapshot<Map<String, dynamic>> snapshot) {
            return snapshot.docs.map((
              QueryDocumentSnapshot<Map<String, dynamic>> doc,
            ) {
              final Map<String, dynamic> data = doc.data();
              data['id'] ??= doc.id;
              return SubjectModel.fromMap(data);
            }).toList();
          });
    } catch (error) {
      return Stream<List<SubjectModel>>.error(
        Exception('Không thể tải danh sách môn học: $error'),
      );
    }
  }

  Future<List<SubjectModel>> getSubjects(String studentId) async {
    try {
      final QuerySnapshot<Map<String, dynamic>> snapshot = await _studentsRef
          .doc(studentId)
          .collection('subjects')
          .orderBy('semester')
          .get();

      return snapshot.docs.map((
        QueryDocumentSnapshot<Map<String, dynamic>> doc,
      ) {
        final Map<String, dynamic> data = doc.data();
        data['id'] ??= doc.id;
        return SubjectModel.fromMap(data);
      }).toList();
    } catch (error) {
      throw Exception('Không thể lấy danh sách môn học: $error');
    }
  }

  Future<void> upsertSubject({
    required String studentId,
    required SubjectModel subject,
  }) async {
    try {
      await _studentsRef
          .doc(studentId)
          .collection('subjects')
          .doc(subject.id)
          .set(subject.toMap(), SetOptions(merge: true));
    } catch (error) {
      throw Exception('Không thể lưu môn học: $error');
    }
  }

  Future<void> deleteSubject({
    required String studentId,
    required String subjectId,
  }) async {
    try {
      await _studentsRef
          .doc(studentId)
          .collection('subjects')
          .doc(subjectId)
          .delete();
    } catch (error) {
      throw Exception('Không thể xóa môn học: $error');
    }
  }

  Future<void> updateStudentGpa({
    required String studentId,
    required double gpa10,
    required double gpa4,
  }) async {
    try {
      await _studentsRef.doc(studentId).set(<String, dynamic>{
        'gpa10': gpa10,
        'gpa4': gpa4,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (error) {
      throw Exception('Không thể cập nhật GPA: $error');
    }
  }
}
