import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import '../models/student_model.dart';
import '../utils/gpa_utils.dart';

class StudentCard extends StatelessWidget {
  const StudentCard({
    super.key,
    required this.student,
    required this.onTap,
    required this.onDelete,
    required this.onCall,
  });

  final StudentModel student;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onCall;

  @override
  Widget build(BuildContext context) {
    final String level = GpaUtils.academicLevelFromGpa4(student.gpa4);
    final Color badgeColor = _badgeColor(level);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Slidable(
        key: ValueKey<String>(student.id),
        startActionPane: ActionPane(
          motion: const ScrollMotion(),
          children: <Widget>[
            SlidableAction(
              onPressed: (_) => onCall(),
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
              icon: Icons.call,
              label: 'Gọi',
              borderRadius: BorderRadius.circular(12),
            ),
          ],
        ),
        endActionPane: ActionPane(
          motion: const DrawerMotion(),
          children: <Widget>[
            SlidableAction(
              onPressed: (_) => onDelete(),
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              icon: Icons.delete,
              label: 'Xóa',
              borderRadius: BorderRadius.circular(12),
            ),
          ],
        ),
        child: Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          color: Colors.white,
          child: ListTile(
            onTap: onTap,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 10,
            ),
            leading: CircleAvatar(
              radius: 23,
              backgroundColor: Colors.blueGrey.shade50,
              child: Icon(
                _avatarIcon(student.gender),
                color: Colors.blueGrey.shade700,
              ),
            ),
            title: Text(
              student.name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('MSSV: ${student.mssv}'),
                  Text('Lớp: ${student.className}'),
                ],
              ),
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Text(
                level,
                style: TextStyle(
                  color: badgeColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  IconData _avatarIcon(String gender) {
    switch (gender.toLowerCase()) {
      case 'male':
        return Icons.man;
      case 'female':
        return Icons.woman;
      default:
        return Icons.person;
    }
  }

  Color _badgeColor(String level) {
    if (level == 'Xuất sắc') {
      return Colors.blue;
    }
    if (level == 'Khá') {
      return Colors.green;
    }
    return Colors.orange;
  }
}
