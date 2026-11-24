import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lkm_pendataan_mahasiswa/common.dart';
import 'package:lkm_pendataan_mahasiswa/guest_page.dart';
import 'package:lkm_pendataan_mahasiswa/login_page.dart';
import 'package:lkm_pendataan_mahasiswa/mahasiswa_form.dart';

class FakeAuth extends Fake implements FirebaseAuth {
  @override
  User? get currentUser => null;
}

void main() {
  testWidgets('Login validates email and password without backend', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: LoginPage()));
    await tester.tap(find.text('Login'));
    await tester.pump();
    expect(find.text('Masukkan alamat email yang valid'), findsOneWidget);
    expect(find.text('Minimal 6 karakter'), findsOneWidget);
    await tester.tap(find.text('Belum punya akun? Daftar'));
    await tester.pump();
    expect(find.text('Daftar Mahasiswa'), findsOneWidget);
  });

  testWidgets('Guest has information but no student CRUD', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: GuestPage()));
    expect(find.text('Tamu — Informasi Umum'), findsOneWidget);
    expect(find.byType(TextFormField), findsNothing);
    expect(find.text('Tambah'), findsNothing);
    expect(find.byTooltip('Keluar'), findsOneWidget);
  });

  testWidgets('L8 dropdown has three study programs and required validation', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: MahasiswaForm(adminMode: false, auth: FakeAuth())),
    );
    await tester.tap(find.text('Simpan'));
    await tester.pump();
    expect(find.text('NIM harus 5–20 karakter'), findsOneWidget);
    expect(find.text('Nama wajib, maksimal 100 karakter'), findsOneWidget);
    expect(find.text('Prodi wajib, maksimal 80 karakter'), findsOneWidget);
    expect(find.text('Masukkan tahun 2000–2100'), findsOneWidget);
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    for (final p in [
      'Teknik Informatika',
      'Sistem Informasi',
      'Manajemen Informatika',
    ]) {
      expect(find.text(p), findsOneWidget);
    }
    await tester.tap(find.text('Manajemen Informatika'));
    await tester.pumpAndSettle();
    expect(find.text('Manajemen Informatika'), findsOneWidget);
  });

  testWidgets('User NIM locked; legacy study program preserved', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MahasiswaForm(
          adminMode: false,
          auth: FakeAuth(),
          studentId: 'user-a',
          initial: const {
            'nim': '12345',
            'nama': 'Dummy',
            'prodi': 'Fisika',
            'angkatan': 2024,
          },
        ),
      ),
    );
    final field = tester.widget<TextField>(find.byType(TextField).first);
    expect(field.readOnly, isTrue);
    expect(find.text('Fisika'), findsOneWidget);
    await tester.tap(find.text('Simpan'));
    await tester.pump();
    expect(find.text('Sesi berubah. Silakan login kembali.'), findsOneWidget);
  });

  testWidgets('Admin can edit NIM', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MahasiswaForm(
          adminMode: true,
          auth: FakeAuth(),
          studentId: 'archive',
          initial: const {
            'nim': '12345',
            'nama': 'Dummy',
            'prodi': 'Manajemen Informatika',
            'angkatan': 2024,
          },
        ),
      ),
    );
    expect(
      tester.widget<TextField>(find.byType(TextField).first).readOnly,
      isFalse,
    );
  });

  testWidgets('L9 cancel keeps session; confirm signs out once', (
    tester,
  ) async {
    var calls = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: AppBar(
            actions: [
              LogoutButton(
                onLogout: () async {
                  calls++;
                },
              ),
            ],
          ),
        ),
      ),
    );
    await tester.tap(find.byTooltip('Keluar'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();
    expect(calls, 0);
    await tester.tap(find.byTooltip('Keluar'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Keluar'));
    await tester.pumpAndSettle();
    expect(calls, 1);
  });

  testWidgets('Logout failure displayed and can retry', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: AppBar(
            actions: [
              LogoutButton(
                onLogout: () async {
                  throw FirebaseAuthException(code: 'network-request-failed');
                },
              ),
            ],
          ),
        ),
      ),
    );
    await tester.tap(find.byTooltip('Keluar'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Keluar'));
    await tester.pumpAndSettle();
    expect(
      find.text('Koneksi gagal. Periksa internet lalu coba lagi.'),
      findsOneWidget,
    );
    expect(
      tester.widget<IconButton>(find.byType(IconButton)).onPressed,
      isNotNull,
    );
  });

  testWidgets('Session change destroys private routes and dialogs', (
    tester,
  ) async {
    Widget app(String session) => MaterialApp(
      home: SessionNavigator(
        sessionKey: session,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (context) => Scaffold(
                    body: TextButton(
                      onPressed: () => showDialog<void>(
                        context: context,
                        useRootNavigator: false,
                        builder: (_) =>
                            const AlertDialog(content: Text('Private dialog')),
                      ),
                      child: const Text('Private form'),
                    ),
                  ),
                ),
              ),
              child: Text(session),
            ),
          ),
        ),
      ),
    );
    await tester.pumpWidget(app('admin'));
    await tester.tap(find.text('admin'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Private form'));
    await tester.pumpAndSettle();
    expect(find.text('Private dialog'), findsOneWidget);
    await tester.pumpWidget(app('guest'));
    await tester.pumpAndSettle();
    expect(find.text('Private dialog'), findsNothing);
    expect(find.text('Private form'), findsNothing);
    expect(find.text('guest'), findsOneWidget);
  });

  test('Permission denied retains diagnostic code', () {
    expect(
      errorMessage(
        FirebaseException(plugin: 'cloud_firestore', code: 'permission-denied'),
      ),
      contains('permission-denied'),
    );
  });
}
