import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/student_model.dart';
import '../providers/student_provider.dart';
import '../utils/app_constants.dart';
import '../utils/gpa_utils.dart';
import '../widgets/error_state.dart';
import '../widgets/loading_state.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  static const String routeName = '/analytics';

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  String? _facultyFilter;
  String? _courseFilter;
  String _academicFilter = AppConstants.filterAll;

  late final Stream<List<StudentModel>> _studentsStream;

  @override
  void initState() {
    super.initState();
    _studentsStream = context.read<StudentProvider>().studentsStream;
  }

  void _setFacultyFilter(String? faculty) {
    setState(() {
      _facultyFilter = _normalizeFilterValue(faculty);
    });
  }

  void _setCourseFilter(String? course) {
    setState(() {
      _courseFilter = _normalizeFilterValue(course);
    });
  }

  void _setAcademicFilter(String level) {
    setState(() {
      _academicFilter = level;
    });
  }

  void _clearFilters() {
    setState(() {
      _facultyFilter = null;
      _courseFilter = null;
      _academicFilter = AppConstants.filterAll;
    });
  }

  List<StudentModel> _applyAdvancedFilters(List<StudentModel> students) {
    return students.where((StudentModel student) {
      final bool matchesFaculty =
          _facultyFilter == null || student.faculty == _facultyFilter;
      final bool matchesCourse =
          _courseFilter == null || student.course == _courseFilter;

      final String studentAcademicLevel = GpaUtils.academicLevelFromGpa4(
        student.gpa4,
      );
      final bool matchesAcademic =
          _academicFilter == AppConstants.filterAll ||
          studentAcademicLevel == _academicFilter;

      return matchesFaculty && matchesCourse && matchesAcademic;
    }).toList();
  }

  List<StudentModel> _currentMonthBirthdays(List<StudentModel> students) {
    final DateTime now = DateTime.now();
    return students
        .where((StudentModel student) => student.birthDate.month == now.month)
        .toList();
  }

  List<StudentModel> _unpaidTuitionStudents(List<StudentModel> students) {
    return students
        .where((StudentModel student) => student.hasUnpaidTuition)
        .toList();
  }

  String? _normalizeFilterValue(String? value) {
    if (value == null || value == AppConstants.filterAll) {
      return null;
    }

    return value;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F7FC),
      appBar: AppBar(title: const Text(AppConstants.appTitle)),
      body: StreamBuilder<List<StudentModel>>(
        stream: _studentsStream,
        builder:
            (BuildContext context, AsyncSnapshot<List<StudentModel>> snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const LoadingState(message: 'Đang tải thống kê...');
              }

              if (snapshot.hasError) {
                return ErrorState(message: snapshot.error.toString());
              }

              final List<StudentModel> students =
                  snapshot.data ?? <StudentModel>[];

              final List<StudentModel> filteredStudents = _applyAdvancedFilters(
                students,
              );
              final List<StudentModel> birthdays = _currentMonthBirthdays(
                students,
              );
              final List<StudentModel> unpaidTuition = _unpaidTuitionStudents(
                students,
              );
              final Map<String, int> academicDistribution =
                  GpaUtils.academicDistribution(filteredStudents);

              return SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 900),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Thống kê và bộ lọc nâng cao',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 12),
                          _FilterPanel(
                            facultyFilter: _facultyFilter,
                            courseFilter: _courseFilter,
                            academicFilter: _academicFilter,
                            onFacultyChanged: _setFacultyFilter,
                            onCourseChanged: _setCourseFilter,
                            onAcademicChanged: _setAcademicFilter,
                            onClearFilters: _clearFilters,
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: <Widget>[
                              _MetricCard(
                                title: 'Sinh viên sau lọc',
                                value: filteredStudents.length.toString(),
                                color: Colors.indigo,
                                icon: Icons.filter_alt_outlined,
                              ),
                              _MetricCard(
                                title: 'Sinh nhật tháng này',
                                value: birthdays.length.toString(),
                                color: Colors.pink,
                                icon: Icons.cake_outlined,
                              ),
                              _MetricCard(
                                title: 'Nợ học phí',
                                value: unpaidTuition.length.toString(),
                                color: Colors.deepOrange,
                                icon: Icons.payments_outlined,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _AcademicDistributionCard(data: academicDistribution),
                          const SizedBox(height: 12),
                          _NotificationSection(
                            title: 'Sinh viên có sinh nhật trong tháng',
                            icon: Icons.cake_outlined,
                            students: birthdays,
                            emptyMessage:
                                'Không có thông báo sinh nhật tháng này.',
                          ),
                          const SizedBox(height: 12),
                          _NotificationSection(
                            title: 'Sinh viên nợ học phí',
                            icon: Icons.warning_amber_outlined,
                            students: unpaidTuition,
                            emptyMessage: 'Không có thông báo nợ học phí.',
                          ),
                          const SizedBox(height: 12),
                          _FilteredStudentList(students: filteredStudents),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
      ),
    );
  }
}

