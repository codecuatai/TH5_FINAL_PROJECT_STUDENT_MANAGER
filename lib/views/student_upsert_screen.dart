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

class StudentUpsertScreen extends StatefulWidget {
  const StudentUpsertScreen({super.key});

  static const String routeName = '/upsert';

  @override
  State<StudentUpsertScreen> createState() => _StudentUpsertScreenState();
}

class _StudentUpsertScreenState extends State<StudentUpsertScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _mssvController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _classController = TextEditingController();
  final TextEditingController _gpa10Controller = TextEditingController();

  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');

  DateTime _birthDate = DateTime(2000, 1, 1);
  String _faculty = AppConstants.faculties.first;
  String _course = AppConstants.courses.first;
  String _gender = AppConstants.genders.first;
  bool _hasUnpaidTuition = false;

  StudentModel? _editingStudent;
  bool _didInit = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInit) {
      return;
    }
    _didInit = true;

    _editingStudent = context.read<StudentProvider>().selectedStudent;
    final StudentModel? editing = _editingStudent;
    if (editing == null) {
      _gpa10Controller.text = '0.0';
      return;
    }

    _nameController.text = editing.name;
    _mssvController.text = editing.mssv;
    _emailController.text = editing.email;
    _phoneController.text = editing.phone;
    _classController.text = editing.className;
    _gpa10Controller.text = editing.gpa10.toStringAsFixed(2);

    _birthDate = editing.birthDate;
    _faculty = editing.faculty;
    _course = editing.course;
    _gender = editing.gender;
    _hasUnpaidTuition = editing.hasUnpaidTuition;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mssvController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _classController.dispose();
    _gpa10Controller.dispose();
    super.dispose();
  }

  Future<void> _pickBirthDate() async {
    final DateTime? selected = await showDatePicker(
      context: context,
      initialDate: _birthDate,
      firstDate: DateTime(1980),
      lastDate: DateTime.now(),
    );

    if (selected == null) {
      return;
    }

    setState(() {
      _birthDate = selected;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final double gpa10 = double.parse(_gpa10Controller.text);
    final StudentModel payload = StudentModel(
      id: _editingStudent?.id ?? const Uuid().v4(),
      name: _nameController.text.trim(),
      mssv: _mssvController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      className: _classController.text.trim(),
      faculty: _faculty,
      course: _course,
      birthDate: _birthDate,
      gpa10: gpa10,
      gpa4: GpaUtils.convert10To4(gpa10),
      gender: _gender,
      hasUnpaidTuition: _hasUnpaidTuition,
      subjects: _editingStudent?.subjects ?? const <SubjectModel>[],
    );

    final String? error = await context.read<StudentProvider>().upsertStudent(
      payload,
    );
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error ?? 'Đã lưu sinh viên thành công.'),
        backgroundColor: error == null ? Colors.green : Colors.red,
      ),
    );

    if (error == null) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isSaving = context.select<StudentProvider, bool>(
      (StudentProvider provider) => provider.isSaving,
    );

    final bool isEditMode = _editingStudent != null;

    return Scaffold(
      appBar: AppBar(title: const Text(AppConstants.appTitle)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          isEditMode ? 'Chỉnh sửa sinh viên' : 'Thêm sinh viên',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 18),
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Họ và tên',
                            border: OutlineInputBorder(),
                          ),
                          validator: (String? value) =>
                              Validators.requiredField(value, 'Họ và tên'),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _mssvController,
                          decoration: const InputDecoration(
                            labelText: 'MSSV',
                            border: OutlineInputBorder(),
                          ),
                          validator: Validators.mssv,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            border: OutlineInputBorder(),
                          ),
                          validator: Validators.studentEmail,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'Số điện thoại',
                            border: OutlineInputBorder(),
                          ),
                          validator: (String? value) =>
                              Validators.requiredField(value, 'Số điện thoại'),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _classController,
                          decoration: const InputDecoration(
                            labelText: 'Lớp',
                            border: OutlineInputBorder(),
                          ),
                          validator: (String? value) =>
                              Validators.requiredField(value, 'Lớp'),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _gpa10Controller,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'GPA (thang 10)',
                            border: OutlineInputBorder(),
                          ),
                          validator: (String? value) =>
                              Validators.score10(value, 'GPA (thang 10)'),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: _faculty,
                          decoration: const InputDecoration(
                            labelText: 'Khoa',
                            border: OutlineInputBorder(),
                          ),
                          items: AppConstants.faculties
                              .map(
                                (String faculty) => DropdownMenuItem<String>(
                                  value: faculty,
                                  child: Text(
                                    AppConstants.facultyLabel(faculty),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (String? value) {
                            if (value == null) {
                              return;
                            }
                            setState(() {
                              _faculty = value;
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: _course,
                          decoration: const InputDecoration(
                            labelText: 'Khóa',
                            border: OutlineInputBorder(),
                          ),
                          items: AppConstants.courses
                              .map(
                                (String course) => DropdownMenuItem<String>(
                                  value: course,
                                  child: Text(course),
                                ),
                              )
                              .toList(),
                          onChanged: (String? value) {
                            if (value == null) {
                              return;
                            }
                            setState(() {
                              _course = value;
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: _gender,
                          decoration: const InputDecoration(
                            labelText: 'Giới tính',
                            border: OutlineInputBorder(),
                          ),
                          items: AppConstants.genders
                              .map(
                                (String gender) => DropdownMenuItem<String>(
                                  value: gender,
                                  child: Text(AppConstants.genderLabel(gender)),
                                ),
                              )
                              .toList(),
                          onChanged: (String? value) {
                            if (value == null) {
                              return;
                            }
                            setState(() {
                              _gender = value;
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        InkWell(
                          onTap: _pickBirthDate,
                          borderRadius: BorderRadius.circular(10),
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Ngày sinh',
                              border: OutlineInputBorder(),
                              suffixIcon: Icon(Icons.calendar_month),
                            ),
                            child: Text(_dateFormat.format(_birthDate)),
                          ),
                        ),
                        const SizedBox(height: 8),
                        SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Nợ học phí'),
                          value: _hasUnpaidTuition,
                          onChanged: (bool value) {
                            setState(() {
                              _hasUnpaidTuition = value;
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: FilledButton(
                            onPressed: isSaving ? null : _submit,
                            child: isSaving
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    isEditMode
                                        ? 'Cập nhật sinh viên'
                                        : 'Tạo sinh viên',
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
