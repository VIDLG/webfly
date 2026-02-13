import 'dart:convert' show base64Decode;
import 'dart:typed_data' show ByteData, Uint8List;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show CachingAssetBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webfly/main.dart';
import 'package:webfly/store/app_settings.dart';
import 'package:webfly/store/url_history.dart';
import 'package:webfly_theme/webfly_theme.dart';

class _TestAssetBundle extends CachingAssetBundle {
  static final Uint8List _png1x1Transparent = base64Decode(
    // 1x1 transparent PNG
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO8p4qUAAAAASUVORK5CYII=',
  );

  @override
  Future<ByteData> load(String key) async {
    // Provide a valid tiny PNG for any requested asset to keep widget tests
    // deterministic (LauncherHeader uses Image.asset for the logo).
    return ByteData.sublistView(_png1x1Transparent);
  }
}

void main() {
  testWidgets('Launcher smoke test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await initializeAppSettings();
    await initializeTheme();
    await initializeUrlHistory();

    await tester.pumpWidget(
      DefaultAssetBundle(bundle: _TestAssetBundle(), child: const MyApp()),
    );

    await tester.pumpAndSettle();

    expect(find.text('WebFly'), findsOneWidget);
    expect(find.byIcon(Icons.settings), findsOneWidget);
    expect(find.text('Launch'), findsOneWidget);
    expect(find.text('Use Cases'), findsOneWidget);
  });
}
