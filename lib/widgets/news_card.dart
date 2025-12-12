import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/berita_model.dart';
// import '../detail/detail_page.dart'; // Tidak perlu diimport di sini

class NewsCard extends StatelessWidget {
  final Berita berita;
  final bool isGrid; // Properti untuk memilih mode tampilan
  final VoidCallback onTap; // Callback untuk navigasi ke detail

  const NewsCard({
    super.key,
    required this.berita,
    required this.isGrid,
    required this.onTap,
  });

  // Helper untuk mendapatkan URL gambar yang aman
  String? get imageUrl => berita.gambarUrl;

  @override
  Widget build(BuildContext context) {
    // Pastikan GestureDetector memiliki key unik jika diperlukan untuk List/Grid yang kompleks
    return GestureDetector(
      onTap: onTap,
      child: isGrid ? _buildGridCard(context) : _buildListCard(context),
    );
  }

  // =================================================================
  // 1. Tampilan LIST (isGrid: false) - Tampilan besar 1 kolom
  // =================================================================

  Widget _buildListCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Gambar Kiri
          ClipRRect(
            borderRadius: const BorderRadius.horizontal(left: Radius.circular(10)),
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.35, // Width eksplisit
              height: 120, // Tinggi tetap (fixed height)
              child: imageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: imageUrl!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(color: Colors.grey[200]),
                      errorWidget: (context, url, error) => Container(color: Colors.grey, child: const Icon(Icons.error, size: 30)),
                    )
                  : Container(color: Colors.grey, child: const Icon(Icons.image, color: Colors.white)),
            ),
          ),
          
          // Konten Teks Kanan
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    berita.judul,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    // Pastikan teks isi aman dari null atau empty
                    berita.isi.isNotEmpty ? berita.isi : 'Tidak ada deskripsi singkat.', 
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Oleh ${berita.user.name} | ${berita.createdAt}',
                    style: const TextStyle(fontSize: 10, color: Colors.blueGrey),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }


  // =================================================================
  // 2. Tampilan GRID (isGrid: true) - Tampilan kecil 3 kolom
  // =================================================================

  Widget _buildGridCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Gambar (Thumbnail) - Menggunakan Expanded agar sisa ruang untuk teks
          Expanded( 
            flex: 6, // Gambar mengambil lebih banyak ruang
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
              child: SizedBox.expand(
                child: imageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: imageUrl!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(color: Colors.grey[200]),
                        errorWidget: (context, url, error) => Container(color: Colors.grey, child: const Icon(Icons.error_outline, size: 20)),
                      )
                    : Container(
                        color: Colors.grey,
                        child: Center(
                            child: Icon(Icons.image_not_supported_outlined, color: Colors.white.withOpacity(0.7), size: 30)
                        ),
                      ),
              ),
            ),
          ),
          
          // 2. Konten Teks Ringkas
          Expanded( // Teks mengambil sisa ruang
            flex: 4, 
            child: Padding(
              padding: const EdgeInsets.all(6.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center, // Pusatkan teks vertikal
                children: [
                  // Judul Berita (Maks 2 Baris)
                  Text(
                    berita.judul,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Info Tambahan (Komentar)
                  Text(
                    '${berita.totalKomentar} Komentar',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}