// Core infrastructure for native tests (registry, models)
import 'package:flutter/material.dart';

import '../router/config.dart';

// ============================================================================
// Models
// ============================================================================

class NativeTestEntry {
  const NativeTestEntry({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.routePath,
    required this.icon,
    this.tags = const <String>[],
  });

  final String id;
  final String title;
  final String subtitle;
  final String routePath;
  final IconData icon;
  final List<String> tags;
}

// ============================================================================
// Registry
// ============================================================================

class NativeTestRegistry {
  static const List<NativeTestEntry> tests = <NativeTestEntry>[
    NativeTestEntry(
      id: 'ble',
      title: 'Bluetooth (BLE) test',
      subtitle: 'Scan for nearby BLE advertisers',
      routePath: bleDiagnosticsPath,
      icon: Icons.bluetooth_searching,
      tags: <String>['Android', 'iOS', 'Permissions'],
    ),
  ];
}
