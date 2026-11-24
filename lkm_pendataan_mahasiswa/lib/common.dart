import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

String errorMessage(Object error) {
  if (error is FirebaseException) {
    return switch (error.code) {
      'permission-denied' =>
        'Akses ditolak (permission-denied). Periksa hak akses dan Rules.',
      'network-request-failed' ||
      'unavailable' => 'Koneksi gagal. Periksa internet lalu coba lagi.',
      'invalid-credential' ||
      'wrong-password' ||
      'user-not-found' => 'Email atau kata sandi salah.',
      'email-already-in-use' => 'Email sudah terdaftar. Silakan login.',
      'weak-password' => 'Kata sandi terlalu lemah.',
      'operation-not-allowed' => 'Metode login belum diaktifkan di Firebase.',
      'too-many-requests' => 'Terlalu banyak percobaan. Coba lagi nanti.',
      _ => 'Operasi gagal: ${error.code}. Silakan coba lagi.',
    };
  }
  return 'Operasi gagal. Silakan coba lagi.';
}

void showMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

class ErrorPage extends StatelessWidget {
  const ErrorPage({required this.message, this.onRetry, super.key});
  final String message;
  final VoidCallback? onRetry;
  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Terjadi kesalahan: $message'),
            if (onRetry != null)
              TextButton(onPressed: onRetry, child: const Text('Coba lagi')),
          ],
        ),
      ),
    ),
  );
}

/// Dialog berada pada Navigator sesi agar ikut hilang ketika akun berubah.
class LogoutButton extends StatefulWidget {
  const LogoutButton({this.onLogout, super.key});
  final Future<void> Function()? onLogout;
  @override
  State<LogoutButton> createState() => _LogoutButtonState();
}

class _LogoutButtonState extends State<LogoutButton> {
  bool busy = false;
  Future<void> logout() async {
    if (busy) return;
    setState(() => busy = true);
    final auth = widget.onLogout == null ? FirebaseAuth.instance : null;
    final uid = auth?.currentUser?.uid;
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        useRootNavigator: false,
        builder: (context) => AlertDialog(
          title: const Text('Keluar dari akun?'),
          content: const Text('Anda akan kembali ke halaman login.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Keluar'),
            ),
          ],
        ),
      );
      if (!mounted || confirmed != true) return;
      if (auth != null && auth.currentUser?.uid != uid) return;
      await (widget.onLogout?.call() ?? auth!.signOut());
    } catch (e) {
      if (mounted) showMessage(context, errorMessage(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => IconButton(
    onPressed: busy ? null : logout,
    tooltip: 'Keluar',
    icon: busy
        ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(),
          )
        : const Icon(Icons.logout),
  );
}

/// Semua rute privat dihancurkan saat UID atau peran berganti.
class SessionNavigator extends StatelessWidget {
  const SessionNavigator({
    required this.sessionKey,
    required this.home,
    super.key,
  });
  final String sessionKey;
  final Widget home;
  @override
  Widget build(BuildContext context) => Navigator(
    key: ValueKey(sessionKey),
    onGenerateRoute: (_) => MaterialPageRoute<void>(builder: (_) => home),
  );
}
