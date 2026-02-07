import 'package:catcher_2/catcher_2.dart';
import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:webf/launcher.dart'
    show WebFControllerManager, WebFControllerManagerConfig;
import 'package:webf/webf.dart' show WebF;
import 'package:webf_cupertino_ui/webf_cupertino_ui.dart'
    show installWebFCupertinoUI;
import 'webf/webf.dart'
    show AppSettingsModule, BleWebfModule, PermissionHandlerWebfModule;
import 'package:webf_share/webf_share.dart' show ShareModule;
import 'package:webf_sqflite/webf_sqflite.dart' show SQFliteModule;
import 'package:permission_handler/permission_handler.dart';
import 'ui/router/app_router.dart' show kGoRouter;
import 'services/asset_http_server.dart';
import 'store/app_settings.dart';
import 'store/url_history.dart';

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
  WebF.defineModule((context) => AppSettingsModule(context));
  WebF.defineModule((context) => PermissionHandlerWebfModule(context));

  // Request Bluetooth permissions at startup
  if (await Permission.bluetoothScan.isDenied) {
    await Permission.bluetoothScan.request();
  }
  if (await Permission.bluetoothConnect.isDenied) {
    await Permission.bluetoothConnect.request();
  }
  // For older Android versions (<= API 30), also need location permission
  if (await Permission.locationWhenInUse.isDenied) {
    await Permission.locationWhenInUse.request();
  }

  // Start asset HTTP server for serving use case files
  await AssetHttpServer().start();

  // Initialize app settings and URL history
  await initializeAppSettings();
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

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Watch((context) {
      try {
        ThemeMode themeMode;
        try {
          themeMode = themeModeSignal.value;
        } catch (_) {
          themeMode = ThemeMode.system;
        }

        return MaterialApp.router(
          title: 'WebFly',
          routerConfig: kGoRouter,
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

        // 手动上报给 Catcher2
        Catcher2.reportCheckedError(e, st);

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
    });
  }
}
