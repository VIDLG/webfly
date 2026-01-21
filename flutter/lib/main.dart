import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart' show ProviderScope;
import 'package:webf/launcher.dart'
    show WebFControllerManager, WebFControllerManagerConfig;
import 'package:webf/webf.dart' show WebF;
import 'package:webf_bluetooth/webf_bluetooth.dart' show BluetoothModule;
import 'package:webf_share/webf_share.dart' show ShareModule;
import 'package:webf_sqflite/webf_sqflite.dart' show SQFliteModule;
import 'router/app_router.dart' show kGoRouter;
import 'services/asset_http_server.dart';

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

  // Start asset HTTP server for serving showcase files
  await AssetHttpServer().start();

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'WebFly',
      routerConfig: kGoRouter,
      themeMode: ThemeMode.system,
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
  }
}
