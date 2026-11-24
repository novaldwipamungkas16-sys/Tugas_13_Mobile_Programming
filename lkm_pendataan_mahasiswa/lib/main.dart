import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'common.dart';
import 'firebase_options.dart';
export 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    runApp(const KampusDataApp());
  } catch (e) {
    // Firebase harus siap sebelum autentikasi.
    runApp(MaterialApp(home: ErrorPage(message: errorMessage(e))));
  }
}
