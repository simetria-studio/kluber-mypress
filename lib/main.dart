import 'package:flutter/material.dart';
import 'views/login_screen.dart';
import 'views/home_screen.dart';
import 'services/storage_service.dart';
import 'views/visitas_pendentes_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Login App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFABA00),
          primary: const Color(0xFFFABA00),
          secondary: Colors.black,
        ),
        useMaterial3: true,
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey[900],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFFABA00), width: 2),
          ),
        ),
      ),
      home: FutureBuilder<bool>(
        future: StorageService().isAuthenticated(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              backgroundColor: Colors.black,
              body: Center(
                child: CircularProgressIndicator(
                  color: Color(0xFFFABA00),
                ),
              ),
            );
          }

          return snapshot.data == true
              ? const HomeScreen()
              : const LoginScreen();
        },
      ),
    );
  }
}
