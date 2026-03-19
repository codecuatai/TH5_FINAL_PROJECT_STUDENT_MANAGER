class AppConstants {
  const AppConstants._();

  static const String appTitle = 'SM - Nhóm 6';
  static const String filterAll = 'Tất cả';

  static const List<String> faculties = <String>[
    'CNTT',
    'Kinh te',
    'Cong trinh',
    'Dien',
    'Moi truong',
  ];

  static const List<String> courses = <String>['K65', 'K66', 'K67', 'K68'];

  static const List<String> academicLevels = <String>[
    filterAll,
    'Xuất sắc',
    'Giỏi',
    'Khá',
    'Trung bình',
    'Yếu',
  ];

  static const List<String> genders = <String>['male', 'female', 'other'];

  static String facultyLabel(String value) {
    switch (value) {
      case 'Kinh te':
        return 'Kinh tế';
      case 'Cong trinh':
        return 'Công trình';
      case 'Dien':
        return 'Điện';
      case 'Moi truong':
        return 'Môi trường';
      default:
        return value;
    }
  }

  static String genderLabel(String value) {
    switch (value.toLowerCase()) {
      case 'male':
        return 'Nam';
      case 'female':
        return 'Nữ';
      default:
        return 'Khác';
    }
  }
}
