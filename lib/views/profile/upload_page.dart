import 'dart:io';
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
  File? _imageFile;
  bool _isLoading = false;
  final ApiService _apiService = ApiService();

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) setState(() => _imageFile = File(picked.path));
  }

  Future<void> _submit() async {
    if (_judulController.text.isEmpty || _isiController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Semua kolom wajib diisi")));
      return;
    }
    setState(() => _isLoading = true);
    bool success = await _apiService.uploadBerita(_judulController.text, _isiController.text, _imageFile);
    setState(() => _isLoading = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Berita Berhasil Diupload")));
      Navigator.pop(context); // Kembali ke Home
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Gagal Upload")));
    }
  }

  Future<void> _logout() async {
    await _apiService.logout();
    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginPage()), (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Profil & Upload"), actions: [
        IconButton(icon: const Icon(Icons.logout), onPressed: _logout)
      ]),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Area Upload Gambar
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 180,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey),
                  image: _imageFile != null ? DecorationImage(image: FileImage(_imageFile!), fit: BoxFit.cover) : null,
                ),
                child: _imageFile == null
                    ? const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.camera_alt, size: 40, color: Colors.grey), Text("Pilih Gambar Berita")])
                    : null,
              ),
            ),
            const SizedBox(height: 20),
            TextField(controller: _judulController, decoration: const InputDecoration(labelText: "Judul Berita", border: OutlineInputBorder())),
            const SizedBox(height: 15),
            TextField(controller: _isiController, maxLines: 6, decoration: const InputDecoration(labelText: "Isi Berita", border: OutlineInputBorder(), alignLabelWithHint: true)),
            const SizedBox(height: 20),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16), backgroundColor: Colors.blueAccent, foregroundColor: Colors.white),
                    child: const Text("POSTING BERITA"),
                  ),
          ],
        ),
      ),
    );
  }
}