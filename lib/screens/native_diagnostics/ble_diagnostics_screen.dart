import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../router/config.dart';
import '../../utils/app_logger.dart';
import 'core.dart';

class BleDiagnosticsScreen extends HookWidget {
  const BleDiagnosticsScreen({super.key});

  String _formatPermission(PermissionStatus? status) {
    if (status == null) return 'unknown';
    return switch (status) {
      PermissionStatus.granted => 'granted',
      PermissionStatus.denied => 'denied',
      PermissionStatus.restricted => 'restricted',
      PermissionStatus.limited => 'limited',
      PermissionStatus.permanentlyDenied => 'permanentlyDenied',
      PermissionStatus.provisional => 'provisional',
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final log = useMemoized(() => TestLogger('BLE'));

    final bleSupported = useState<bool?>(null);
    final adapterState = useState<BluetoothAdapterState>(
      BluetoothAdapterState.unknown,
    );
    final scanning = useState(false);
    final requestingPermissions = useState(false);
    final results = useState<List<ScanResult>>(<ScanResult>[]);
    final permissionStatuses = useState<Map<String, PermissionStatus>>(
      <String, PermissionStatus>{},
    );
    final lastError = useState<String?>(null);

    void showSnack(String message) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }

    Future<void> logEnvironmentSnapshot({required String reason}) async {
      try {
        ServiceStatus? locationService;
        try {
          locationService = await Permission.location.serviceStatus;
        } catch (_) {
          locationService = null;
        }

        log.i('--- BLE environment snapshot ($reason) ---');
        log.i('platform=${Platform.operatingSystem}');
        log.i('osVersion=${Platform.operatingSystemVersion}');

        log.i('bleSupported=${bleSupported.value}');
        log.i('adapterState=${adapterState.value}');
        log.i(
          'permissions: '
          'scan=${permissionStatuses.value['bluetoothScan']}, '
          'connect=${permissionStatuses.value['bluetoothConnect']}, '
          'locWhenInUse=${permissionStatuses.value['locationWhenInUse']}',
        );
        log.i('locationService=${locationService ?? 'unknown'}');
      } catch (e, st) {
        log.e('logEnvironmentSnapshot failed', e, st);
      }
    }

    Future<void> refreshPermissions() async {
      final statuses = <String, PermissionStatus>{
        'bluetoothScan': await Permission.bluetoothScan.status,
        'bluetoothConnect': await Permission.bluetoothConnect.status,
        // Older Androids may still require location permission for BLE scans.
        'locationWhenInUse': await Permission.locationWhenInUse.status,
      };

      if (!context.mounted) return;
      permissionStatuses.value = statuses;
    }

    Future<void> requestPermissions() async {
      if (requestingPermissions.value) return;

      lastError.value = null;
      requestingPermissions.value = true;

      try {
        await refreshPermissions();

        log.i('requestPermissions: start');

        // Android 12+ uses nearby devices permissions.
        await Permission.bluetoothScan.request();
        await Permission.bluetoothConnect.request();
        // Some OEMs / Android versions still gate scan results on location being enabled.
        await Permission.locationWhenInUse.request();

        await refreshPermissions();

        log.i(
          'requestPermissions: done '
          '(scan=${permissionStatuses.value['bluetoothScan']}, '
          'connect=${permissionStatuses.value['bluetoothConnect']}, '
          'loc=${permissionStatuses.value['locationWhenInUse']})',
        );

        final scan = permissionStatuses.value['bluetoothScan'];
        final connect = permissionStatuses.value['bluetoothConnect'];
        final loc = permissionStatuses.value['locationWhenInUse'];

        if (scan == PermissionStatus.permanentlyDenied ||
            connect == PermissionStatus.permanentlyDenied ||
            loc == PermissionStatus.permanentlyDenied) {
          showSnack('Permission permanently denied. Open Settings to enable.');
        } else {
          showSnack('Permission request completed.');
        }
      } catch (e, st) {
        log.e('Permission request error', e, st);
        lastError.value = 'Permission request failed: $e';
      } finally {
        requestingPermissions.value = false;
      }
    }

    Future<void> turnOnBluetoothIfPossible() async {
      lastError.value = null;

      if (bleSupported.value == false) {
        lastError.value = 'BLE is not supported on this device.';
        showSnack('BLE is not supported on this device.');
        return;
      }

      try {
        log.i('turnOn: requested');
        await FlutterBluePlus.turnOn();
      } catch (e, st) {
        // turnOn() may not be supported or may require user interaction.
        log.w('turnOn failed: $e');
        appLogger.w('[BLE] turnOn not available/failed: $e\n$st');
        lastError.value = 'Could not turn on Bluetooth automatically: $e';
      }
    }

    Future<void> startScan() async {
      lastError.value = null;
      results.value = const <ScanResult>[];

      if (bleSupported.value == false) {
        lastError.value = 'BLE is not supported on this device.';
        showSnack('BLE is not supported on this device.');
        return;
      }

      await refreshPermissions();

      // If scan permission is denied, request it up front.
      final scanStatus = permissionStatuses.value['bluetoothScan'];
      if (scanStatus != PermissionStatus.granted) {
        await requestPermissions();
      }

      if (!context.mounted) return;

      try {
        log.i('startScan(adapter=${adapterState.value})');
        await FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));
      } catch (e, st) {
        log.e('startScan failed', e, st);
        lastError.value = 'startScan failed: $e';
      }
    }

    Future<void> stopScan() async {
      lastError.value = null;

      try {
        log.i('stopScan');
        await FlutterBluePlus.stopScan();
      } catch (e, st) {
        log.e('stopScan failed', e, st);
        lastError.value = 'stopScan failed: $e';
      }
    }

    useEffect(() {
      unawaited(() async {
        try {
          final supported = await FlutterBluePlus.isSupported;
          bleSupported.value = supported;
          log.i('isSupported=$supported');
        } catch (e, st) {
          // If the platform does not implement the call, keep it as unknown.
          log.w('isSupported check failed: $e');
          appLogger.w('[BLE] isSupported check failed: $e\n$st');
          bleSupported.value = null;
        }
      }());

      final adapterSub = FlutterBluePlus.adapterState.listen((state) {
        adapterState.value = state;
        log.d('adapterState=$state');
      });

      final resultsSub = FlutterBluePlus.scanResults.listen((r) {
        results.value = List<ScanResult>.unmodifiable(r);
        log.d('scanResults=${r.length}');
      });

      final scanningSub = FlutterBluePlus.isScanning.listen((isScanning) {
        scanning.value = isScanning;
        log.d('isScanning=$isScanning');
      });

      unawaited(refreshPermissions());
      unawaited(() async {
        // Give permission refresh a moment to complete before snapshot.
        await Future<void>.delayed(const Duration(milliseconds: 150));
        if (!context.mounted) return;
        await refreshPermissions();
        await logEnvironmentSnapshot(reason: 'screen_open');
      }());

      return () {
        unawaited(FlutterBluePlus.stopScan());
        adapterSub.cancel();
        resultsSub.cancel();
        scanningSub.cancel();
      };
    }, const []);

    final scanPerm = permissionStatuses.value['bluetoothScan'];
    final connectPerm = permissionStatuses.value['bluetoothConnect'];
    final locPerm = permissionStatuses.value['locationWhenInUse'];

    final adapterOk = adapterState.value == BluetoothAdapterState.on;
    final supportedOk = bleSupported.value != false;

    Widget section({required Widget child}) {
      return Card(
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: child,
        ),
      );
    }

    Widget actionGrid({required List<Widget> Function(bool twoColumns) buildButtons}) {
      return LayoutBuilder(
        builder: (context, constraints) {
          // Two columns on wider layouts to reduce vertical scrolling.
          // Use a phone-friendly threshold; labels are shortened in two-column mode.
          final twoColumns = constraints.maxWidth >= 360;

          final buttons = buildButtons(twoColumns);

          if (!twoColumns) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < buttons.length; i++) ...[
                  buttons[i],
                  if (i != buttons.length - 1) const SizedBox(height: 10),
                ],
              ],
            );
          }

          final rows = <Widget>[];
          for (var i = 0; i < buttons.length; i += 2) {
            final left = buttons[i];
            final right = (i + 1 < buttons.length) ? buttons[i + 1] : null;

            rows.add(
              Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: left),
                  if (right != null) ...[
                    const SizedBox(width: 12),
                    Expanded(child: right),
                  ],
                ],
              ),
            );

            if (i + 2 < buttons.length) rows.add(const SizedBox(height: 10));
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: rows,
          );
        },
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('BLE Diagnostics'),
        actions: [
          IconButton(
            tooltip: 'Logs',
            onPressed: () => context.push(kNativeDiagnosticsLogsPath),
            icon: const Icon(Icons.article_outlined),
          ),
          IconButton(
            tooltip: 'Refresh',
            onPressed: refreshPermissions,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          section(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Adapter: ${adapterState.value}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (scanning.value)
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'BLE supported: ${switch (bleSupported.value) {
                    null => 'checking...',
                    true => 'yes',
                    false => 'no',
                  }}',
                ),
                const SizedBox(height: 10),
                Text(
                  'Permissions',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(' bluetoothScan: ${_formatPermission(scanPerm)}'),
                Text(' bluetoothConnect: ${_formatPermission(connectPerm)}'),
                Text(' locationWhenInUse: ${_formatPermission(locPerm)}'),
              ],
            ),
          ),
          section(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Compact layout: 2 columns on wide screens, 1 column on narrow.
                // Keeps buttons stable even if labels change (e.g. start/stop scan).
                actionGrid(
                  buildButtons: (twoColumns) {
                    Text label(String normal, String compact) {
                      return Text(
                        twoColumns ? compact : normal,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      );
                    }

                    return [
                      FilledButton.icon(
                        onPressed:
                            requestingPermissions.value ? null : requestPermissions,
                        icon: requestingPermissions.value
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.lock_open),
                        label: label(
                          requestingPermissions.value
                              ? 'Requesting permissions...'
                              : 'Request permissions',
                          requestingPermissions.value ? 'Requesting…' : 'Permissions',
                        ),
                      ),
                      FilledButton.icon(
                        onPressed: (!supportedOk || adapterOk)
                            ? null
                            : turnOnBluetoothIfPossible,
                        icon: const Icon(Icons.bluetooth),
                        label: label('Turn on Bluetooth', 'Bluetooth'),
                      ),
                      FilledButton.icon(
                        onPressed: supportedOk
                            ? (scanning.value ? stopScan : startScan)
                            : null,
                        icon: Icon(scanning.value ? Icons.stop : Icons.search),
                        label: label(
                          scanning.value ? 'Stop scan' : 'Start scan (10s)',
                          scanning.value ? 'Stop' : 'Scan',
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: openAppSettings,
                        icon: const Icon(Icons.settings),
                        label: label('Open app settings', 'Settings'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () async {
                          await refreshPermissions();
                          await logEnvironmentSnapshot(reason: 'manual');
                          showSnack('Logged environment snapshot.');
                        },
                        icon: const Icon(Icons.bug_report_outlined),
                        label: label('Log environment', 'Log env'),
                      ),
                    ];
                  },
                ),
                if (lastError.value != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    lastError.value!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ],
              ],
            ),
          ),
          section(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Results',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Text(
                      '${results.value.length}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (results.value.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'If this stays empty but scanning succeeds, check:\n'
                      '1) Bluetooth is ON\n'
                      '2) There is a BLE advertiser nearby (try nRF Connect)\n'
                      '3) On some Android 10/11 devices: Location services must be ON (not just permission)\n',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                else
                  ...results.value.map((r) {
                    final device = r.device;
                    final name = device.platformName.isNotEmpty
                        ? device.platformName
                        : '(no name)';
                    return Column(
                      children: [
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(name),
                          subtitle: Text(device.remoteId.str),
                          trailing: Text('${r.rssi} dBm'),
                        ),
                        const Divider(height: 1),
                      ],
                    );
                  }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}



