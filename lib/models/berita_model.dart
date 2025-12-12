// file: lib/models/berita_model.dart

import 'user_model.dart';
import 'komentar_model.dart';

class Berita {
  final int id;
  final String judul;
  final String isi;
  final String? gambarUrl; 
  final String createdAt;
  final User user;
  final List<Komentar> komentars;
  final int totalKomentar;

  Berita({
    required this.id,
    required this.judul,
    required this.isi,
    this.gambarUrl, 
    required this.createdAt,
    required this.user,
    this.komentars = const [],
    this.totalKomentar = 0,
  });

  factory Berita.fromJson(Map<String, dynamic> json) {
    // --- PENANGANAN ID YANG AMAN ---
    final idValue = json['id'];
    int parsedId = 0;
    if (idValue is int) {
      parsedId = idValue;
    } else if (idValue is String) {
      parsedId = int.tryParse(idValue) ?? 0;
    }

    // --- PENANGANAN KOMENTAR (Relasi) ---
    var listKomentarJson = json['komentars'];
    List<Komentar> komentarList = [];
    if (listKomentarJson is List) {
      komentarList = listKomentarJson
          .whereType<Map<String, dynamic>>() // Filter dan pastikan hanya Map yang diproses
          .map((i) => Komentar.fromJson(i))
          .toList();
    }

    // --- PENANGANAN TOTAL KOMENTAR ---
    final totalKomentarValue = json['komentars_count'];
    int parsedTotalKomentar = 0;
    if (totalKomentarValue is int) {
      parsedTotalKomentar = totalKomentarValue;
    } else {
      parsedTotalKomentar = komentarList.length;
    }
    
    // --- PENANGANAN USER (Relasi) ---
    final userData = json['user'];

    return Berita(
      id: parsedId,
      // Pastikan semua String wajib memiliki fallback
      judul: json['judul']?.toString() ?? 'Judul Tidak Ada',
      isi: json['isi']?.toString() ?? 'Isi berita tidak tersedia.',
      
      // gambarUrl boleh null, jadi tidak perlu fallback String
      gambarUrl: json['gambar_url']?.toString() ?? json['gambar']?.toString(), 
      
      createdAt: json['created_at']?.toString() ?? '',
      
      // User: Pastikan User.fromJson menerima Map<String, dynamic> atau null
      // Jika userData adalah Map<String, dynamic>, kirimkan; jika null/lain, kirimkan null
      user: User.fromJson(userData is Map<String, dynamic> ? userData : null), 
      
      komentars: komentarList, 
      totalKomentar: parsedTotalKomentar,
    );
  }
}