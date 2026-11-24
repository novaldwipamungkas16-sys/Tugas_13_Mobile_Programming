// Dikembangkan dari Lampiran A LKM; otorisasi final tetap pada Rules.
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'common.dart';
import 'mahasiswa_form.dart';

class AdminPage extends StatelessWidget {
  const AdminPage({super.key});

  Future<void> deleteDoc(BuildContext context, String id) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final confirm = await showDialog<bool>(
      useRootNavigator: false,
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus data?'),
        content: const Text('Data mahasiswa ini akan dihapus dari Firestore.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirm != true ||
        !context.mounted ||
        uid == null ||
        FirebaseAuth.instance.currentUser?.uid != uid) {
      return;
    }
    try {
      await FirebaseFirestore.instance.collection('mahasiswa').doc(id).delete();
      if (context.mounted) showMessage(context, 'Data berhasil dihapus');
    } catch (e) {
      if (context.mounted) showMessage(context, errorMessage(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin — Data Mahasiswa'),
        actions: [const LogoutButton()],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const MahasiswaForm(adminMode: true),
          ),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Tambah'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('mahasiswa')
            .orderBy('nama')
            .snapshots(),
        builder: (context, snap) {
          if (snap.hasError) {
            return ErrorPage(message: errorMessage(snap.error!));
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snap.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text('Belum ada data mahasiswa.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 90),
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final doc = docs[i];
              final data = doc.data();
              return Card(
                child: ListTile(
                  title: Text('${data['nama']} — ${data['nim']}'),
                  subtitle: Text(
                    '${data['prodi']} • Angkatan ${data['angkatan']}',
                  ),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MahasiswaForm(
                        adminMode: true,
                        studentId: doc.id,
                        initial: data,
                      ),
                    ),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    tooltip: 'Hapus',
                    onPressed: () => deleteDoc(context, doc.id),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
