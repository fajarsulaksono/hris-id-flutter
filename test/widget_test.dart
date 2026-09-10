import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hris_id_flutter/app.dart';
import 'package:hris_id_flutter/core/api/api_client.dart';
import 'package:hris_id_flutter/core/storage/token_storage.dart';

class _EmptyTokenStorage extends TokenStorage {
  const _EmptyTokenStorage() : super();

  @override
  Future<String?> read() async => null;

  @override
  Future<void> write(String token) async {}

  @override
  Future<void> clear() async {}
}

void main() {
  testWidgets('menampilkan layar login saat token belum ada', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tokenStorageProvider.overrideWithValue(const _EmptyTokenStorage()),
        ],
        child: const HrisApp(),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpAndSettle();

    expect(find.text('HRIS ID'), findsOneWidget);
    expect(find.text('Masuk'), findsOneWidget);
  });
}