import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../models/student_model.dart';
import '../models/subject_model.dart';
import '../providers/student_provider.dart';
import '../utils/app_constants.dart';
import '../utils/gpa_utils.dart';
import '../utils/validators.dart';
import '../widgets/error_state.dart';
import '../widgets/loading_state.dart';
import 'student_upsert_screen.dart';

class StudentDetailScreen extends StatefulWidget {
  const StudentDetailScreen({super.key});

  static const String routeName = '/detail';

  @override
  State<StudentDetailScreen> createState() => _StudentDetailScreenState();
}

class _StudentDetailScreenState extends State<StudentDetailScreen> {
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');

  Future<void> _showSubjectDialog({
    required String studentId,
    SubjectModel? subject,
  }) async {
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    final TextEditingController nameController = TextEditingController(
      text: subject?.name ?? '',
    );
    final TextEditingController creditsController = TextEditingController(
      text: subject?.credits.toString() ?? '3',
    );
    final TextEditingController scoreController = TextEditingController(
      text: subject?.score.toStringAsFixed(2) ?? '0.0',
    );
    final TextEditingController semesterController = TextEditingController(
      text: subject?.semester ?? 'HK1',
    );

    final bool? shouldSave = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(subject == null ? 'Add Subject' : 'Edit Subject'),
          content: SizedBox(
            width: 420,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Subject name',
                      border: OutlineInputBorder(),
                    ),
                    validator: (String? value) =>
                        Validators.requiredField(value, 'Subject name'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: creditsController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Credits',
                      border: OutlineInputBorder(),
                    ),
                    validator: (String? value) {
                      final String? required = Validators.requiredField(
                        value,
                        'Credits',
                      );
                      if (required != null) {
                        return required;
                      }

                      final int? credits = int.tryParse(value!);
                      if (credits == null || credits <= 0) {
                        return 'Credits must be a positive integer';
                      }

                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: scoreController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Score (0 - 10)',
                      border: OutlineInputBorder(),
                    ),
                    validator: (String? value) =>
                        Validators.score10(value, 'Score'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: semesterController,
                    decoration: const InputDecoration(
                      labelText: 'Semester (e.g. HK1, HK2)',
                      border: OutlineInputBorder(),
                    ),
                    validator: (String? value) =>
                        Validators.requiredField(value, 'Semester'),
                  ),
                ],
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (!formKey.currentState!.validate()) {
                  return;
                }
                Navigator.of(context).pop(true);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (!mounted || shouldSave != true) {
      nameController.dispose();
      creditsController.dispose();
      scoreController.dispose();
      semesterController.dispose();
      return;
    }

    final SubjectModel payload = SubjectModel(
      id: subject?.id ?? const Uuid().v4(),
      name: nameController.text.trim(),
      credits: int.parse(creditsController.text.trim()),
      score: double.parse(scoreController.text.trim()),
      semester: semesterController.text.trim(),
    );

