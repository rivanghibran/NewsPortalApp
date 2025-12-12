import 'package:flutter/material.dart';
class AppConstants {
  // Ganti 10.0.2.2 dengan IP Laptop jika pakai HP fisik (misal: http://192.168.1.5:8000/api)
  static const String baseUrl = "http://127.0.0.1:8000/api";

  static const Color cnnRed = Color(0xFFCC0000); // Merah CNN Asli
  static const Color cnnBlack = Color(0xFF000000);
  static const Color cnnDarkGrey = Color(0xFF282828);
  static const Color cnnLightGrey = Color(0xFFF5F5F5);
  
  // --- TEXT STYLES ---
  static const TextStyle titleStyle = TextStyle(
    fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white
  );
  
  static const TextStyle headlineStyle = TextStyle(
    fontSize: 16, fontWeight: FontWeight.w800, color: Colors.black87
  );
}