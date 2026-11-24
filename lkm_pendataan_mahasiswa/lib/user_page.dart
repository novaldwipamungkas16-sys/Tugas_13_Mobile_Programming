// Dikembangkan dari Lampiran A LKM; otorisasi final tetap pada Rules.
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'common.dart';
import 'mahasiswa_form.dart';

class UserPage extends StatelessWidget {
  final String uid;
  const UserPage({required this.uid, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mahasiswa Terdaftar'),
        actions: [const LogoutButton()],
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('mahasiswa')
            .doc(uid)
            .snapshots(),
        builder: (context, snap) {
          if (snap.hasError) {
            return ErrorPage(message: errorMessage(snap.error!));
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snap.data!.data();
          if (data == null) {
            return Center(
              child: FilledButton.icon(
                icon: const Icon(Icons.person_add),
                label: const Text('Isi Profil Mahasiswa'),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const MahasiswaForm(adminMode: false),
                  ),
                ),
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text(
                'Data saya',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
              ),
              const SizedBox(height: 12),
              Text('NIM: ${data['nim']}'),
              Text('Nama: ${data['nama']}'),
              Text('Program Studi: ${data['prodi']}'),
              Text('Angkatan: ${data['angkatan']}'),
              const SizedBox(height: 16),
              FilledButton.icon(
                icon: const Icon(Icons.edit),
                label: const Text('Edit Data Saya'),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MahasiswaForm(
                      adminMode: false,
                      studentId: uid,
                      initial: data,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Akun mahasiswa tidak boleh melihat data mahasiswa lain.',
              ),
            ],
          );
        },
      ),
    );
  }
}
