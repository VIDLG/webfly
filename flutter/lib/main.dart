import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:webf/launcher.dart'
    show WebFControllerManager, WebFControllerManagerConfig;
import 'package:webf/webf.dart' show WebF;
import 'package:webf_bluetooth/webf_bluetooth.dart' show BluetoothModule;
import 'package:webf_share/webf_share.dart' show ShareModule;
import 'package:webf_sqflite/webf_sqflite.dart' show SQFliteModule;
import 'router/app_router.dart' show kGoRouter;
import 'services/asset_http_server.dart';
import 'services/app_settings_service.dart'
    show initializeAppSettings, themeModeSignal;
import 'services/url_history_service.dart' show initializeUrlHistory;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
  WebF.defineModule((context) => BluetoothModule(context));
  WebF.defineModule((context) => ShareModule(context));
  WebF.defineModule((context) => SQFliteModule(context));

  // Start asset HTTP server for serving use case files
  await AssetHttpServer().start();

  // Initialize app settings and URL history
  await initializeAppSettings();
  await initializeUrlHistory();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Watch((context) {
      final themeMode = themeModeSignal.value;

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
    });
  }
}
