// Dikembangkan dari Lampiran A LKM; otorisasi final tetap pada Rules.
import 'package:flutter/material.dart';

import 'common.dart';

class GuestPage extends StatelessWidget {
  const GuestPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tamu — Informasi Umum'),
        actions: [const LogoutButton()],
      ),
      body: const Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Selamat datang!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Text(
              'Ini adalah halaman informasi umum untuk tamu. '
              'Tamu tidak dapat melihat atau mengubah data pribadi mahasiswa.',
            ),
            SizedBox(height: 10),
            Text(
              'Silakan keluar, kemudian daftar/login untuk mengisi data sendiri.',
            ),
          ],
        ),
      ),
    );
  }
}
