class Validators {
  const Validators._();

  static String? requiredField(String? value, String label) {
    if (value == null || value.trim().isEmpty) {
      return '$label không được để trống';
    }
    return null;
  }

  static String? adminEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email không được để trống';
    }

    final RegExp emailRegex = RegExp(
      r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$',
    );
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Định dạng email không hợp lệ';
    }

    return null;
  }

  static String? studentEmail(String? value) {
    final String? requiredValidation = requiredField(value, 'Email');
    if (requiredValidation != null) {
      return requiredValidation;
    }

    final String email = value!.trim().toLowerCase();
    if (!email.endsWith('@gmail.com') && !email.endsWith('@wru.vn')) {
      return 'Email phải kết thúc bằng @gmail.com hoặc @wru.vn';
    }

    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Mật khẩu không được để trống';
    }
    if (value.length < 6) {
      return 'Mật khẩu phải có ít nhất 6 ký tự';
    }
    return null;
  }

  static String? mssv(String? value) {
    final String? requiredValidation = requiredField(value, 'MSSV');
    if (requiredValidation != null) {
      return requiredValidation;
    }

    final String mssv = value!.trim();
    if (mssv.length < 6) {
      return 'MSSV phải có ít nhất 6 ký tự';
    }

    return null;
  }

  static String? score10(String? value, String label) {
    final String? requiredValidation = requiredField(value, label);
    if (requiredValidation != null) {
      return requiredValidation;
    }

    final double? score = double.tryParse(value!);
    if (score == null) {
      return '$label phải là số';
    }
    if (score < 0 || score > 10) {
      return '$label phải nằm trong khoảng từ 0 đến 10';
    }
    return null;
  }
}
