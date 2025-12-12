import 'dart:io'; // Untuk File (Mobile)
import 'dart:typed_data'; // Untuk Uint8List (Web)

import 'package:flutter/foundation.dart'; // Untuk kIsWeb
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/api_service.dart';
import '../auth/login_page.dart';

class UploadPage extends StatefulWidget {
  const UploadPage({super.key});

  @override
  State<UploadPage> createState() => _UploadPageState();
}

class _UploadPageState extends State<UploadPage> {
  final _judulController = TextEditingController();
  final _isiController = TextEditingController();
  
  // Variabel terpisah untuk Mobile dan Web
  File? _mobileImage; 
  Uint8List? _webImage;

  bool _isLoading = false;
  final ApiService _apiService = ApiService();

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? picked = await picker.pickImage(source: ImageSource.gallery);
    
    if (picked != null) {
      if (kIsWeb) {
        // LOGIKA WEB: Baca sebagai Bytes (Uint8List)
        final bytes = await picked.readAsBytes();
        setState(() {
          _webImage = bytes;
          _mobileImage = null; // Reset mobile
        });
      } else {
        // LOGIKA MOBILE: Baca sebagai File Path
        setState(() {
          _mobileImage = File(picked.path);
          _webImage = null; // Reset web
        });
      }
    }
  }

  Future<void> _submit() async {
    if (_judulController.text.isEmpty || _isiController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Semua kolom wajib diisi"))
      );
      return;
    }

    setState(() => _isLoading = true);

    // Tentukan file mana yang dikirim ke ApiService
    // ApiService Anda sudah saya buat pintar untuk menerima keduanya
    dynamic imageToSend = kIsWeb ? _webImage : _mobileImage;

    try {
      bool success = await _apiService.uploadBerita(
        _judulController.text, 
        _isiController.text, 
        imageToSend
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Berita Berhasil Diupload"))
        );
        Navigator.pop(context); // Kembali ke Home dan refresh
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal Upload: ${e.toString().replaceAll('Exception: ', '')}"), backgroundColor: Colors.red,)
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    await _apiService.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context, 
      MaterialPageRoute(builder: (_) => const LoginPage()), 
      (route) => false
    );
  }

  @override
  Widget build(BuildContext context) {
    // Helper untuk menentukan ImageProvider yang dipakai di UI
    ImageProvider? imageProvider;
    if (kIsWeb && _webImage != null) {
      imageProvider = MemoryImage(_webImage!);
    } else if (!kIsWeb && _mobileImage != null) {
      imageProvider = FileImage(_mobileImage!);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Upload Berita"),
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout)
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Area Upload Gambar
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey),
                  image: imageProvider != null 
                      ? DecorationImage(image: imageProvider, fit: BoxFit.cover) 
                      : null,
                ),
                child: imageProvider == null
                    ? const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate, size: 50, color: Colors.grey),
                          SizedBox(height: 10),
                          Text("Ketuk untuk pilih gambar", style: TextStyle(color: Colors.grey))
                        ],
                      )
                    : null,
              ),
            ),
            
            const SizedBox(height: 20),
            TextField(
              controller: _judulController, 
              decoration: const InputDecoration(
                labelText: "Judul Berita", 
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.title)
              )
            ),
            
            const SizedBox(height: 15),
            TextField(
              controller: _isiController, 
              maxLines: 6, 
              decoration: const InputDecoration(
                labelText: "Isi Berita", 
                border: OutlineInputBorder(), 
                alignLabelWithHint: true
              )
            ),
            
            const SizedBox(height: 20),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent, 
                  foregroundColor: Colors.white
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("POSTING BERITA", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}