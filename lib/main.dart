import 'package:catcher_2/catcher_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:signals_hooks/signals_hooks.dart';
import 'package:webf/webf.dart';
import 'package:webf_cupertino_ui/webf_cupertino_ui.dart';
import 'package:webf_share/webf_share.dart';
import 'package:webf_sqflite/webf_sqflite.dart';
import 'package:webfly_theme/webfly_theme.dart';
import 'webf/webf.dart';
import 'services/asset_http_server.dart';
import 'store/app_settings.dart';
import 'store/url_history.dart';
import 'ui/router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Register WebF Cupertino UI custom elements (required by @openwebf/react-cupertino-ui).
  installWebFCupertinoUI();

  // Configure WebF controller manager
  WebFControllerManager.instance.initialize(
    const WebFControllerManagerConfig(
      enableDevTools: true,
      devToolsPort: 9222,
      devToolsAddress: '0.0.0.0',
      // Maximum number of alive controllers (including detached ones)
      maxAliveInstances: 5,
      // Maximum number of attached controllers (actively rendering)
      maxAttachedInstances: 3,
    ),
  );

  // Register WebF native plugin modules
  WebF.defineModule((context) => BleWebfModule(context));
  WebF.defineModule((context) => ShareModule(context));
  WebF.defineModule((context) => SQFliteModule(context));
  WebF.defineModule((context) => ThemeWebfModule(context));
  WebF.defineModule((context) => PermissionHandlerWebfModule(context));

  // Start asset HTTP server for serving use case files
  await AssetHttpServer().start();

  // Initialize app settings, theme (stream), and URL history.
  await initializeAppSettings();
  await initializeTheme();
  await initializeUrlHistory();

  // Catcher2 will call runApp internally
  Catcher2(
    rootWidget: const MyApp(),
    debugConfig: Catcher2Options(DialogReportMode(), [ConsoleHandler()]),
    releaseConfig: Catcher2Options(SilentReportMode(), [
      ConsoleHandler(),
      // Add SentryHandler, HttpHandler, etc. as needed
      // SentryHandler(sentryClient),
      // HttpHandler(HttpRequestType.post, Uri.parse('https://your-error-server.com/api/errors')),
    ]),
  );
}

class MyApp extends HookWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    try {
      final themeSignal = useStreamSignal<ThemeState>(
        () => themeStream,
        initialValue: getTheme(),
      );
      final themeValue = themeSignal.value;
      final ThemeState themeState = themeValue is AsyncData<ThemeState>
          ? themeValue.value
          : getTheme();
      final ThemeMode themeMode = themeState.themePreference;

      return MaterialApp.router(
        title: 'WebFly',
        routerConfig: goRouter,
        themeMode: themeMode,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.indigo,
            brightness: Brightness.light,
          ),
        ),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.indigo,
            brightness: Brightness.dark,
          ),
        ),
      );
    } catch (e, st) {
      debugPrint('[MyApp] root build failed: $e');
      debugPrint('$st');

      // 手动上报给 Catcher2 (guard against uninitialized Catcher2 in tests)
      try {
        Catcher2.reportCheckedError(e, st);
      } catch (_) {}

      return MaterialApp(
        title: 'WebFly (fallback)',
        home: Scaffold(
          appBar: AppBar(title: const Text('Startup Error')),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Text('Startup Error: $e\n\n$st'),
          ),
        ),
      );
    }
  }
}
