import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/berita_model.dart';
import '../../services/api_service.dart';

class DetailPage extends StatefulWidget {
  final int beritaId;
  const DetailPage({super.key, required this.beritaId});

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  final ApiService _apiService = ApiService();
  final TextEditingController _commentController = TextEditingController();
  final ScrollController _scrollController = ScrollController(); 
  
  late Future<Berita> _futureBerita;
  bool _isSendingComment = false; 
  
  // =================================================================
  // LIFECYCLE & DATA
  // =================================================================

  @override
  void initState() {
    super.initState();
    _refreshData();
  }
  
  @override
  void dispose() {
    _scrollController.dispose(); 
    _commentController.dispose();
    super.dispose();
  }

  void _refreshData() {
    setState(() {
      _futureBerita = _apiService.getDetailBerita(widget.beritaId);
    });
  }

  // =================================================================
  // COMMENT LOGIC
  // =================================================================

  // Metode untuk menggeser ke bagian bawah (komentar baru)
  void _scrollToComments() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent, 
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendComment() async {
    if (_commentController.text.isEmpty || _isSendingComment) return;
    
    final commentText = _commentController.text;

    setState(() {
      _isSendingComment = true; // Tampilkan loading
    });
    
    try {
      bool success = await _apiService.postKomentar(widget.beritaId, commentText);

      if (success) {
        _commentController.clear();
        
        // 1. Refresh data dari server (memuat ulang list komentar)
        _refreshData(); 
        
        // 2. Gunakan addPostFrameCallback untuk menunggu FutureBuilder selesai me-rebuild
        // Ini lebih andal daripada Future.delayed
        WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollToComments();
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Komentar terkirim!"))
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Gagal mengirim komentar. Coba lagi."))
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"))
      );
    } finally {
      setState(() {
        _isSendingComment = false; // Sembunyikan loading
      });
    }
  }

  // =================================================================
  // BUILD METHOD
  // =================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<Berita>(
        future: _futureBerita,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return Center(child: Text("Error memuat detail: ${snapshot.error}"));

          final berita = snapshot.data!;
          return Column(
            children: [
              Expanded(
                child: CustomScrollView(
                  controller: _scrollController, 
                  slivers: [
                    // Header Gambar Parallax
                    SliverAppBar(
                      expandedHeight: 250.0,
                      floating: false,
                      pinned: true,
                      flexibleSpace: FlexibleSpaceBar(
                        title: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(4)),
                          child: Text(berita.judul, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis),
                        ),
                        // Menggunakan gambarUrl (sudah diperbaiki)
                        background: berita.gambarUrl != null
                            ? CachedNetworkImage(imageUrl: berita.gambarUrl!, fit: BoxFit.cover)
                            : Container(color: Colors.grey),
                      ),
                    ),
                    // Konten Berita
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Info Penulis dengan Badge Official
                            Row(
                              children: [
                                CircleAvatar(child: Text(berita.user.name[0])),
                                const SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(berita.user.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                        if (berita.user.isOfficial)
                                          const Padding(
                                            padding: EdgeInsets.only(left: 4),
                                            child: Icon(Icons.verified, color: Colors.blue, size: 16),
                                          ),
                                      ],
                                    ),
                                    Text(berita.createdAt, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                  ],
                                )
                              ],
                            ),
                            const Divider(height: 30),
                            Text(berita.isi, style: const TextStyle(fontSize: 16, height: 1.6)),
                            const SizedBox(height: 20),
                            const Text("Komentar", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 10),
                            // List Komentar
                            if (berita.komentars.isEmpty) const Text("Belum ada komentar", style: TextStyle(color: Colors.grey)),
                            ...berita.komentars.map((k) => ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: CircleAvatar(radius: 14, backgroundColor: Colors.grey[200], child: Text(k.user.name[0], style: const TextStyle(fontSize: 12))),
                                  title: Text(k.user.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                  subtitle: Text(k.isi),
                                )),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Input Komentar di Bawah
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: const Offset(0, -2))]),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _commentController,
                        decoration: const InputDecoration(hintText: "Tulis komentar...", border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 10)),
                        enabled: !_isSendingComment, // Nonaktifkan saat mengirim
                      ),
                    ),
                    _isSendingComment
                        ? const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12.0),
                            child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 3)),
                          )
                        : IconButton(
                            icon: const Icon(Icons.send, color: Colors.blue),
                            onPressed: _sendComment,
                          ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}