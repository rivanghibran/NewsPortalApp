import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; // Pastikan sudah ada di pubspec.yaml
import 'package:shared_preferences/shared_preferences.dart';
import 'core/constants.dart';
import 'views/auth/login_page.dart';
import 'views/main/main_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token');

  runApp(MyApp(isLoggedIn: token != null));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  const MyApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'News Portal',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // Gunakan Merah sebagai warna utama
        primaryColor: AppConstants.cnnRed,
        scaffoldBackgroundColor: Colors.white,
        
        // Atur Font Default (Opsional: Gunakan Poppins/Roboto jika ada)
        textTheme: GoogleFonts.latoTextTheme(),
        
        // Style AppBar Default
        appBarTheme: const AppBarTheme(
          backgroundColor: AppConstants.cnnRed,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          iconTheme: IconThemeData(color: Colors.white),
        ),

        // Style Input Field (TextField)
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppConstants.cnnRed, width: 2)),
          prefixIconColor: AppConstants.cnnRed,
        ),

        // Style ElevatedButton
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppConstants.cnnRed,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(vertical: 14),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),
      home: isLoggedIn ? const MainPage() : const LoginPage(),
    );
  }
}