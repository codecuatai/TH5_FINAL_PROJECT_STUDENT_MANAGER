import '../models/student_model.dart';
import '../models/subject_model.dart';

class GpaUtils {
  const GpaUtils._();

  static double calculateGpa10(List<SubjectModel> subjects) {
    if (subjects.isEmpty) {
      return 0;
    }

    double totalWeightedScore = 0;
    int totalCredits = 0;

    for (final SubjectModel subject in subjects) {
      totalWeightedScore += subject.score * subject.credits;
      totalCredits += subject.credits;
    }

    if (totalCredits == 0) {
      return 0;
    }

    return double.parse((totalWeightedScore / totalCredits).toStringAsFixed(2));
  }

  static double convert10To4(double gpa10) {
    if (gpa10 >= 8.5) {
      return 4.0;
    }
    if (gpa10 >= 8.0) {
      return 3.5;
    }
    if (gpa10 >= 7.0) {
      return 3.0;
    }
    if (gpa10 >= 6.5) {
      return 2.5;
    }
    if (gpa10 >= 5.5) {
      return 2.0;
    }
    if (gpa10 >= 5.0) {
      return 1.5;
    }
    if (gpa10 >= 4.0) {
      return 1.0;
    }

    return 0.0;
  }

  static String academicLevelFromGpa4(double gpa4) {
    if (gpa4 >= 3.6) {
      return 'Excellent';
    }
    if (gpa4 >= 2.5) {
      return 'Good';
    }
    return 'Average';
  }

  static Map<String, int> gradeDistribution(List<SubjectModel> subjects) {
    final Map<String, int> distribution = <String, int>{
      'A': 0,
      'B': 0,
      'C': 0,
      'D': 0,
      'F': 0,
    };

    for (final SubjectModel subject in subjects) {
      final double score = subject.score;
      if (score >= 8.5) {
        distribution['A'] = (distribution['A'] ?? 0) + 1;
      } else if (score >= 7.0) {
        distribution['B'] = (distribution['B'] ?? 0) + 1;
      } else if (score >= 5.5) {
        distribution['C'] = (distribution['C'] ?? 0) + 1;
      } else if (score >= 4.0) {
        distribution['D'] = (distribution['D'] ?? 0) + 1;
      } else {
        distribution['F'] = (distribution['F'] ?? 0) + 1;
      }
    }

    return distribution;
  }

  static Map<String, double> semesterAverages(List<SubjectModel> subjects) {
    final Map<String, double> sumBySemester = <String, double>{};
    final Map<String, int> countBySemester = <String, int>{};

    for (final SubjectModel subject in subjects) {
      final String semester = subject.semester;
      sumBySemester[semester] = (sumBySemester[semester] ?? 0) + subject.score;
      countBySemester[semester] = (countBySemester[semester] ?? 0) + 1;
    }

    return sumBySemester.map((String semester, double totalScore) {
      final int count = countBySemester[semester] ?? 1;
      return MapEntry<String, double>(
        semester,
        double.parse((totalScore / count).toStringAsFixed(2)),
      );
    });
  }

  static Map<String, int> academicDistribution(List<StudentModel> students) {
    final Map<String, int> result = <String, int>{
      'Excellent': 0,
      'Good': 0,
      'Average': 0,
    };

    for (final StudentModel student in students) {
      final String level = academicLevelFromGpa4(student.gpa4);
      result[level] = (result[level] ?? 0) + 1;
    }

    return result;
  }
}
