import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'admin_page.dart';
import 'common.dart';
import 'guest_page.dart';
import 'login_page.dart';
import 'user_page.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});
  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final Stream<User?> changes = FirebaseAuth.instance.idTokenChanges();
  @override
  Widget build(BuildContext context) => StreamBuilder<User?>(
    stream: changes,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return Scaffold(
          appBar: AppBar(actions: const [LogoutButton()]),
          body: ErrorPage(message: errorMessage(snapshot.error!)),
        );
      }
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      final user = snapshot.data;
      if (user == null) return const LoginPage();
      if (user.isAnonymous) {
        return SessionNavigator(
          sessionKey: '${user.uid}:guest',
          home: const GuestPage(),
        );
      }
      return _MemberGate(key: ValueKey(user), user: user);
    },
  );
}

class _MemberGate extends StatefulWidget {
  const _MemberGate({required this.user, super.key});
  final User user;
  @override
  State<_MemberGate> createState() => _MemberGateState();
}

class _MemberGateState extends State<_MemberGate> {
  // Jangan memaksa refresh setiap build: idTokenChanges sudah melacak token baru.
  late Future<IdTokenResult> token = widget.user.getIdTokenResult();
  @override
  void didUpdateWidget(covariant _MemberGate oldWidget) {
    super.didUpdateWidget(oldWidget);
    token = widget.user.getIdTokenResult();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<IdTokenResult>(
    future: token,
    builder: (context, snapshot) {
      // FutureBuilder dapat membawa data lama; jangan tampilkan sebelum selesai.
      if (snapshot.connectionState != ConnectionState.done) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      if (snapshot.hasError) {
        return Scaffold(
          appBar: AppBar(actions: const [LogoutButton()]),
          body: ErrorPage(
            message: errorMessage(snapshot.error!),
            onRetry: () => setState(() {
              token = widget.user.getIdTokenResult(true);
            }),
          ),
        );
      }
      final admin = snapshot.data?.claims?['admin'] == true;
      return SessionNavigator(
        sessionKey: '${widget.user.uid}:$admin',
        home: admin ? const AdminPage() : UserPage(uid: widget.user.uid),
      );
    },
  );
}
