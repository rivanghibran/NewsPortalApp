// file: lib/services/api_service.dart

import 'dart:convert';
// Import File dan SocketException secara eksplisit
import 'dart:io' show File, SocketException; 
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../core/constants.dart';
import '../models/berita_model.dart';

class ApiService {
  
  // Helper untuk mengambil Token dari SharedPreferences
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // Helper untuk membuat Header JSON
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
        
        // Ambil token (bisa 'access_token' atau 'token')
        final tokenKey = data['access_token'] ?? data['token']; 
        await prefs.setString('token', tokenKey ?? '');

        if (data['user'] != null) {
          final user = data['user'];
          // Simpan ID user untuk fitur Profile
          if (user['id'] != null) {
             await prefs.setInt('userId', user['id']); 
          }
          await prefs.setString('userName', user['name'] ?? 'Pengguna');
          await prefs.setString('userEmail', user['email'] ?? '');
          
          // Penanganan is_official (biasanya 0/1 atau true/false)
          bool isOfficial = false;
          if (user['is_official'] != null) {
              isOfficial = user['is_official'] == 1 || user['is_official'] == true;
          }
          await prefs.setBool('isOfficial', isOfficial);
        }
        return true;
      }
      
      // Tangani Error 401 (Unauthorized) atau Error Validasi
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? "Login gagal. Periksa kredensial.");
      
    } catch (e) {
      if (!kIsWeb && e is SocketException) { 
        throw Exception("Gagal terhubung ke server. Periksa koneksi Anda.");
      }
      print("Login Exception: $e");
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
          'password_confirmation': password, // Wajib untuk validasi Laravel
        }),
      );

      print("REGISTER Status: ${response.statusCode}");

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final tokenKey = data['access_token'] ?? data['token']; 
        if (tokenKey != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('token', tokenKey);
          
          if (data['user'] != null) {
            final user = data['user'];
            if (user['id'] != null) {
               await prefs.setInt('userId', user['id']);
            }
            await prefs.setString('userName', user['name'] ?? 'Pengguna Baru');
            await prefs.setString('userEmail', user['email'] ?? '');
             
            bool isOfficial = false;
            if (user['is_official'] != null) {
                isOfficial = user['is_official'] == 1 || user['is_official'] == true;
            }
            await prefs.setBool('isOfficial', isOfficial);
          }
        }
        return true;
      }

      // Tangani Error Validasi (422) atau Error Server (500)
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
      print("Register Exception: $e");
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
          headers: _getJsonHeaders(token: token),
        );
      }
    } catch (_) {
      // Abaikan error jaringan saat logout
    } finally {
      // Selalu hapus sesi lokal
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    }
  }

  // ===========================================================================
  // BERITA & DATA TERPROTEKSI
  // ===========================================================================

  /// 📰 Ambil List Berita
  Future<List<Berita>> getBerita() async {
    final response = await http.get(
      Uri.parse('${AppConstants.baseUrl}/berita'),
      headers: _getJsonHeaders(), // Tidak perlu token, public
    );

    print("GET BERITA Status: ${response.statusCode}");

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);

      // Logika fleksibel untuk membaca List dari root atau dari key 'data'
      final list = (jsonResponse is List)
          ? jsonResponse
          : jsonResponse['data'] ?? [];

      return (list as List).map((e) => Berita.fromJson(e)).toList();
    }
    
    throw Exception("Gagal memuat berita (Kode: ${response.statusCode})"); 
  }

  /// 📖 Ambil Detail Berita
  Future<Berita> getDetailBerita(int id) async {
    final response = await http.get(
      Uri.parse('${AppConstants.baseUrl}/berita/$id'),
      headers: _getJsonHeaders(), // Tidak perlu token, public
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      // Mengatasi respons yang mungkin dibungkus oleh 'data' atau tidak
      return Berita.fromJson(data['data'] ?? data);
    }
    
    throw Exception("Gagal memuat detail (Kode: ${response.statusCode})");
  }

  /// 🖼️ Upload Berita (Membutuhkan Token)
  /// Parameter [imageFile] bisa berupa:
  /// - [Uint8List] (untuk Web)
  /// - [File] (untuk Mobile/Desktop)
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
        // --- LOGIKA WEB ---
        if (imageFile is Uint8List) {
          request.files.add(http.MultipartFile.fromBytes('gambar', imageFile, filename: 'upload.png'));
        } else {
            throw Exception("Tipe file tidak valid untuk Web (Diharapkan Uint8List).");
        }
      } else {
        // --- LOGIKA MOBILE ---
        try {
            if (imageFile is File) {
               final imageFilePath = imageFile.path; 
               request.files.add(await http.MultipartFile.fromPath('gambar', imageFilePath));
            } else {
               throw Exception("Tipe file tidak valid. Pastikan imageFile adalah dart:io.File.");
            }
        } catch (e) {
             throw Exception("Gagal membaca file gambar: ${e.toString()}");
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

  /// 💬 Post Komentar (Membutuhkan Token)
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

    print("POST KOMENTAR Status: ${response.statusCode}");
    if (response.statusCode == 200 || response.statusCode == 201) {
      return true;
    }
    
    final error = jsonDecode(response.body);
    throw Exception(error['message'] ?? "Gagal mengirim komentar.");
  }
}
