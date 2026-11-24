import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lkm_pendataan_mahasiswa/common.dart';

void main() {
  testWidgets('Error page offers retry', (tester) async {
    var retried = false;
    await tester.pumpWidget(
      MaterialApp(
        home: ErrorPage(
          message: 'uji',
          onRetry: () {
            retried = true;
          },
        ),
      ),
    );
    await tester.tap(find.text('Coba lagi'));
    expect(retried, isTrue);
  });
}
