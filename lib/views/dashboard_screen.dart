import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/student_model.dart';
import '../providers/auth_provider.dart';
import '../providers/student_provider.dart';
import '../utils/app_constants.dart';
import '../widgets/error_state.dart';
import '../widgets/loading_state.dart';
import '../widgets/stats_card.dart';
import '../widgets/student_card.dart';
import 'analytics_screen.dart';
import 'login_screen.dart';
import 'student_detail_screen.dart';
import 'student_upsert_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  static const String routeName = '/dashboard';

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No phone number found.')));
      return;
    }

    final Uri uri = Uri(scheme: 'tel', path: phone.trim());
    try {
      final bool launched = await launchUrl(uri);
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not start phone call.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not start phone call.')),
        );
      }
    }
  }

  Future<void> _confirmDelete(StudentModel student) async {
    final bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Student'),
          content: Text('Delete ${student.name} (${student.mssv})?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red.shade700,
              ),
              child: const Text('Delete'),
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
        content: Text(error ?? 'Student deleted successfully.'),
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
        label: const Text('Add Student'),
      ),
      body: StreamBuilder<List<StudentModel>>(
        stream: context.read<StudentProvider>().studentsStream,
        builder:
            (BuildContext context, AsyncSnapshot<List<StudentModel>> snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const LoadingState(message: 'Loading students...');
              }

              if (snapshot.hasError) {
                return ErrorState(message: snapshot.error.toString());
              }

              final List<StudentModel> students =
                  snapshot.data ?? <StudentModel>[];
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
                        tooltip: 'Analytics',
                      ),
                      IconButton(
                        onPressed: _logout,
                        icon: const Icon(Icons.logout),
                        tooltip: 'Logout',
                      ),
                    ],
                    flexibleSpace: FlexibleSpaceBar(
                      background: Container(
                        padding: const EdgeInsets.fromLTRB(16, 72, 16, 12),
                        alignment: Alignment.bottomLeft,
                        child: Text(
                          'Realtime Student Admin Dashboard',
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
                        child: TextField(
                          controller: _searchController,
                          onChanged: (String value) {
                            provider.setSearchQuery(value);
                            setState(() {});
                          },
                          decoration: InputDecoration(
                            hintText: 'Search by name or MSSV',
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: _searchController.text.isEmpty
                                ? null
                                : IconButton(
                                    onPressed: () {
                                      _searchController.clear();
                                      provider.setSearchQuery('');
                                      setState(() {});
                                    },
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
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: _StatsSection(provider: provider),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
                      child: Row(
                        children: <Widget>[
                          Expanded(
                            child: _FilterDropdown(
                              title: 'Faculty',
                              value: provider.facultyFilter,
                              items: <String>['All', ...AppConstants.faculties],
                              onChanged: provider.setFacultyFilter,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _FilterDropdown(
                              title: 'Course',
                              value: provider.courseFilter,
                              items: <String>['All', ...AppConstants.courses],
                              onChanged: provider.setCourseFilter,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (filteredStudents.isEmpty)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(child: Text('No students found.')),
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
  const _StatsSection({required this.provider});

  final StudentProvider provider;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool isCompact = constraints.maxWidth < 680;
        if (isCompact) {
          return Column(
            children: <Widget>[
              StatsCard(
                title: 'Total students',
                value: provider.totalStudents.toString(),
                icon: Icons.groups,
                color: Colors.indigo,
              ),
              const SizedBox(height: 10),
              StatsCard(
                title: 'Scholarship students',
                value: provider.scholarshipStudents.toString(),
                icon: Icons.emoji_events,
                color: Colors.green,
              ),
              const SizedBox(height: 10),
              StatsCard(
                title: 'Warning students',
                value: provider.warningStudents.toString(),
                icon: Icons.warning_amber,
                color: Colors.orange,
              ),
            ],
          );
        }

        return Row(
          children: <Widget>[
            Expanded(
              child: StatsCard(
                title: 'Total students',
                value: provider.totalStudents.toString(),
                icon: Icons.groups,
                color: Colors.indigo,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: StatsCard(
                title: 'Scholarship students',
                value: provider.scholarshipStudents.toString(),
                icon: Icons.emoji_events,
                color: Colors.green,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: StatsCard(
                title: 'Warning students',
                value: provider.warningStudents.toString(),
                icon: Icons.warning_amber,
                color: Colors.orange,
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
    return DropdownButtonFormField<String>(
      initialValue: value ?? 'All',
      decoration: InputDecoration(
        labelText: title,
        isDense: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      items: items
          .map(
            (String item) =>
                DropdownMenuItem<String>(value: item, child: Text(item)),
          )
          .toList(),
      onChanged: onChanged,
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