class _FilterPanel extends StatelessWidget {
  const _FilterPanel({
    required this.facultyFilter,
    required this.courseFilter,
    required this.academicFilter,
    required this.onFacultyChanged,
    required this.onCourseChanged,
    required this.onAcademicChanged,
    required this.onClearFilters,
  });

  final String? facultyFilter;
  final String? courseFilter;
  final String academicFilter;
  final ValueChanged<String?> onFacultyChanged;
  final ValueChanged<String?> onCourseChanged;
  final ValueChanged<String> onAcademicChanged;
  final VoidCallback onClearFilters;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: facultyFilter ?? AppConstants.filterAll,
                  decoration: const InputDecoration(
                    labelText: 'Khoa',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items:
                      <String>[
                            AppConstants.filterAll,
                            ...AppConstants.faculties,
                          ]
                          .map(
                            (String value) => DropdownMenuItem<String>(
                              value: value,
                              child: Text(AppConstants.facultyLabel(value)),
                            ),
                          )
                          .toList(),
                  onChanged: onFacultyChanged,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: courseFilter ?? AppConstants.filterAll,
                  decoration: const InputDecoration(
                    labelText: 'Khóa',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items:
                      <String>[AppConstants.filterAll, ...AppConstants.courses]
                          .map(
                            (String value) => DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            ),
                          )
                          .toList(),
                  onChanged: onCourseChanged,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: academicFilter,
                  decoration: const InputDecoration(
                    labelText: 'Học lực',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: AppConstants.academicLevels
                      .map(
                        (String value) => DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        ),
                      )
                      .toList(),
                  onChanged: (String? value) {
                    if (value == null) {
                      return;
                    }
                    onAcademicChanged(value);
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onClearFilters,
                  icon: const Icon(Icons.filter_alt_off),
                  label: const Text('Xóa bộ lọc'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String title;
  final String value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: <Widget>[
          CircleAvatar(
            radius: 20,
            backgroundColor: color.withValues(alpha: 0.15),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(title, style: TextStyle(color: Colors.blueGrey.shade700)),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AcademicDistributionCard extends StatelessWidget {
  const _AcademicDistributionCard({required this.data});

  final Map<String, int> data;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Phân bố học lực',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: data.entries
                .map(
                  (MapEntry<String, int> entry) => Chip(
                    label: Text('${entry.key}: ${entry.value}'),
                    avatar: CircleAvatar(
                      backgroundColor: entry.key == 'Xuất sắc'
                          ? Colors.blue
                          : entry.key == 'Giỏi'
                          ? Colors.indigo
                          : entry.key == 'Khá'
                          ? Colors.green
                          : entry.key == 'Trung bình'
                          ? Colors.orange
                          : Colors.red,
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _NotificationSection extends StatelessWidget {
  const _NotificationSection({
    required this.title,
    required this.icon,
    required this.students,
    required this.emptyMessage,
  });

  final String title;
  final IconData icon;
  final List<StudentModel> students;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    final DateFormat dateFormat = DateFormat('dd/MM/yyyy');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(icon),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (students.isEmpty)
            Text(emptyMessage)
          else
            ...students.map(
              (StudentModel student) => ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(student.name),
                subtitle: Text('${student.mssv} - ${student.className}'),
                trailing: Text(dateFormat.format(student.birthDate)),
              ),
            ),
        ],
      ),
    );
  }
}

class _FilteredStudentList extends StatelessWidget {
  const _FilteredStudentList({required this.students});

  final List<StudentModel> students;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Xem trước sinh viên sau lọc',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          if (students.isEmpty)
            const Text('Không có sinh viên nào khớp bộ lọc hiện tại.')
          else
            ...students
                .take(10)
                .map(
                  (StudentModel student) => ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(student.name),
                    subtitle: Text(
                      '${student.mssv} - ${AppConstants.facultyLabel(student.faculty)} - ${student.course}',
                    ),
                    trailing: Text(student.gpa4.toStringAsFixed(2)),
                  ),
                ),
        ],
      ),
    );
  }
}
