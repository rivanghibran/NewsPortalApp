import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../home/home_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  final TextEditingController _confirmPassController = TextEditingController();
  
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  bool _obscurePassword = true;

  Future<void> _handleRegister() async {
    // 1. Validasi Input Dasar
    if (_nameController.text.isEmpty || 
        _emailController.text.isEmpty || 
        _passController.text.isEmpty) {
      _showError('Semua kolom wajib diisi', Colors.orange);
      return;
    }

    // 2. Validasi Konfirmasi Password
    if (_passController.text != _confirmPassController.text) {
      _showError('Password konfirmasi tidak sama!', Colors.red);
      return;
    }

    // 3. Validasi Panjang Password
    if (_passController.text.length < 6) {
      _showError('Password minimal 6 karakter', Colors.red);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 4. Panggil API dengan Try-Catch
      bool success = await _apiService.register(
        _nameController.text,
        _emailController.text, 
        _passController.text
      );

      if (!mounted) return;

      if (success) {
        // SUKSES -> Masuk ke Home
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registrasi Berhasil! Selamat Datang.')),
        );

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomePage()),
          (route) => false,
        );
      } else {
        // Gagal tanpa Exception (jarang terjadi jika logic ApiService benar)
        _showError('Gagal Mendaftar. Silahkan coba lagi.', Colors.red);
      }

    } catch (e) {
      // 5. TANGKAP PESAN ERROR DARI SERVER
      if (mounted) {
        // Ini akan menampilkan pesan spesifik dari backend (misal: "Email has been taken")
        _showError(e.toString().replaceAll("Exception:", ""), Colors.red);
        print("DEBUG REGISTER ERROR: $e");
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Daftar Akun"),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                "Buat Akun Baru",
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              const Text(
                "Silahkan isi data diri Anda",
                style: TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),

              _buildTextField(_nameController, "Nama Lengkap", Icons.person),
              const SizedBox(height: 15),

              _buildTextField(_emailController, "Email", Icons.email, isEmail: true),
              const SizedBox(height: 15),

              // Password Field
              TextField(
                controller: _passController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 15),

              // Confirm Password Field
              TextField(
                controller: _confirmPassController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Ulangi Password',
                  prefixIcon: const Icon(Icons.lock_reset),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 30),

              SizedBox(
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleRegister,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text("DAFTAR SEKARANG", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool isEmail = false}) {
    return TextField(
      controller: controller,
      keyboardType: isEmail ? TextInputType.emailAddress : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}