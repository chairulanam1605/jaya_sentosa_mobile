import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';
import 'edit_profile_screen.dart';

class ProfileDetailScreen extends StatefulWidget {
  const ProfileDetailScreen({super.key});

  @override
  State<ProfileDetailScreen> createState() => _ProfileDetailScreenState();
}

class _ProfileDetailScreenState extends State<ProfileDetailScreen> {
  File? _imageFile;
  bool _isUploading = false;

  // =========================================================
  // VARIABEL CACHE UNTUK MENCEGAH LAYAR MERAH (NULL ERROR)
  // =========================================================
  String _userName = 'Memuat...';
  String _userEmail = '-';
  String _userPhone = '-';
  String _userCustomerNumber = '-';
  DateTime _userSince = DateTime.now();
  String _fotoUrl = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // =========================================================
  // MENYIMPAN DAN MENARIK DATA PROFIL DARI MEMORI HP
  // =========================================================
  Future<void> _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final user = AuthService.currentUser;

    if (user != null) {
      await prefs.setString('cache_fullName', user.fullName);
      await prefs.setString('cache_email', user.email);
      await prefs.setString('cache_phone', user.phone);
      await prefs.setString('cache_customerNumber', user.customerNumber ?? '-');
      await prefs.setString('cache_since', user.since.toIso8601String());
      await prefs.setString('cache_fotoProfile', user.fotoProfile ?? '');
    }

    setState(() {
      _userName = prefs.getString('cache_fullName') ?? 'Pelanggan JSG';
      _userEmail = prefs.getString('cache_email') ?? '-';
      _userPhone = prefs.getString('cache_phone') ?? '-';
      _userCustomerNumber = prefs.getString('cache_customerNumber') ?? '-';
      _fotoUrl = prefs.getString('cache_fotoProfile') ?? '';
      
      String? sinceStr = prefs.getString('cache_since');
      if (sinceStr != null && sinceStr.isNotEmpty) {
        _userSince = DateTime.parse(sinceStr);
      }
    });

    _loadSavedImage();
  }

  Future<void> _loadSavedImage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedPath = prefs.getString('profile_image_path');

    if (savedPath != null && savedPath.isNotEmpty) {
      File img = File(savedPath);
      if (await img.exists()) {
        setState(() {
          _imageFile = img;
        });
      }
    }
  }

  Future<void> _refreshData() async {
    await _loadUserData();
    setState(() {});
    await Future.delayed(const Duration(seconds: 1));
  }

  void _showImageSourceMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Column(
                  children: [
                    const Text('Pilih Sumber Foto', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    ListTile(
                      leading: const Icon(Icons.camera_alt_rounded, color: Color(0xFF1E3A8A)),
                      title: const Text('Ambil dari Kamera', style: TextStyle(fontWeight: FontWeight.w600)),
                      onTap: () {
                        Navigator.of(context).pop();
                        _pickAndUploadImage(ImageSource.camera);
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.photo_library_rounded, color: Color(0xFF1E3A8A)),
                      title: const Text('Pilih dari Galeri', style: TextStyle(fontWeight: FontWeight.w600)),
                      onTap: () {
                        Navigator.of(context).pop();
                        _pickAndUploadImage(ImageSource.gallery);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickAndUploadImage(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: source, imageQuality: 70);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
        _isUploading = true;
      });

      SharedPreferences prefs = await SharedPreferences.getInstance();
      String userId = prefs.getString('user_id') ?? '';

      if (userId.isNotEmpty) {
        bool success = await ApiService.uploadProfilePicture(userId, _imageFile!);

        if (mounted) {
          setState(() {
            _isUploading = false;
          });

          if (success) {
            prefs.setString('profile_image_path', pickedFile.path);
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(success ? 'Foto profil berhasil diperbarui!' : 'Gagal mengupload foto.'),
              backgroundColor: success ? Colors.green : Colors.red,
            ),
          );
        }
      } else {
        if (mounted) {
          setState(() => _isUploading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 🚀 SUDAH DIHAPUS: Final user = AuthService.currentUser! yang menyebabkan error layar merah

    final String fullImageUrl = _fotoUrl.isNotEmpty ? 'https://adminjsg.com/public/storage/profil/$_fotoUrl' : '';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Detail Profile', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF1E3A8A),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshData,
          color: const Color(0xFF1E3A8A),
          backgroundColor: Colors.white,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
                      ),
                      child: CircleAvatar(
                        radius: 55,
                        backgroundColor: const Color(0xFFE2E8F0),
                        backgroundImage: _imageFile != null
                            ? FileImage(_imageFile!)
                            : (fullImageUrl.isNotEmpty ? NetworkImage(fullImageUrl) as ImageProvider : null),
                        child: _imageFile == null && fullImageUrl.isEmpty
                            ? const Icon(Icons.person, size: 60, color: Color(0xFF1E3A8A))
                            : null,
                      ),
                    ),
                    if (_isUploading) const Positioned.fill(child: CircularProgressIndicator(color: Color(0xFF1E3A8A))),
                    if (!_isUploading)
                      Positioned(
                        bottom: 4,
                        right: 4,
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(30),
                            onTap: _showImageSourceMenu,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: const Color(0xFF1E3A8A), shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                              child: const Icon(Icons.camera_alt_rounded, size: 20, color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  _userName, // 🚀 MENGAMBIL NAMA DARI CACHE
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(20)),
                  child: Text(
                    'Pelanggan sejak ${_formatDate(_userSince)}',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.green),
                  ),
                ),
                const SizedBox(height: 32),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Informasi Pribadi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: Column(
                    children: [
                      _buildInfoRow(Icons.person_outline, 'Nama Lengkap', _userName),
                      const Divider(height: 1, indent: 50, color: Color(0xFFF1F5F9)),
                      _buildInfoRow(Icons.confirmation_number_outlined, 'Nomor Pelanggan', _userCustomerNumber),
                      const Divider(height: 1, indent: 50, color: Color(0xFFF1F5F9)),
                      _buildInfoRow(Icons.email_outlined, 'Alamat Email', _userEmail),
                      const Divider(height: 1, indent: 50, color: Color(0xFFF1F5F9)),
                      _buildInfoRow(Icons.phone_outlined, 'Nomor Telepon', _userPhone),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () async {
                      await Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen()));
                      _loadUserData(); // 🚀 Refresh data sepulang dari halaman ubah profil
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF1E3A8A),
                      side: const BorderSide(color: Color(0xFF1E3A8A), width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    child: const Text('UBAH DATA PROFIL', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                  ),
                ),
                const SizedBox(height: 24),
                Center(
                  child: Text('Versi ${Constants.version} · Jaya Sentosa Mobile', style: TextStyle(fontSize: 12, color: Colors.black.withOpacity(0.4))),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: const Color(0xFF1E3A8A), size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${_getMonthName(date.month)} ${date.year}';
  }

  String _getMonthName(int month) {
    const months = ['Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni', 'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'];
    return months[month - 1];
  }
}