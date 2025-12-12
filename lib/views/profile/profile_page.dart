import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/berita_model.dart';
import '../../services/api_service.dart';
import '../auth/login_page.dart';
import '../detail/detail_page.dart';
// Pastikan import constants ada jika ingin menggunakan warna dari AppConstants
// import '../../core/constants.dart'; 

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final ApiService _apiService = ApiService();
  String _userName = "Loading...";
  String _userEmail = "";
  int? _userId;
  late Future<List<Berita>> _futureMyPosts;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    // Kita panggil semua berita, nanti difilter berdasarkan userId
    _futureMyPosts = _apiService.getBerita(); 
  }

  Future<void> _loadUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('userName') ?? "Pengguna";
      _userEmail = prefs.getString('userEmail') ?? "";
      _userId = prefs.getInt('userId');
    });
  }

  Future<void> _logout() async {
    await _apiService.logout();
    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()), 
      (route) => false
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          _userName, 
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu, color: Colors.black),
            onPressed: () {
              // Tampilkan opsi Logout di BottomSheet
              showModalBottomSheet(context: context, builder: (ctx) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(Icons.logout, color: Color(0xFFCC0000)), // Merah CNN
                    title: const Text("Keluar", style: TextStyle(color: Color(0xFFCC0000))),
                    onTap: _logout,
                  )
                ],
              ));
            },
          )
        ],
      ),
      body: DefaultTabController(
        length: 2,
        child: NestedScrollView(
          headerSliverBuilder: (context, _) {
            return [
              SliverList(
                delegate: SliverChildListDelegate([
                  _buildProfileHeader(),
                ]),
              ),
            ];
          },
          body: Column(
            children: [
              const TabBar(
                indicatorColor: Color(0xFFCC0000), // Indicator Merah
                labelColor: Color(0xFFCC0000),     // Icon Aktif Merah
                unselectedLabelColor: Colors.grey,
                tabs: [
                  Tab(icon: Icon(Icons.grid_on)),
                  Tab(icon: Icon(Icons.assignment_ind_outlined)),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _buildMyPostsGrid(),
                    const Center(child: Text("Foto yang menandai Anda")),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 40,
                backgroundColor: Colors.grey[300],
                child: Text(
                  _userName.isNotEmpty ? _userName[0].toUpperCase() : "U",
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.grey),
                ),
              ),
              const SizedBox(width: 20),
              // Stats
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatItem("0", "Postingan"), 
                    _buildStatItem("1.2K", "Pengikut"),
                    _buildStatItem("500", "Mengikuti"),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(_userName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          Text(_userEmail, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 16),
          // Tombol Edit Profile
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.grey.shade300),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text("Edit Profil", style: TextStyle(color: Colors.black)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildMyPostsGrid() {
    return FutureBuilder<List<Berita>>(
      future: _futureMyPosts,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFFCC0000)));
        }
        
        // Filter berita yang dibuat oleh user ini
        final allBerita = snapshot.data ?? [];
        
        // --- PERBAIKAN DI SINI ---
        // Menggunakan 'b.user.id' bukan 'b.userId'
        final myPosts = _userId == null 
            ? <Berita>[] 
            : allBerita.where((b) => b.user.id == _userId).toList();

        if (myPosts.isEmpty) {
          return const Center(child: Text("Belum ada postingan"));
        }

        return GridView.builder(
          padding: const EdgeInsets.all(2),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 2,
            mainAxisSpacing: 2,
          ),
          itemCount: myPosts.length,
          itemBuilder: (context, index) {
            final berita = myPosts[index];
            return GestureDetector(
              // 'berita.id' sudah int, tidak perlu tanda seru '!'
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DetailPage(beritaId: berita.id))),
              child: Container(
                color: Colors.grey[200],
                child: berita.gambarUrl != null 
                    ? Image.network(berita.gambarUrl!, fit: BoxFit.cover)
                    : const Center(child: Icon(Icons.article, color: Colors.grey)),
              ),
            );
          },
        );
      },
    );
  }
}