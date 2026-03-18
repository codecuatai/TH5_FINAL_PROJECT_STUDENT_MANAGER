class Validators {
  const Validators._();

  static String? requiredField(String? value, String label) {
    if (value == null || value.trim().isEmpty) {
      return '$label is required';
    }
    return null;
  }

  static String? adminEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }

    final RegExp emailRegex = RegExp(
      r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$',
    );
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Invalid email format';
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
      return 'Email must end with @gmail.com or @wru.vn';
    }

    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
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
      return 'MSSV must be at least 6 characters';
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
      return '$label must be a number';
    }
    if (score < 0 || score > 10) {
      return '$label must be between 0 and 10';
    }
    return null;
  }
}
