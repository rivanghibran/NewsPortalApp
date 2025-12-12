// file: lib/models/komentar_model.dart
import 'user_model.dart';

class Komentar {
  final int id;
  final String isi;
  final User user; // Relasi ke Model User

  Komentar({
    required this.id, 
    required this.isi, 
    required this.user
  });

  factory Komentar.fromJson(Map<String, dynamic> json) {
    // Pastikan ID di-parse dengan aman
    final idValue = json['id'];
    int parsedId = 0;

    if (idValue is int) {
      parsedId = idValue;
    } else if (idValue is String) {
      parsedId = int.tryParse(idValue) ?? 0;
    }

    // Menggunakan User.fromJson dengan null check
    final userData = json['user'];

    return Komentar(
      id: parsedId,
      isi: json['isi']?.toString() ?? '', 
      // Menggunakan User.fromJson yang sudah aman dari null
      user: User.fromJson(userData),
    );
  }
}