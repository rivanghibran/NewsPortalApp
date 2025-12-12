import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../models/berita_model.dart';
import '../../services/api_service.dart';
import '../../widgets/news_card.dart';
import '../detail/detail_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ApiService _apiService = ApiService();
  late Future<List<Berita>> _futureBerita;
  bool _isGridView = true;

  @override
  void initState() {
    super.initState();
    _futureBerita = _apiService.getBerita();
  }

  Future<void> _refreshData() async {
    setState(() {
      _futureBerita = _apiService.getBerita();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.cnnLightGrey,
      appBar: AppBar(
        title: const Text("NAVIR NEWS PORTAL", style: TextStyle(fontFamily: 'Roboto', fontWeight: FontWeight.w900, letterSpacing: 2)),
        actions: [
          IconButton(
            icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view),
            onPressed: () => setState(() => _isGridView = !_isGridView),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppConstants.cnnRed,
        onRefresh: _refreshData,
        child: FutureBuilder<List<Berita>>(
          future: _futureBerita,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: AppConstants.cnnRed));
            } else if (snapshot.hasError) {
              return Center(child: Text("Gagal memuat berita", style: TextStyle(color: Colors.grey[600])));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text("Belum ada berita terkini"));
            }

            final data = snapshot.data!;
            
            if (_isGridView) {
              return GridView.builder(
                padding: const EdgeInsets.all(12),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.75, // Kartu lebih tinggi
                ),
                itemCount: data.length,
                itemBuilder: (ctx, index) => NewsCard(berita: data[index], isGrid: true, onTap: () => _toDetail(data[index])),
              );
            } else {
              return ListView.separated(
                padding: const EdgeInsets.all(12),
                separatorBuilder: (ctx, i) => const SizedBox(height: 12),
                itemCount: data.length,
                itemBuilder: (ctx, index) => NewsCard(berita: data[index], isGrid: false, onTap: () => _toDetail(data[index])),
              );
            }
          },
        ),
      ),
    );
  }

  void _toDetail(Berita berita) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => DetailPage(beritaId: berita.id!)));
    _refreshData();
  }
}