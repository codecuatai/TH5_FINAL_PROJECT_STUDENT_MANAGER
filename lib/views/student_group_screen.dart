import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/student_model.dart';
import '../providers/student_provider.dart';
import '../utils/app_constants.dart';
import '../utils/gpa_utils.dart';
import '../widgets/error_state.dart';
import '../widgets/loading_state.dart';
import 'student_detail_screen.dart';

enum StudentGroupType { scholarship, warning }

class StudentGroupScreen extends StatefulWidget {
  const StudentGroupScreen({super.key, required this.groupType});

  final StudentGroupType groupType;

  @override
  State<StudentGroupScreen> createState() => _StudentGroupScreenState();
}

class _StudentGroupScreenState extends State<StudentGroupScreen> {
  final TextEditingController _searchController = TextEditingController();

  late final Stream<List<StudentModel>> _studentsStream;

  String _searchQuery = '';
  String? _facultyFilter;
  String? _courseFilter;

  @override
  void initState() {
    super.initState();
    _studentsStream = context.read<StudentProvider>().studentsStream;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _setSearchQuery(String query) {
    setState(() {
      _searchQuery = query.trim().toLowerCase();
    });
  }

  void _clearSearch() {
    _searchController.clear();
    _setSearchQuery('');
  }

  void _setFacultyFilter(String? value) {
    setState(() {
      _facultyFilter = _normalizeFilter(value);
    });
  }

  void _setCourseFilter(String? value) {
    setState(() {
      _courseFilter = _normalizeFilter(value);
    });
  }

  void _clearFilters() {
    setState(() {
      _facultyFilter = null;
      _courseFilter = null;
    });
  }

  String? _normalizeFilter(String? value) {
    if (value == null || value == AppConstants.filterAll) {
      return null;
    }

    return value;
  }

  bool _matchesGroup(StudentModel student) {
    switch (widget.groupType) {
      case StudentGroupType.scholarship:
        return GpaUtils.isScholarshipGpa(student.gpa4);
      case StudentGroupType.warning:
        return GpaUtils.isWarningGpa(student.gpa4);
    }
  }

  List<StudentModel> _filteredStudents(List<StudentModel> students) {
    return students.where((StudentModel student) {
      final bool matchesGroup = _matchesGroup(student);
      final bool matchesSearch =
          _searchQuery.isEmpty ||
          student.name.toLowerCase().contains(_searchQuery) ||
          student.mssv.toLowerCase().contains(_searchQuery);
      final bool matchesFaculty =
          _facultyFilter == null || student.faculty == _facultyFilter;
      final bool matchesCourse =
          _courseFilter == null || student.course == _courseFilter;

      return matchesGroup && matchesSearch && matchesFaculty && matchesCourse;
    }).toList();
  }

  String get _screenTitle {
    switch (widget.groupType) {
      case StudentGroupType.scholarship:
        return 'Danh sách sinh viên học bổng';
      case StudentGroupType.warning:
        return 'Danh sách sinh viên cảnh báo';
    }
  }

  String get _emptyMessage {
    switch (widget.groupType) {
      case StudentGroupType.scholarship:
        return 'Không có sinh viên học bổng phù hợp bộ lọc.';
      case StudentGroupType.warning:
        return 'Không có sinh viên cảnh báo phù hợp bộ lọc.';
    }
  }

  Color get _badgeColor {
    switch (widget.groupType) {
      case StudentGroupType.scholarship:
        return Colors.green;
      case StudentGroupType.warning:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F7FC),
      appBar: AppBar(title: Text(_screenTitle)),
      body: StreamBuilder<List<StudentModel>>(
        stream: _studentsStream,
        builder:
            (BuildContext context, AsyncSnapshot<List<StudentModel>> snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const LoadingState(message: 'Đang tải danh sách...');
              }

              if (snapshot.hasError) {
                return ErrorState(message: snapshot.error.toString());
              }

              final List<StudentModel> students =
                  snapshot.data ?? <StudentModel>[];
              final List<StudentModel> filteredStudents = _filteredStudents(
                students,
              );

              return Column(
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                    child: TextField(
                      controller: _searchController,
                      onChanged: _setSearchQuery,
                      decoration: InputDecoration(
                        hintText: 'Tìm theo tên hoặc MSSV',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchController.text.isEmpty
                            ? null
                            : IconButton(
                                onPressed: _clearSearch,
                                icon: const Icon(Icons.clear),
                              ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: _FilterDropdown(
                            title: 'Khoa',
                            value: _facultyFilter,
                            items: <String>[
                              AppConstants.filterAll,
                              ...AppConstants.faculties,
                            ],
                            onChanged: _setFacultyFilter,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _FilterDropdown(
                            title: 'Khóa',
                            value: _courseFilter,
                            items: <String>[
                              AppConstants.filterAll,
                              ...AppConstants.courses,
                            ],
                            onChanged: _setCourseFilter,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            'Kết quả: ${filteredStudents.length} sinh viên',
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _clearFilters,
                          icon: const Icon(Icons.filter_alt_off),
                          label: const Text('Xóa lọc'),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: filteredStudents.isEmpty
                        ? Center(
                            child: Text(
                              _emptyMessage,
                              textAlign: TextAlign.center,
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            itemCount: filteredStudents.length,
                            itemBuilder: (BuildContext context, int index) {
                              final StudentModel student =
                                  filteredStudents[index];
                              return _StudentGroupTile(
                                student: student,
                                badgeColor: _badgeColor,
                                onTap: () {
                                  context.read<StudentProvider>().selectStudent(
                                    student.id,
                                  );
                                  Navigator.of(
                                    context,
                                  ).pushNamed(StudentDetailScreen.routeName);
                                },
                              );
                            },
                          ),
                  ),
                ],
              );
            },
      ),
    );
  }
}

class _FilterDropdown extends StatelessWidget {
  const _FilterDropdown({
    required this.title,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String title;
  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final bool isFacultyFilter = title == 'Khoa';

    return DropdownButtonFormField<String>(
      initialValue: value ?? AppConstants.filterAll,
      decoration: InputDecoration(
        labelText: title,
        isDense: true,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      items: items
          .map(
            (String item) => DropdownMenuItem<String>(
              value: item,
              child: Text(
                isFacultyFilter ? AppConstants.facultyLabel(item) : item,
              ),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }
}

class _StudentGroupTile extends StatelessWidget {
  const _StudentGroupTile({
    required this.student,
    required this.badgeColor,
    required this.onTap,
  });

  final StudentModel student;
  final Color badgeColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: Colors.blueGrey.shade50,
          child: Icon(Icons.person, color: Colors.blueGrey.shade700),
        ),
        title: Text(
          student.name,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          '${student.mssv} - ${AppConstants.facultyLabel(student.faculty)} - ${student.course}',
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: badgeColor.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            student.gpa4.toStringAsFixed(2),
            style: TextStyle(color: badgeColor, fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }
}
