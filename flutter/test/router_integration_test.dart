import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:webfly/router/app_router.dart';
import 'package:webfly/router/config.dart';

void main() {
  group('GoRouter Integration Tests', () {
    testWidgets('Router matches /app/?url=xxx (root path)', (tester) async {
      final testUrl = 'https://example.com/app.js';
      final generatedUrl = buildWebFRouteUrl(path: '/', url: testUrl);
      
      print('Testing route: $generatedUrl');

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: kGoRouter,
        ),
      );

      // Navigate to the generated URL
      kGoRouter.go(generatedUrl);
      await tester.pumpAndSettle();

      // Should not redirect to launcher (would happen if route not found)
      expect(kGoRouter.routerDelegate.currentConfiguration.uri.path, isNot(equals('/')));
      expect(kGoRouter.routerDelegate.currentConfiguration.uri.path, equals('/app'));
      
      print('Current route: ${kGoRouter.routerDelegate.currentConfiguration.uri}');
    });

    testWidgets('Router matches /app/home?url=xxx (nested path)', (tester) async {
      final testUrl = 'https://example.com/app.js';
      final generatedUrl = buildWebFRouteUrl(path: '/home', url: testUrl);
      
      print('Testing route: $generatedUrl');

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: kGoRouter,
        ),
      );

      kGoRouter.go(generatedUrl);
      await tester.pumpAndSettle();

      expect(kGoRouter.routerDelegate.currentConfiguration.uri.path, equals('/app'));
      expect(kGoRouter.routerDelegate.currentConfiguration.uri.queryParameters['path'], equals('/home'));
      
      print('Current route: ${kGoRouter.routerDelegate.currentConfiguration.uri}');
    });

    testWidgets('Router redirects to launcher when url parameter is missing', (tester) async {
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: kGoRouter,
        ),
      );

      // Try to navigate without url parameter
      kGoRouter.go('/app');
      await tester.pumpAndSettle();

      // Should redirect to launcher
      expect(kGoRouter.routerDelegate.currentConfiguration.uri.path, equals('/'));
      
      print('Correctly redirected to launcher');
    });

    testWidgets('Router matches /webf?url=xxx (single page mode)', (tester) async {
      final testUrl = 'https://example.com/app.js';
      final generatedUrl = buildWebFUrl(testUrl);
      
      print('Testing single page route: $generatedUrl');

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: kGoRouter,
        ),
      );

      kGoRouter.go(generatedUrl);
      await tester.pumpAndSettle();

      expect(kGoRouter.routerDelegate.currentConfiguration.uri.path, equals('/webf'));
      expect(kGoRouter.routerDelegate.currentConfiguration.uri.queryParameters['url'], equals(testUrl));
      
      print('Current route: ${kGoRouter.routerDelegate.currentConfiguration.uri}');
    });

    testWidgets('Path parameter is correctly extracted', (tester) async {
      final testUrl = 'https://example.com/app.js';
      final testPaths = [
        '/',           // Empty path param
        '/home',       // Simple path
        '/about/team', // Nested path
        '/api/v1/users/123', // Deep nested path
      ];

      for (final path in testPaths) {
        final generatedUrl = buildWebFRouteUrl(path: path, url: testUrl);
        print('Testing path "$path" -> $generatedUrl');

        await tester.pumpWidget(
          MaterialApp.router(
            routerConfig: kGoRouter,
          ),
        );

        kGoRouter.go(generatedUrl);
        await tester.pumpAndSettle();

        final currentUri = kGoRouter.routerDelegate.currentConfiguration.uri;
        print('  Current URI: $currentUri');
        
        // All should have path /app
        expect(currentUri.path, equals('/app'));
        
        // Should not be redirected to launcher
        expect(currentUri.path, isNot(equals('/')));
        
        // URL parameter should be preserved
        expect(currentUri.queryParameters['url'], equals(testUrl));
        
        // Path parameter should match
        expect(currentUri.queryParameters['path'], equals(path));
      }
    });

    test('Route pattern analysis', () {
      // Analyze the route path
      print('Route path: $kAppRoutePath');
      print('Expected format: /app');
      
      // The pattern should allow empty path
      final regex = RegExp(r'^/app/(.*)$');
      
      expect(regex.hasMatch('/app/'), isTrue, reason: '/app/ should match');
      expect(regex.hasMatch('/app/home'), isTrue, reason: '/app/home should match');
      expect(regex.hasMatch('/app'), isFalse, reason: '/app without trailing slash should not match');
      
      // Test what the empty group captures
      final match1 = regex.firstMatch('/app/');
      print('Captured path for /app/: "${match1?.group(1)}"');
      expect(match1?.group(1), equals(''));
      
      final match2 = regex.firstMatch('/app/home');
      print('Captured path for /app/home: "${match2?.group(1)}"');
      expect(match2?.group(1), equals('home'));
    });
  });
}