    final String? error = await context.read<StudentProvider>().upsertSubject(
      studentId: studentId,
      subject: payload,
    );

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error ?? 'Subject saved successfully.'),
        backgroundColor: error == null ? Colors.green : Colors.red,
      ),
    );

    nameController.dispose();
    creditsController.dispose();
    scoreController.dispose();
    semesterController.dispose();
  }

  Future<void> _deleteSubject({
    required String studentId,
    required SubjectModel subject,
  }) async {
    final bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete subject'),
          content: Text('Delete ${subject.name}?'),
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

    final String? error = await context.read<StudentProvider>().deleteSubject(
      studentId: studentId,
      subjectId: subject.id,
    );

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error ?? 'Subject deleted successfully.'),
        backgroundColor: error == null ? Colors.green : Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final StudentProvider provider = context.watch<StudentProvider>();
    final StudentModel? selectedStudent = provider.selectedStudent;

    if (selectedStudent == null) {
      return Scaffold(
        appBar: AppBar(title: const Text(AppConstants.appTitle)),
        body: const Center(
          child: Text(
            'No student selected. Return to dashboard and choose one.',
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.appTitle),
        actions: <Widget>[
          IconButton(
            onPressed: () {
              Navigator.of(context).pushNamed(StudentUpsertScreen.routeName);
            },
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit student',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showSubjectDialog(studentId: selectedStudent.id),
        icon: const Icon(Icons.add),
        label: const Text('Add Subject'),
      ),
      body: StreamBuilder<List<SubjectModel>>(
        stream: context.read<StudentProvider>().streamSubjectsByStudentId(
          selectedStudent.id,
        ),
        builder:
            (BuildContext context, AsyncSnapshot<List<SubjectModel>> snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const LoadingState(message: 'Loading profile...');
              }

              if (snapshot.hasError) {
                return ErrorState(message: snapshot.error.toString());
              }

              final List<SubjectModel> subjects =
                  snapshot.data ?? <SubjectModel>[];
              final double gpa10 = subjects.isEmpty
                  ? selectedStudent.gpa10
                  : GpaUtils.calculateGpa10(subjects);
              final double gpa4 = subjects.isEmpty
                  ? selectedStudent.gpa4
                  : GpaUtils.convert10To4(gpa10);
              final String academicLevel = GpaUtils.academicLevelFromGpa4(gpa4);

              final Map<String, double> semesterAverages =
                  GpaUtils.semesterAverages(subjects);
              final Map<String, int> gradeDistribution =
                  GpaUtils.gradeDistribution(subjects);

              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 900),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        _ProfileCard(
                          student: selectedStudent,
                          birthDateText: _dateFormat.format(
                            selectedStudent.birthDate,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: <Widget>[
                            _InfoChip(
                              label: 'GPA (10)',
                              value: gpa10.toStringAsFixed(2),
                              color: Colors.indigo,
                            ),
                            _InfoChip(
                              label: 'GPA (4)',
                              value: gpa4.toStringAsFixed(2),
                              color: Colors.teal,
                            ),
                            _InfoChip(
                              label: 'Academic',
                              value: academicLevel,
                              color: academicLevel == 'Excellent'
                                  ? Colors.blue
                                  : academicLevel == 'Good'
                                  ? Colors.green
                                  : Colors.orange,
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'Subjects',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        if (subjects.isEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'No subjects yet. Add one to calculate GPA.',
                            ),
                          )
                        else
                          ...subjects.map(
                            (SubjectModel subject) => Card(
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListTile(
                                title: Text(
                                  subject.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Text(
                                  'Credits: ${subject.credits} | Score: ${subject.score.toStringAsFixed(2)} | ${subject.semester}',
                                ),
                                trailing: Wrap(
                                  spacing: 4,
                                  children: <Widget>[
                                    IconButton(
                                      onPressed: () => _showSubjectDialog(
                                        studentId: selectedStudent.id,
                                        subject: subject,
                                      ),
                                      icon: const Icon(Icons.edit_outlined),
                                    ),
                                    IconButton(
                                      onPressed: () => _deleteSubject(
                                        studentId: selectedStudent.id,
                                        subject: subject,
                                      ),
                                      icon: const Icon(Icons.delete_outline),
                                      color: Colors.red,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        const SizedBox(height: 18),
                        Text(
                          'Semester Score Comparison',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: 260,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.fromLTRB(12, 18, 12, 12),
                          child: semesterAverages.isEmpty
                              ? const Center(child: Text('No data for chart'))
                              : _SemesterBarChart(data: semesterAverages),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Grade Distribution',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: 280,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.all(12),
                          child: _GradePieChart(data: gradeDistribution),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.student, required this.birthDateText});

  final StudentModel student;
  final String birthDateText;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              CircleAvatar(
                radius: 28,
                backgroundColor: Colors.blueGrey.shade50,
                child: Icon(
                  student.gender == 'female'
                      ? Icons.woman
                      : student.gender == 'male'
                      ? Icons.man
                      : Icons.person,
                  size: 32,
                  color: Colors.blueGrey.shade700,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      student.name,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text('MSSV: ${student.mssv}'),
                    Text('Class: ${student.className}'),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          Wrap(
            spacing: 18,
            runSpacing: 8,
            children: <Widget>[
              Text('Email: ${student.email}'),
              Text('Phone: ${student.phone}'),
              Text('Faculty: ${student.faculty}'),
              Text('Course: ${student.course}'),
              Text('Birth date: $birthDateText'),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: RichText(
        text: TextSpan(
          style: Theme.of(context).textTheme.bodyMedium,
          children: <InlineSpan>[
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            TextSpan(
              text: value,
              style: TextStyle(color: color),
            ),
          ],
        ),
      ),
    );
  }
}

class _SemesterBarChart extends StatelessWidget {
  const _SemesterBarChart({required this.data});

  final Map<String, double> data;

  @override
  Widget build(BuildContext context) {
    final List<MapEntry<String, double>> entries = data.entries.toList();
    final double maxY = math.max(
      10,
      entries.fold<double>(
        0,
        (double previous, MapEntry<String, double> element) =>
            math.max(previous, element.value + 1),
      ),
    );

    return BarChart(
      BarChartData(
        maxY: maxY,
        gridData: const FlGridData(show: true),
        barGroups: entries.asMap().entries.map((
          MapEntry<int, MapEntry<String, double>> item,
        ) {
          final int x = item.key;
          final double y = item.value.value;
          return BarChartGroupData(
            x: x,
            barRods: <BarChartRodData>[
              BarChartRodData(
                toY: y,
                color: const Color(0xFF0F5FAF),
                width: 18,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          );
        }).toList(),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 32),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (double value, TitleMeta meta) {
                final int index = value.toInt();
                if (index < 0 || index >= entries.length) {
                  return const SizedBox.shrink();
                }

                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    entries[index].key,
                    style: const TextStyle(fontSize: 11),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _GradePieChart extends StatelessWidget {
  const _GradePieChart({required this.data});

  final Map<String, int> data;

  @override
  Widget build(BuildContext context) {
    final int total = data.values.fold<int>(
      0,
      (int sum, int value) => sum + value,
    );
    if (total == 0) {
      return const Center(child: Text('No grade data'));
    }

    final Map<String, Color> colors = <String, Color>{
      'A': Colors.blue,
      'B': Colors.green,
      'C': Colors.orange,
      'D': Colors.deepOrange,
      'F': Colors.red,
    };

    final List<PieChartSectionData> sections = data.entries
        .where((MapEntry<String, int> entry) => entry.value > 0)
        .map((MapEntry<String, int> entry) {
          final double percentage = (entry.value / total) * 100;
          return PieChartSectionData(
            value: entry.value.toDouble(),
            color: colors[entry.key] ?? Colors.grey,
            radius: 66,
            title: '${entry.key}\n${percentage.toStringAsFixed(0)}%',
            titleStyle: const TextStyle(
              fontSize: 12,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          );
        })
        .toList();

    return Column(
      children: <Widget>[
        Expanded(
          child: PieChart(
            PieChartData(
              sections: sections,
              sectionsSpace: 2,
              centerSpaceRadius: 32,
            ),
          ),
        ),
        Wrap(
          spacing: 10,
          runSpacing: 6,
          children: data.entries
              .map(
                (MapEntry<String, int> entry) => Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: colors[entry.key] ?? Colors.grey,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text('${entry.key}: ${entry.value}'),
                  ],
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}
