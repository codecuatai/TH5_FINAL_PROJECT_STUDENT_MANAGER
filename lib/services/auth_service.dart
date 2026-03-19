import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  AuthService({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (error) {
      throw Exception(_mapAuthError(error));
    } catch (error) {
      throw Exception('Đăng nhập thất bại: $error');
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } on FirebaseAuthException catch (error) {
      throw Exception(_mapAuthError(error));
    } catch (error) {
      throw Exception('Đăng xuất thất bại: $error');
    }
  }

  String _mapAuthError(FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-email':
        return 'Địa chỉ email không hợp lệ.';
      case 'invalid-credential':
        return 'Email hoặc mật khẩu không đúng.';
      case 'user-disabled':
        return 'Tài khoản này đã bị vô hiệu hóa.';
      case 'user-not-found':
        return 'Không tìm thấy tài khoản với email này.';
      case 'wrong-password':
        return 'Email hoặc mật khẩu không đúng.';
      case 'too-many-requests':
        return 'Có quá nhiều yêu cầu. Vui lòng thử lại sau.';
      default:
        return error.message ?? 'Xác thực thất bại.';
    }
  }
}
