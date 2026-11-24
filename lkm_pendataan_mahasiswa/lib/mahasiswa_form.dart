// Dikembangkan dari Lampiran A LKM; otorisasi final tetap pada Rules.
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'common.dart';

class MahasiswaForm extends StatefulWidget {
  final bool adminMode;
  final FirebaseAuth? auth;
  final String? studentId;
  final Map<String, dynamic>? initial;
  const MahasiswaForm({
    required this.adminMode,
    this.studentId,
    this.initial,
    this.auth,
    super.key,
  });

  @override
  State<MahasiswaForm> createState() => _MahasiswaFormState();
}

class _MahasiswaFormState extends State<MahasiswaForm> {
  final form = GlobalKey<FormState>();
  late final TextEditingController nim;
  late final TextEditingController nama;
  String? prodi;
  String? sessionUid;
  static const programStudi = [
    'Teknik Informatika',
    'Sistem Informasi',
    'Manajemen Informatika',
  ];
  late final TextEditingController angkatan;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    nim = TextEditingController(text: widget.initial?['nim'] ?? '');
    nama = TextEditingController(text: widget.initial?['nama'] ?? '');
    prodi = widget.initial?['prodi'] as String?;
    // UID diikat saat formulir dibuka, bukan saat menyimpan.
    sessionUid = (widget.auth ?? FirebaseAuth.instance).currentUser?.uid;
    angkatan = TextEditingController(
      text: widget.initial?['angkatan']?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    nim.dispose();
    nama.dispose();
    angkatan.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (saving || !form.currentState!.validate()) return;
    final user = (widget.auth ?? FirebaseAuth.instance).currentUser;
    if (sessionUid == null ||
        user?.uid != sessionUid ||
        user!.isAnonymous ||
        (!widget.adminMode &&
            widget.studentId != null &&
            widget.studentId != sessionUid)) {
      showMessage(context, 'Sesi berubah. Silakan login kembali.');
      return;
    }
    setState(() => saving = true);
    try {
      final collection = FirebaseFirestore.instance.collection('mahasiswa');
      final data = <String, dynamic>{
        'nim': !widget.adminMode && widget.studentId != null
            ? widget.initial!['nim']
            : nim.text.trim(),
        'nama': nama.text.trim(),
        'prodi': prodi!.trim(),
        'angkatan': int.parse(angkatan.text.trim()),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (widget.studentId != null) {
        await collection.doc(widget.studentId).update(data);
      } else if (widget.adminMode) {
        // Data arsip/admin tidak terkait ke akun pengguna tertentu.
        await collection.add({
          ...data,
          'ownerUid': '',
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        final uid = sessionUid!;
        await collection.doc(uid).set({
          ...data,
          'ownerUid': uid,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      if (mounted &&
          (widget.auth ?? FirebaseAuth.instance).currentUser?.uid ==
              sessionUid) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) showMessage(context, errorMessage(e));
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.studentId == null
              ? 'Tambah Data Mahasiswa'
              : 'Edit Data Mahasiswa',
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Form(
            key: form,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                TextFormField(
                  controller: nim,
                  // NIM milik akun mahasiswa bersifat tetap setelah dibuat.
                  readOnly: !widget.adminMode && widget.studentId != null,
                  decoration: const InputDecoration(labelText: 'NIM'),
                  validator: (v) =>
                      (v == null || v.trim().length < 5 || v.trim().length > 20)
                      ? 'NIM harus 5–20 karakter'
                      : null,
                ),
                TextFormField(
                  controller: nama,
                  decoration: const InputDecoration(labelText: 'Nama lengkap'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty || v.trim().length > 100)
                      ? 'Nama wajib, maksimal 100 karakter'
                      : null,
                ),
                // Nilai prodi lama tetap dapat diedit tanpa kehilangan data.
                DropdownButtonFormField<String>(
                  initialValue: prodi,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Program studi'),
                  items: {...programStudi, ?prodi}
                      .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                      .toList(),
                  onChanged: saving
                      ? null
                      : (value) => setState(() => prodi = value),
                  validator: (v) =>
                      v == null || v.trim().isEmpty || v.trim().length > 80
                      ? 'Prodi wajib, maksimal 80 karakter'
                      : null,
                ),
                TextFormField(
                  controller: angkatan,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Tahun angkatan',
                  ),
                  validator: (v) {
                    final value = int.tryParse(v ?? '');
                    if (value == null || value < 2000 || value > 2100) {
                      return 'Masukkan tahun 2000–2100';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                if (saving) const LinearProgressIndicator(),
                FilledButton.icon(
                  onPressed: saving ? null : save,
                  icon: const Icon(Icons.save),
                  label: const Text('Simpan'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
