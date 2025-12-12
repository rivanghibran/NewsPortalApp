import 'package:flutter/material.dart';
import '../../models/berita_model.dart';
import '../../services/api_service.dart';
import '../../widgets/news_card.dart';
import '../detail/detail_page.dart';
import '../profile/upload_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ApiService _apiService = ApiService();
  bool _isGridView = true; // Default Grid View

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Portal Berita", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        actions: [
          // Tombol Toggle
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
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UploadPage())),
              ),
            ),
          )
        ],
      ),
      body: FutureBuilder<List<Berita>>(
        future: _apiService.getBerita(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Gagal memuat: ${snapshot.error}"));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("Belum ada berita"));
          }

          final data = snapshot.data!;
          
          // Logika Layout GridView 3 Kolom atau ListView
          return _isGridView
              ? GridView.builder(
                  // KOREKSI: Tambahkan Key Unik untuk GridView
                  key: const PageStorageKey<String>('gridViewKey'), 
                  padding: const EdgeInsets.all(10),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3, 
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 0.65, 
                  ),
                  itemCount: data.length,
                  itemBuilder: (context, index) => NewsCard(
                    berita: data[index],
                    isGrid: true, 
                    onTap: () => _toDetail(data[index]),
                  ),
                )
              : ListView.builder(
                  // KOREKSI: Tambahkan Key Unik untuk ListView
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
    );
  }

  void _toDetail(Berita berita) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => DetailPage(beritaId: berita.id)));
  }
}