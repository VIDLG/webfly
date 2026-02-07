// ignore_for_file: depend_on_referenced_packages

import 'dart:async';

import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fbp;

/// Export event classes so consumers don't need to import internal FBP type
typedef BleOnConnectionStateChangedEvent = fbp.OnConnectionStateChangedEvent;
typedef BleOnMtuChangedEvent = fbp.OnMtuChangedEvent;
typedef BleOnReadRssiEvent = fbp.OnReadRssiEvent;
typedef BleOnServicesResetEvent = fbp.OnServicesResetEvent;
typedef BleOnDiscoveredServicesEvent = fbp.OnDiscoveredServicesEvent;
typedef BleOnCharacteristicReceivedEvent = fbp.OnCharacteristicReceivedEvent;
typedef BleOnCharacteristicWrittenEvent = fbp.OnCharacteristicWrittenEvent;
typedef BleOnDescriptorReadEvent = fbp.OnDescriptorReadEvent;
typedef BleOnDescriptorWrittenEvent = fbp.OnDescriptorWrittenEvent;
typedef BleOnNameChangedEvent = fbp.OnNameChangedEvent;
typedef BleOnBondStateChangedEvent = fbp.OnBondStateChangedEvent;

/// Access to all global Bluetooth events as streams.
class BleEvents {
  static Stream<BleOnConnectionStateChangedEvent>
  get onConnectionStateChanged =>
      fbp.FlutterBluePlus.events.onConnectionStateChanged;

  static Stream<BleOnMtuChangedEvent> get onMtuChanged =>
      fbp.FlutterBluePlus.events.onMtuChanged;

  static Stream<BleOnReadRssiEvent> get onReadRssi =>
      fbp.FlutterBluePlus.events.onReadRssi;

  static Stream<BleOnServicesResetEvent> get onServicesReset =>
      fbp.FlutterBluePlus.events.onServicesReset;

  static Stream<BleOnDiscoveredServicesEvent> get onDiscoveredServices =>
      fbp.FlutterBluePlus.events.onDiscoveredServices;

  static Stream<BleOnCharacteristicReceivedEvent>
  get onCharacteristicReceived =>
      fbp.FlutterBluePlus.events.onCharacteristicReceived;

  static Stream<BleOnCharacteristicWrittenEvent> get onCharacteristicWritten =>
      fbp.FlutterBluePlus.events.onCharacteristicWritten;

  static Stream<BleOnDescriptorReadEvent> get onDescriptorRead =>
      fbp.FlutterBluePlus.events.onDescriptorRead;

  static Stream<BleOnDescriptorWrittenEvent> get onDescriptorWritten =>
      fbp.FlutterBluePlus.events.onDescriptorWritten;

  static Stream<BleOnNameChangedEvent> get onNameChanged =>
      fbp.FlutterBluePlus.events.onNameChanged;

  static Stream<BleOnBondStateChangedEvent> get onBondStateChanged =>
      fbp.FlutterBluePlus.events.onBondStateChanged;
}
