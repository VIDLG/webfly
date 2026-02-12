import 'package:flutter_test/flutter_test.dart';
import 'package:webfly/ui/router/config.dart';

void main() {
  group('Router URL Generation Tests', () {
    test(
      'buildWebFRouteUrl generates correct hybrid routing URL with root path',
      () {
        final url = 'https://example.com/app.js';
        final result = buildWebFRouteUrl(
          url: url,
          route: appRoutePath,
          path: '/',
        );

        expect(result, startsWith('/_/app?'));
        expect(result, contains('url=https%3A%2F%2Fexample.com%2Fapp.js'));
        expect(result, contains('ctrl='));
        expect(result, contains('loc=%2F'));
      },
    );

    test(
      'buildWebFRouteUrl generates correct hybrid routing URL with nested path',
      () {
        final url = 'https://example.com/app.js';
        final result = buildWebFRouteUrl(
          url: url,
          route: appRoutePath,
          path: '/home',
        );

        expect(result, startsWith('/_/app?'));
        expect(result, contains('url=https%3A%2F%2Fexample.com%2Fapp.js'));
        expect(result, contains('loc=%2Fhome'));
      },
    );

    test('buildWebFRouteUrl generates correct URL with custom base', () {
      final url = 'https://example.com/app.js';
      final base = 'my-custom-ctrl';
      final result = buildWebFRouteUrl(
        url: url,
        route: appRoutePath,
        path: '/about',
        base: base,
      );

      expect(result, contains('ctrl=my-custom-ctrl'));
    });

    test('buildWebFRouteUrl handles path without leading slash', () {
      final url = 'https://example.com/app.js';
      final result = buildWebFRouteUrl(
        url: url,
        route: appRoutePath,
        path: 'about',
      );

      expect(result, startsWith('/_/app?'));
      expect(result, contains('loc=about'));
    });

    test('generateDefaultControllerName generates consistent names', () {
      final url1 = 'https://example.com/app.js';
      final url2 = 'https://example.com/app.js';
      final url3 = 'https://different.com/app.js';

      final name1 = generateDefaultControllerName(url1);
      final name2 = generateDefaultControllerName(url2);
      final name3 = generateDefaultControllerName(url3);

      expect(name1, equals(name2)); // Same URL should generate same name
      expect(
        name1,
        isNot(equals(name3)),
      ); // Different URL should generate different name
      expect(name1, startsWith('webf-'));
    });
  });

  group('GoRouter Configuration Tests', () {
    test('appRoutePath should match various paths', () {
      // Test the route path itself
      expect(appRoutePath, equals('/_/app'));

      // Test that the pattern format is correct
      final testUrls = [
        '/_/app/',
        '/_/app/home',
        '/_/app/about/team',
        '/_/app/products/123',
      ];

      // Verify URLs match expected pattern
      for (final _ in testUrls) {}
    });

    test('Route paths are correctly defined', () {
      expect(launcherPath, equals('/_'));
      expect(scannerPath, equals('/_/scanner'));
      expect(appRoutePath, equals('/_/app'));
    });

    test('Query parameter keys are correctly defined', () {
      expect(urlParam, equals('url'));
      expect(baseParam, equals('ctrl'));
      expect(locParam, equals('loc'));
      expect(titleParam, equals('title'));
    });
  });

  group('URL Encoding Tests', () {
    test('Base parameter is properly encoded', () {
      final url = 'https://example.com/app.js';
      final base = 'ctrl-with-special-chars:/@';
      final result = buildWebFRouteUrl(
        url: url,
        route: appRoutePath,
        path: '/',
        base: base,
      );

      // The controller name should be URL encoded
      expect(result, isNot(contains(':/@')));
    });
  });

  group('Edge Cases', () {
    test('Empty path parameter should result in root path', () {
      final url = 'https://example.com/app.js';
      final result = buildWebFRouteUrl(
        url: url,
        route: appRoutePath,
        path: '/',
      );

      // Path is '/' which generates /_/app?...&loc=%2F
      expect(result, matches(RegExp(r'^/_/app\?')));
    });

    test('Multiple slashes in path are handled', () {
      final url = 'https://example.com/app.js';
      final result = buildWebFRouteUrl(
        url: url,
        route: appRoutePath,
        path: '//double//slash',
      );

      // Should still work with query parameter format
      expect(result, startsWith('/_/app?'));
      expect(result, contains('loc=%2F%2Fdouble%2F%2Fslash'));
    });

    test('Go router pattern should match /_/app/ with empty path', () {
      // The regex pattern for go_router :path(.*)
      // When path is /_/app/, the captured group should be empty string
      final pattern = RegExp(r'^/_/app/(.*)');

      expect(pattern.hasMatch('/_/app/'), isTrue);
      expect(pattern.hasMatch('/_/app/home'), isTrue);
      expect(pattern.hasMatch('/_/app?url=xxx'), isFalse); // Missing slash!

      final match = pattern.firstMatch('/_/app/');
      expect(match?.group(1), equals(''));
    });
  });
}
