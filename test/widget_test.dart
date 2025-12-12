import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:newsportal_app/main.dart';

void main() {
  testWidgets('App startup smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    // PERBAIKAN: Menambahkan parameter isLoggedIn (kita set false untuk tes awal)
    await tester.pumpWidget(const MyApp(isLoggedIn: false));

    // Verifikasi bahwa widget dasar aplikasi (MaterialApp) berhasil dimuat
    expect(find.byType(MaterialApp), findsOneWidget);

    // Keterangan:
    // Kode test penghitung angka (0, 1, + button) dihapus
    // karena aplikasi sudah berubah menjadi Portal Berita.
  });
}