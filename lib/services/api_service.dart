// file: lib/services/api_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';

// Import hanya untuk menangkap Exception
import 'dart:io' show SocketException; 

import '../core/constants.dart';
import '../models/berita_model.dart';

class ApiService {
  
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Map<String, String> _getJsonHeaders({String? token}) {
    final headers = {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  // ===========================================================================
  // AUTH (LOGIN, REGISTER, LOGOUT)
  // ===========================================================================

  /// 🔐 LOGIN (Laravel Passport)
  Future<bool> login(String email, String password) async {
    final url = Uri.parse('${AppConstants.baseUrl}/login');

    try {
      final response = await http.post(
        url,
        headers: _getJsonHeaders(),
        body: jsonEncode({'email': email, 'password': password}),
      );

      print("LOGIN Status: ${response.statusCode}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', data['access_token'] ?? '');

        if (data['user'] != null) {
          final user = data['user'];
          await prefs.setString('userName', user['name'] ?? 'Pengguna');
          await prefs.setBool('isOfficial', user['is_official'] ?? false);
        }
        return true;
      }

      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? "Login gagal. Periksa kredensial.");
      
    } catch (e) {
      if (!kIsWeb && e is SocketException) { 
        throw Exception("Gagal terhubung ke server. Periksa koneksi Anda.");
      }
      print("Login Error: $e");
      rethrow;
    }
  }

  /// 📝 REGISTER (Laravel Passport)
  Future<bool> register(String name, String email, String password) async {
    final url = Uri.parse('${AppConstants.baseUrl}/register');

    try {
      final response = await http.post(
        url,
        headers: _getJsonHeaders(),
        body: jsonEncode({
          'name': name, 'email': email, 'password': password,
          'password_confirmation': password,
        }),
      );

      print("REGISTER Status: ${response.statusCode}");

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['access_token'] != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('token', data['access_token'] ?? '');
          
          if (data['user'] != null) {
            final user = data['user'];
            await prefs.setString('userName', user['name'] ?? 'Pengguna Baru');
            await prefs.setBool('isOfficial', user['is_official'] ?? false);
          }
        }
        return true;
      }

      final error = jsonDecode(response.body);
      if (error['errors'] != null && error['errors'] is Map) {
          final firstError = error['errors'].values.first.first;
          throw Exception(firstError.toString());
      }
      throw Exception(error['message'] ?? "Registrasi gagal.");

    } catch (e) {
      if (!kIsWeb && e is SocketException) { 
          throw Exception("Gagal terhubung ke server. Periksa koneksi Anda.");
      }
      print("Register Error: $e");
      rethrow;
    }
  }
  
  /// 🚪 LOGOUT
  Future<void> logout() async {
    try {
      final token = await _getToken();
      if (token != null) {
        await http.post(
          Uri.parse('${AppConstants.baseUrl}/logout'),
          headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
        );
      }
    } catch (_) {
      // Abaikan error saat logout
    } finally {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    }
  }

  // ===========================================================================
  // BERITA
  // ===========================================================================

  /// 📰 Ambil List Berita
  Future<List<Berita>> getBerita() async {
    final response = await http.get(
      Uri.parse('${AppConstants.baseUrl}/berita'),
      headers: {'Accept': 'application/json'},
    );

    print("GET BERITA Status: ${response.statusCode}");

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);

      final list = (jsonResponse is List)
          ? jsonResponse
          : jsonResponse['data'] ?? [];

      return (list as List).map((e) => Berita.fromJson(e)).toList();
    }
    
    // SOLUSI ERROR body_might_complete_normally: Memastikan throw di akhir
    throw Exception("Gagal memuat berita (Kode: ${response.statusCode})"); 
  }

  /// 📖 Ambil Detail Berita
  Future<Berita> getDetailBerita(int id) async {
    final response = await http.get(
      Uri.parse('${AppConstants.baseUrl}/berita/$id'),
      headers: {'Accept': 'application/json'},
    );
    
    // Pastikan response.statusCode = 200 sebelum memproses
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      // Mengatasi respons yang mungkin dibungkus oleh 'data' atau tidak
      return Berita.fromJson(data['data'] ?? data);
    }
    
    // SOLUSI ERROR body_might_complete_normally: Memastikan throw di akhir
    throw Exception("Gagal memuat detail (Kode: ${response.statusCode})");
  }

  /// 🖼️ Upload Berita
  Future<bool> uploadBerita(String judul, String isi, dynamic imageFile) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception("Autentikasi diperlukan untuk mengunggah berita.");
    }
    
    var request = http.MultipartRequest('POST', Uri.parse('${AppConstants.baseUrl}/berita'));

    request.headers['Authorization'] = 'Bearer $token';
    request.headers['Accept'] = 'application/json';

    request.fields['judul'] = judul;
    request.fields['isi'] = isi;

    if (imageFile != null) {
      if (kIsWeb) {
        if (imageFile is Uint8List) {
          request.files.add(http.MultipartFile.fromBytes('gambar', imageFile, filename: 'upload.png'));
        } else {
           throw Exception("Tipe file tidak valid untuk Web (Diharapkan Uint8List).");
        }
      } else {
        // Logika Mobile/Desktop: Asumsi imageFile memiliki properti 'path'
        try {
           final imageFilePath = imageFile.path;
           request.files.add(await http.MultipartFile.fromPath('gambar', imageFilePath));
        } catch (e) {
           throw Exception("Gagal membaca path file di Mobile/Desktop. Pastikan imageFile adalah dart:io.File.");
        }
      }
    }

    final response = await request.send();
    final parsed = await http.Response.fromStream(response);

    print("UPLOAD Status: ${parsed.statusCode}");
    if (parsed.statusCode == 200 || parsed.statusCode == 201) {
      return true;
    }
    
    try {
        final error = jsonDecode(parsed.body);
        final errorMessage = error['message'] ?? (error['errors']?.values.first.first);
        throw Exception(errorMessage ?? "Gagal mengunggah berita");
    } catch (_) {
        throw Exception("Gagal mengunggah berita (Kode: ${parsed.statusCode})");
    }
  }

  /// 💬 Post Komentar
  Future<bool> postKomentar(int beritaId, String isi) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception("Autentikasi diperlukan untuk berkomentar.");
    }

    final response = await http.post(
      Uri.parse('${AppConstants.baseUrl}/berita/$beritaId/komentar'),
      headers: _getJsonHeaders(token: token),
      body: jsonEncode({'isi': isi}),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return true;
    }
    
    final error = jsonDecode(response.body);
    throw Exception(error['message'] ?? "Gagal mengirim komentar.");
  }
}