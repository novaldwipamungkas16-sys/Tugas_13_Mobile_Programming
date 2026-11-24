// Dikembangkan dari Lampiran A LKM; otorisasi final tetap pada Rules.
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'common.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final email = TextEditingController();
  final password = TextEditingController();
  final form = GlobalKey<FormState>();
  bool register = false;
  bool busy = false;

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (busy || !form.currentState!.validate()) return;
    setState(() => busy = true);
    try {
      if (register) {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email.text.trim(),
          password: password.text,
        );
      } else {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email.text.trim(),
          password: password.text,
        );
      }
    } catch (e) {
      if (mounted) showMessage(context, errorMessage(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sistem Pendataan Mahasiswa')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.school, size: 72),
                  const SizedBox(height: 12),
                  Text(
                    register ? 'Daftar Mahasiswa' : 'Masuk Akun',
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: email,
                    decoration: const InputDecoration(labelText: 'Email'),
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) => (v == null || !v.contains('@'))
                        ? 'Masukkan alamat email yang valid'
                        : null,
                  ),
                  TextFormField(
                    controller: password,
                    decoration: const InputDecoration(labelText: 'Kata sandi'),
                    obscureText: true,
                    validator: (v) => (v == null || v.length < 6)
                        ? 'Minimal 6 karakter'
                        : null,
                  ),
                  const SizedBox(height: 22),
                  if (busy) const LinearProgressIndicator(),
                  FilledButton(
                    onPressed: busy ? null : submit,
                    child: Text(register ? 'Daftar' : 'Login'),
                  ),
                  TextButton(
                    onPressed: busy
                        ? null
                        : () => setState(() => register = !register),
                    child: Text(
                      register
                          ? 'Sudah punya akun? Login'
                          : 'Belum punya akun? Daftar',
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: busy
                        ? null
                        : () async {
                            setState(() => busy = true);
                            try {
                              await FirebaseAuth.instance.signInAnonymously();
                            } catch (e) {
                              if (context.mounted) {
                                showMessage(context, errorMessage(e));
                              }
                            } finally {
                              if (mounted) setState(() => busy = false);
                            }
                          },
                    icon: const Icon(Icons.visibility_outlined),
                    label: const Text('Masuk sebagai Tamu'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
