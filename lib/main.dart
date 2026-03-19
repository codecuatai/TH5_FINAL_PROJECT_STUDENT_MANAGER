import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/student_provider.dart';
import 'utils/app_constants.dart';
import 'views/analytics_screen.dart';
import 'views/dashboard_screen.dart';
import 'views/login_screen.dart';
import 'views/student_detail_screen.dart';
import 'views/student_upsert_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  String? initError;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (error) {
    try {
      // Dự phòng cho môi trường chưa có cấu hình Firebase được sinh tự động.
      await Firebase.initializeApp();
    } catch (fallbackError) {
      initError = fallbackError.toString();
    }
  }

  runApp(SMApp(initializationError: initError));
}

class SMApp extends StatelessWidget {
  const SMApp({super.key, this.initializationError});

  final String? initializationError;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider()),
        ChangeNotifierProvider<StudentProvider>(
          create: (_) => StudentProvider(),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: AppConstants.appTitle,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0F5FAF)),
          scaffoldBackgroundColor: const Color(0xFFF3F7FC),
          useMaterial3: true,
          snackBarTheme: const SnackBarThemeData(
            behavior: SnackBarBehavior.floating,
          ),
        ),
        routes: <String, WidgetBuilder>{
          LoginScreen.routeName: (_) => const LoginScreen(),
          DashboardScreen.routeName: (_) => const DashboardScreen(),
          StudentUpsertScreen.routeName: (_) => const StudentUpsertScreen(),
          StudentDetailScreen.routeName: (_) => const StudentDetailScreen(),
          AnalyticsScreen.routeName: (_) => const AnalyticsScreen(),
        },
        home: initializationError == null
            ? const _AuthGate()
            : _InitErrorScreen(error: initializationError!),
      ),
    );
  }
}

class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    final bool isAuthenticated = context.select<AuthProvider, bool>((
      AuthProvider provider,
    ) {
      return provider.isAuthenticated;
    });

    if (isAuthenticated) {
      return const DashboardScreen();
    }

    return const LoginScreen();
  }
}

class _InitErrorScreen extends StatelessWidget {
  const _InitErrorScreen({required this.error});

  final String error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppConstants.appTitle)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(Icons.error_outline, size: 40, color: Colors.red.shade700),
              const SizedBox(height: 12),
              const Text(
                'Khởi tạo Firebase thất bại.',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(error, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
