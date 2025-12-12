// file: lib/models/user_model.dart

class User {
  final int id;
  final String name;
  final String email;
  final bool isOfficial;
  // DITAMBAH: Properti waktu (penting untuk konsistensi Model)
  final String createdAt;
  final String updatedAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.isOfficial,
    required this.createdAt, // DITAMBAH
    required this.updatedAt, // DITAMBAH
  });

  factory User.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      // Mengembalikan User default jika data null
      return User(
        id: 0,
        name: 'Pengguna Tak Dikenal',
        email: '',
        isOfficial: false,
        createdAt: '',
        updatedAt: '',
      );
    }
    
    // --- PENANGANAN isOfficial YANG AMAN (dari int/bool/null) ---
    final isOfficialValue = json['is_official'];
    bool officialStatus = false;
    if (isOfficialValue is bool) {
      officialStatus = isOfficialValue;
    } else if (isOfficialValue is int) {
      officialStatus = isOfficialValue == 1;
    }
    
    // --- PENANGANAN ID YANG AMAN (dari int/string/null) ---
    final idValue = json['id'];
    int parsedId = 0;
    if (idValue is int) {
      parsedId = idValue;
    } else if (idValue is String) {
      parsedId = int.tryParse(idValue) ?? 0;
    }


    return User(
      // Pastikan id selalu int, default 0
      id: parsedId,
      // Pastikan name selalu String, default 'N/A'
      name: json['name']?.toString() ?? 'N/A',
      // Pastikan email selalu String, default ''
      email: json['email']?.toString() ?? '',
      // Gunakan status yang sudah di-parse
      isOfficial: officialStatus,
      // Pastikan waktu selalu String, default ''
      createdAt: json['created_at']?.toString() ?? '', 
      updatedAt: json['updated_at']?.toString() ?? '',
    );
  }
}