import 'package:flutter/material.dart';
import '../../models/berita_model.dart';
import '../../services/api_service.dart';
import '../../widgets/news_card.dart';
import '../detail/detail_page.dart';
import '../profile/upload_page.dart';
// Import untuk refresh
import 'dart:async'; 

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ApiService _apiService = ApiService();
  bool _isGridView = true;
  
  // 1. Tambahkan Future untuk menyimpan status pemuatan data
  late Future<List<Berita>> _futureBerita;

  @override
  void initState() {
    super.initState();
    // Panggil pemuatan data awal
    _futureBerita = _apiService.getBerita(); 
  }

  // 2. Fungsi untuk memuat ulang data (dipanggil oleh tombol Refresh dan setelah kembali dari halaman lain)
  Future<void> _refreshData() async {
    setState(() {
      _futureBerita = _apiService.getBerita();
    });
  }

  // 3. Navigasi ke Detail Page dengan Refresh (Penting!)
  void _toDetail(Berita berita) async {
    // Navigasi ke DetailPage
    await Navigator.push(
      context, 
      MaterialPageRoute(
        builder: (_) => DetailPage(beritaId: berita.id!) // Pastikan berita.id tidak null
      )
    );
    // Setelah kembali dari DetailPage (misal setelah komen/edit), refresh data
    _refreshData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Portal Berita", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 1, // Beri sedikit bayangan agar terpisah dari body
        foregroundColor: Colors.black,
        actions: [
          // Tombol Refresh
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
            tooltip: "Muat Ulang Berita",
          ),
          // Tombol Toggle View
          IconButton(
            icon: Icon(_isGridView ? Icons.view_list_rounded : Icons.grid_view_rounded),
            onPressed: () => setState(() => _isGridView = !_isGridView),
            tooltip: "Ubah Tampilan",
          ),
          // Tombol Profile/Upload
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: CircleAvatar(
              backgroundColor: Colors.blueAccent,
              child: IconButton(
                icon: const Icon(Icons.person, color: Colors.white),
                onPressed: () async {
                   // Refresh data setelah kembali dari UploadPage
                   await Navigator.push(context, MaterialPageRoute(builder: (_) => const UploadPage()));
                   _refreshData();
                },
              ),
            ),
          )
        ],
      ),
      // Menggunakan RefreshIndicator agar bisa pull-to-refresh
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: FutureBuilder<List<Berita>>(
          // Gunakan _futureBerita yang sudah diinisialisasi
          future: _futureBerita, 
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              // Menampilkan tombol refresh jika error
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Gagal memuat: ${snapshot.error}"),
                    TextButton(onPressed: _refreshData, child: const Text("Coba Lagi"))
                  ],
                ),
              );
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                // Tambahkan ListView kosong untuk pull-to-refresh tetap berfungsi
                child: ListView(
                  children: const [
                    SizedBox(height: 150),
                    Center(child: Text("Belum ada berita yang tersedia.")),
                  ],
                ),
              );
            }

            final data = snapshot.data!;
            
            return _isGridView
                ? GridView.builder(
                    key: const PageStorageKey<String>('gridViewKey'),
                    padding: const EdgeInsets.all(10),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3, 
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 0.65, // Sesuaikan rasio ini
                    ),
                    itemCount: data.length,
                    itemBuilder: (context, index) => NewsCard(
                      berita: data[index],
                      isGrid: true, 
                      onTap: () => _toDetail(data[index]),
                    ),
                  )
                : ListView.builder(
                    key: const PageStorageKey<String>('listViewKey'),
                    padding: const EdgeInsets.all(12),
                    itemCount: data.length,
                    itemBuilder: (context, index) => NewsCard(
                      berita: data[index],
                      isGrid: false, 
                      onTap: () => _toDetail(data[index]),
                    ),
                  );
          },
        ),
      ),
    );
  }
}