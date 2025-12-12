import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../models/berita_model.dart';

class NewsCard extends StatelessWidget {
  final Berita berita;
  final bool isGrid;
  final VoidCallback onTap;

  const NewsCard({super.key, required this.berita, required this.isGrid, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // gambarUrl Berita
            Expanded(
              flex: isGrid ? 3 : 2,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      berita.gambarUrl ?? '',
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, err, stack) => Container(
                        color: Colors.grey[200],
                        child: const Icon(Icons.broken_image, color: Colors.grey),
                      ),
                    ),
                    // Label "NEWS" di pojok
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: AppConstants.cnnRed, borderRadius: BorderRadius.circular(4)),
                        child: const Text("NEWS", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    )
                  ],
                ),
              ),
            ),
            // Judul & Info
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      berita.judul ?? "Tanpa Judul",
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppConstants.headlineStyle.copyWith(fontSize: isGrid ? 14 : 16),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        const Icon(Icons.access_time, size: 12, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          "Baru saja", // Anda bisa pakai intl date format nanti
                          style: TextStyle(color: Colors.grey[600], fontSize: 11),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}