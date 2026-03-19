import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/student_model.dart';
import '../providers/auth_provider.dart';
import '../providers/student_provider.dart';
import '../utils/app_constants.dart';
import '../widgets/error_state.dart';
import '../widgets/filter_loading_overlay.dart';
import '../widgets/loading_state.dart';
import '../widgets/stats_card.dart';
import '../widgets/student_card.dart';
import 'analytics_screen.dart';
import 'login_screen.dart';
import 'student_detail_screen.dart';
import 'student_group_screen.dart';
import 'student_upsert_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  static const String routeName = '/dashboard';

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounceTimer;
  Timer? _filterLoadingTimer;

  bool _isFiltering = false;
  String _filterLoadingMessage = 'Đang áp dụng bộ lọc...';

  @override
  void dispose() {
    _searchDebounceTimer?.cancel();
    _filterLoadingTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _startFilterLoading(String message) {
    _filterLoadingTimer?.cancel();

    if (!_isFiltering || _filterLoadingMessage != message) {
      setState(() {
        _isFiltering = true;
        _filterLoadingMessage = message;
      });
    }

    _filterLoadingTimer = Timer(const Duration(milliseconds: 260), () {
      if (!mounted) {
        return;
      }

      setState(() {
        _isFiltering = false;
      });
    });
  }

  void _handleSearchChanged(StudentProvider provider, String value) {
    _searchDebounceTimer?.cancel();
    _startFilterLoading('Đang tìm kiếm sinh viên...');

    _searchDebounceTimer = Timer(const Duration(milliseconds: 220), () {
      provider.setSearchQuery(value);
    });
  }

  void _clearSearch(StudentProvider provider) {
    _searchDebounceTimer?.cancel();
    _searchController.clear();
    _startFilterLoading('Đang tải lại danh sách...');
    provider.setSearchQuery('');
  }

  void _handleFacultyFilterChange(StudentProvider provider, String? value) {
    _startFilterLoading('Đang lọc theo khoa...');
    provider.setFacultyFilter(value);
  }

  void _handleCourseFilterChange(StudentProvider provider, String? value) {
    _startFilterLoading('Đang lọc theo khóa...');
    provider.setCourseFilter(value);
  }

  void _handleGpaFilterChange(StudentProvider provider, double value) {
    _startFilterLoading('Đang lọc theo GPA...');
    provider.setMinGpaFilter(value);
  }

  Future<void> _openScholarshipStudents() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            const StudentGroupScreen(groupType: StudentGroupType.scholarship),
      ),
    );
  }

  Future<void> _openWarningStudents() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            const StudentGroupScreen(groupType: StudentGroupType.warning),
      ),
    );
  }

  Future<void> _logout() async {
    await context.read<AuthProvider>().logout();
    if (!mounted) {
      return;
    }

    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(LoginScreen.routeName, (_) => false);
  }

  Future<void> _openCall(String phone) async {
    if (phone.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không tìm thấy số điện thoại.')),
      );
      return;
    }

    final Uri uri = Uri(scheme: 'tel', path: phone.trim());
    try {
      final bool launched = await launchUrl(uri);
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể thực hiện cuộc gọi.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể thực hiện cuộc gọi.')),
        );
      }
    }
  }

  Future<void> _confirmDelete(StudentModel student) async {
    final bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Xóa sinh viên'),
          content: Text(
            'Bạn có chắc muốn xóa ${student.name} (${student.mssv})?',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red.shade700,
              ),
              child: const Text('Xóa'),
            ),
          ],
        );
      },
    );

    if (!mounted || shouldDelete != true) {
      return;
    }

    final String? error = await context.read<StudentProvider>().deleteStudent(
      student.id,
    );
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error ?? 'Đã xóa sinh viên thành công.'),
        backgroundColor: error == null ? Colors.green : Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final StudentProvider provider = context.watch<StudentProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF3F7FC),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          provider.clearSelectedStudent();
          Navigator.of(context).pushNamed(StudentUpsertScreen.routeName);
        },
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Thêm sinh viên'),
      ),
      body: StreamBuilder<List<StudentModel>>(
        stream: context.read<StudentProvider>().studentsStream,
        builder:
            (BuildContext context, AsyncSnapshot<List<StudentModel>> snapshot) {
              final List<StudentModel> students =
                  snapshot.data ?? provider.students;

              if (snapshot.connectionState == ConnectionState.waiting &&
                  students.isEmpty) {
                return const LoadingState(
                  message: 'Đang tải danh sách sinh viên...',
                );
              }

              if (snapshot.hasError) {
                return ErrorState(message: snapshot.error.toString());
              }

              provider.setStudentsFromSnapshot(students);
              final List<StudentModel> filteredStudents =
                  provider.filteredStudents;

              return CustomScrollView(
                slivers: <Widget>[
                  SliverAppBar(
                    pinned: true,
                    expandedHeight: 120,
                    backgroundColor: const Color(0xFF0F5FAF),
                    foregroundColor: Colors.white,
                    title: const Text(AppConstants.appTitle),
                    actions: <Widget>[
                      IconButton(
                        onPressed: () => Navigator.of(
                          context,
                        ).pushNamed(AnalyticsScreen.routeName),
                        icon: const Icon(Icons.analytics_outlined),
                        tooltip: 'Thống kê',
                      ),
                      IconButton(
                        onPressed: _logout,
                        icon: const Icon(Icons.logout),
                        tooltip: 'Đăng xuất',
                      ),
                    ],
                    flexibleSpace: FlexibleSpaceBar(
                      background: Container(
                        padding: const EdgeInsets.fromLTRB(16, 72, 16, 12),
                        alignment: Alignment.bottomLeft,
                        child: Text(
                          'Bảng điều khiển quản lý sinh viên theo thời gian thực',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _SearchBarDelegate(
                      child: Container(
                        color: const Color(0xFFF3F7FC),
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                        child: ValueListenableBuilder<TextEditingValue>(
                          valueListenable: _searchController,
                          builder:
                              (
                                BuildContext context,
                                TextEditingValue value,
                                Widget? child,
                              ) {
                                return TextField(
                                  controller: _searchController,
                                  onChanged: (String inputValue) =>
                                      _handleSearchChanged(
                                        provider,
                                        inputValue,
                                      ),
                                  decoration: InputDecoration(
                                    hintText: 'Tìm theo tên hoặc MSSV',
                                    prefixIcon: const Icon(Icons.search),
                                    suffixIcon: value.text.isEmpty
                                        ? null
                                        : IconButton(
                                            onPressed: () =>
                                                _clearSearch(provider),
                                            icon: const Icon(Icons.clear),
                                          ),
                                    filled: true,
                                    fillColor: Colors.white,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                );
                              },
                        ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: _StatsSection(
                        provider: provider,
                        onScholarshipTap: _openScholarshipStudents,
                        onWarningTap: _openWarningStudents,
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
                      child: Column(
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: _FilterDropdown(
                                  title: 'Khoa',
                                  value: provider.facultyFilter,
                                  items: <String>[
                                    AppConstants.filterAll,
                                    ...AppConstants.faculties,
                                  ],
                                  onChanged: (String? value) =>
                                      _handleFacultyFilterChange(
                                        provider,
                                        value,
                                      ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _FilterDropdown(
                                  title: 'Khóa',
                                  value: provider.courseFilter,
                                  items: <String>[
                                    AppConstants.filterAll,
                                    ...AppConstants.courses,
                                  ],
                                  onChanged: (String? value) =>
                                      _handleCourseFilterChange(
                                        provider,
                                        value,
                                      ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _GpaFilterSlider(
                            value: provider.minGpaFilter,
                            onChanged: (double value) =>
                                _handleGpaFilterChange(provider, value),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_isFiltering)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
                        child: FilterLoadingOverlay(
                          message: _filterLoadingMessage,
                        ),
                      ),
                    )
                  else if (filteredStudents.isEmpty)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(child: Text('Không tìm thấy sinh viên.')),
                    )
                  else
                    SliverList.builder(
                      itemCount: filteredStudents.length,
                      itemBuilder: (BuildContext context, int index) {
                        final StudentModel student = filteredStudents[index];
                        return StudentCard(
                          student: student,
                          onTap: () {
                            provider.selectStudent(student.id);
                            Navigator.of(
                              context,
                            ).pushNamed(StudentDetailScreen.routeName);
                          },
                          onDelete: () => _confirmDelete(student),
                          onCall: () => _openCall(student.phone),
                        );
                      },
                    ),
                  const SliverToBoxAdapter(child: SizedBox(height: 90)),
                ],
              );
            },
      ),
    );
  }
}

class _StatsSection extends StatelessWidget {
  const _StatsSection({
    required this.provider,
    required this.onScholarshipTap,
    required this.onWarningTap,
  });

  final StudentProvider provider;
  final VoidCallback onScholarshipTap;
  final VoidCallback onWarningTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool isCompact = constraints.maxWidth < 680;
        if (isCompact) {
          return Column(
            children: <Widget>[
              StatsCard(
                title: 'Tổng sinh viên',
                value: provider.totalStudents.toString(),
                icon: Icons.groups,
                color: Colors.indigo,
              ),
              const SizedBox(height: 10),
              StatsCard(
                title: 'Sinh viên học bổng',
                value: provider.scholarshipStudents.toString(),
                icon: Icons.emoji_events,
                color: Colors.green,
                onTap: onScholarshipTap,
              ),
              const SizedBox(height: 10),
              StatsCard(
                title: 'Sinh viên cảnh báo',
                value: provider.warningStudents.toString(),
                icon: Icons.warning_amber,
                color: Colors.orange,
                onTap: onWarningTap,
              ),
            ],
          );
        }

        return Row(
          children: <Widget>[
            Expanded(
              child: StatsCard(
                title: 'Tổng sinh viên',
                value: provider.totalStudents.toString(),
                icon: Icons.groups,
                color: Colors.indigo,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: StatsCard(
                title: 'Sinh viên học bổng',
                value: provider.scholarshipStudents.toString(),
                icon: Icons.emoji_events,
                color: Colors.green,
                onTap: onScholarshipTap,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: StatsCard(
                title: 'Sinh viên cảnh báo',
                value: provider.warningStudents.toString(),
                icon: Icons.warning_amber,
                color: Colors.orange,
                onTap: onWarningTap,
              ),
            ),
          ],
        );
      },
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

class _GpaFilterSlider extends StatelessWidget {
  const _GpaFilterSlider({required this.value, required this.onChanged});

  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Lọc GPA tối thiểu: ${value.toStringAsFixed(2)}',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          Slider(
            value: value,
            min: 0.0,
            max: 4.0,
            divisions: 40,
            label: value.toStringAsFixed(2),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _SearchBarDelegate extends SliverPersistentHeaderDelegate {
  _SearchBarDelegate({required this.child});

  final Widget child;

  @override
  double get minExtent => 76;

  @override
  double get maxExtent => 76;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return child;
  }

  @override
  bool shouldRebuild(covariant _SearchBarDelegate oldDelegate) {
    return oldDelegate.child != child;
  }
}
