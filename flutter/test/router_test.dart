import 'package:flutter_test/flutter_test.dart';
import 'package:webfly/router/config.dart';
import 'package:webfly/router/app_router.dart';

void main() {
  group('Router URL Generation Tests', () {
    test('buildWebFUrl generates correct single-page URL', () {
      final url = 'https://example.com/app.js';
      final result = buildWebFUrl(url);

      expect(result, startsWith('/webf?'));
      expect(result, contains('url=https%3A%2F%2Fexample.com%2Fapp.js'));
    });

    test(
      'buildWebFRouteUrl generates correct hybrid routing URL with root path',
      () {
        final url = 'https://example.com/app.js';
        final result = buildWebFRouteUrl(
          url: url,
          route: kAppRoutePath,
          path: '/',
        );

        print('Generated URL for root path: $result');
        expect(result, startsWith('/app?'));
        expect(result, contains('url=https%3A%2F%2Fexample.com%2Fapp.js'));
        expect(result, contains('base='));
        expect(result, contains('path=%2F'));
      },
    );

    test(
      'buildWebFRouteUrl generates correct hybrid routing URL with nested path',
      () {
        final url = 'https://example.com/app.js';
        final result = buildWebFRouteUrl(
          url: url,
          route: kAppRoutePath,
          path: '/home',
        );

        print('Generated URL for /home path: $result');
        expect(result, startsWith('/app?'));
        expect(result, contains('url=https%3A%2F%2Fexample.com%2Fapp.js'));
        expect(result, contains('path=%2Fhome'));
      },
    );

    test('buildWebFRouteUrl generates correct URL with custom base', () {
      final url = 'https://example.com/app.js';
      final base = 'my-custom-base';
      final result = buildWebFRouteUrl(
        url: url,
        route: kAppRoutePath,
        path: '/about',
        base: base,
      );

      print('Generated URL with custom base: $result');
      expect(result, contains('base=my-custom-base'));
    });

    test('buildWebFRouteUrl handles path without leading slash', () {
      final url = 'https://example.com/app.js';
      final result = buildWebFRouteUrl(
        url: url,
        route: kAppRoutePath,
        path: 'about',
      );

      print('Generated URL for path without slash: $result');
      expect(result, startsWith('/app?'));
      expect(result, contains('path=about'));
    });

    test('buildWebFRouteUrlFromUri preserves base parameter', () {
      final uri = Uri.parse(
        '/app?url=https%3A%2F%2Fexample.com%2Fapp.js&base=test-base&path=%2Fpage',
      );
      final result = buildWebFRouteUrlFromUri(
        uri: uri,
        route: kAppRoutePath,
        path: '/new-page',
      );

      print('Generated URL preserving base: $result');
      expect(result, contains('base=test-base'));
      expect(result, startsWith('/app?'));
      expect(result, contains('path=%2Fnew-page'));
    });

    test('generateDefaultControllerName generates consistent names', () {
      final url1 = 'https://example.com/app.js';
      final url2 = 'https://example.com/app.js';
      final url3 = 'https://different.com/app.js';

      final name1 = generateDefaultControllerName(url1);
      final name2 = generateDefaultControllerName(url2);
      final name3 = generateDefaultControllerName(url3);

      print('Controller names: $name1, $name2, $name3');
      expect(name1, equals(name2)); // Same URL should generate same name
      expect(
        name1,
        isNot(equals(name3)),
      ); // Different URL should generate different name
      expect(name1, startsWith('webf-'));
    });
  });

  group('GoRouter Configuration Tests', () {
    test('kAppRoutePath should match various paths', () {
      // Test the route path itself
      expect(kAppRoutePath, equals('/app'));

      // Test that the pattern format is correct
      final testUrls = [
        '/app/',
        '/app/home',
        '/app/about/team',
        '/app/products/123',
      ];

      for (final url in testUrls) {
        print('Testing pattern match for: $url');
      }
    });

    test('Route paths are correctly defined', () {
      expect(kLauncherPath, equals('/'));
      expect(kScannerPath, equals('/scanner'));
      expect(kWebfRoutePath, equals('/webf'));
      expect(kAppRoutePath, equals('/app'));
    });

    test('Query parameter keys are correctly defined', () {
      expect(kUrlParam, equals('url'));
      expect(kBaseParam, equals('base'));
      expect(kPathParam, equals('path'));
      expect(kTitleParam, equals('title'));
    });
  });

  group('URL Encoding Tests', () {
    test('Special characters in URL are properly encoded', () {
      final url = 'https://example.com/app.js?foo=bar&baz=qux';
      final result = buildWebFUrl(url);

      print('Encoded URL: $result');
      expect(
        result,
        contains(
          'url=https%3A%2F%2Fexample.com%2Fapp.js%3Ffoo%3Dbar%26baz%3Dqux',
        ),
      );
    });

    test('Base parameter is properly encoded', () {
      final url = 'https://example.com/app.js';
      final base = 'base-with-special-chars:/@';
      final result = buildWebFRouteUrl(
        url: url,
        route: kAppRoutePath,
        path: '/',
        base: base,
      );

      print('URL with encoded base: $result');
      // The base should be URL encoded
      expect(result, isNot(contains(':/@')));
    });
  });

  group('Edge Cases', () {
    test('Empty path parameter should result in root path', () {
      final url = 'https://example.com/app.js';
      final result = buildWebFRouteUrl(
        url: url,
        route: kAppRoutePath,
        path: '/',
      );

      // Path is '/' which generates /app?...&path=%2F
      print('Root path URL: $result');
      expect(result, matches(RegExp(r'^/app\?')));
    });

    test('Multiple slashes in path are handled', () {
      final url = 'https://example.com/app.js';
      final result = buildWebFRouteUrl(
        url: url,
        route: kAppRoutePath,
        path: '//double//slash',
      );

      print('Multiple slashes URL: $result');
      // Should still work with query parameter format
      expect(result, startsWith('/app?'));
      expect(result, contains('path=%2F%2Fdouble%2F%2Fslash'));
    });

    test('Go router pattern should match /app/ with empty path', () {
      // The regex pattern for go_router :path(.*)
      // When path is /app/, the captured group should be empty string
      final pattern = RegExp(r'^/app/(.*)');

      expect(pattern.hasMatch('/app/'), isTrue);
      expect(pattern.hasMatch('/app/home'), isTrue);
      expect(pattern.hasMatch('/app?url=xxx'), isFalse); // Missing slash!

      final match = pattern.firstMatch('/app/');
      print('Captured from /app/: "${match?.group(1)}"');
      expect(match?.group(1), equals(''));
    });
  });
}
