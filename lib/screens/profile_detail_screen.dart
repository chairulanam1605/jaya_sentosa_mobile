// lib/screens/profile_detail_screen.dart
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../utils/constants.dart';
import 'edit_profile_screen.dart';

class ProfileDetailScreen extends StatelessWidget {
  const ProfileDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = AuthService.currentUser!;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // Latar belakang abu-abu terang
      appBar: AppBar(
        title: const Text(
          'Detail Profile',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF1E3A8A),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // --- SECTION FOTO PROFIL & TOMBOL UBAH ---
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const CircleAvatar(
                      radius: 55,
                      backgroundColor: Color(0xFFE2E8F0),
                      child: Icon(Icons.person, size: 60, color: Color(0xFF1E3A8A)),
                    ),
                  ),
                  // Tombol Kamera untuk ganti foto
                  Positioned(
                    bottom: 4,
                    right: 4,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(30),
                        onTap: () {
                          // TODO: Tambahkan fungsi upload/pilih gambar di sini
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Fitur ubah foto belum tersedia')),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E3A8A),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(
                            Icons.camera_alt_rounded,
                            size: 20,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              Text(
                user.fullName,
                style: const TextStyle(
                  fontSize: 24, 
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Pelanggan sejak ${_formatDate(user.since)}',
                  style: const TextStyle(
                    fontSize: 13, 
                    fontWeight: FontWeight.w600,
                    color: Colors.green,
                  ),
                ),
              ),
              
              const SizedBox(height: 32),

              // --- SECTION DATA AKUN (CARD STYLE) ---
              Align(
                alignment: Alignment.centerLeft,
                child: const Text(
                  'Informasi Pribadi',
                  style: TextStyle(
                    fontSize: 18, 
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildInfoRow(Icons.person_outline, 'Nama Lengkap', user.fullName),
                    const Divider(height: 1, indent: 50, color: Color(0xFFF1F5F9)),
                    _buildInfoRow(Icons.confirmation_number_outlined, 'Nomor Pelanggan', user.customerNumber),
                    const Divider(height: 1, indent: 50, color: Color(0xFFF1F5F9)),
                    _buildInfoRow(Icons.email_outlined, 'Alamat Email', user.email),
                    const Divider(height: 1, indent: 50, color: Color(0xFFF1F5F9)),
                    _buildInfoRow(Icons.phone_outlined, 'Nomor Telepon', user.phone),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),

              // --- SECTION TOMBOL UBAH PROFIL ---
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF1E3A8A),
                    side: const BorderSide(color: Color(0xFF1E3A8A), width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    'UBAH DATA PROFIL',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              Center(
                child: Text(
                  'Versi ${Constants.version} · Jaya Sentosa Mobile',
                  style: TextStyle(fontSize: 12, color: Colors.black.withOpacity(0.4)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper widget untuk baris data dengan Ikon
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9), // Latar ikon abu-abu kebiruan
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFF1E3A8A), size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12, 
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
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
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return months[month - 1];
  }
}