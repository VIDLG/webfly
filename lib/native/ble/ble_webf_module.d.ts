// Type definitions for BLE Native Module
// Mirrors serialization.dart logic from native/ble

export interface BleResponse<T> {
  result?: T;
  error?: {
    code: number;
    message: string;
  };
}

export interface AdvertisementData {
  advName: string;
  txPowerLevel: number | null;
  appearance: number | null;
  connectable: boolean;
  manufacturerData: Record<string, number[]>; // key is stringified int
  serviceData: Record<string, number[]>; // key is UUID string
  serviceUuids: string[];
}

export interface ScanResult {
  remoteId: string;
  rssi: number;
  advertisementData: AdvertisementData;
  timestamp_ms: number;
}

export interface BluetoothDevice {
  remoteId: string;
  platformName: string;
  advName: string;
  isConnected: boolean;
  mtuNow: number;
}

export interface DisconnectReason {
  platform: string;
  code: number | null;
  description: string | null;
}

export interface CharacteristicProperties {
  broadcast: boolean;
  read: boolean;
  writeWithoutResponse: boolean;
  write: boolean;
  notify: boolean;
  indicate: boolean;
  authenticatedSignedWrites: boolean;
  extendedProperties: boolean;
  notifyEncryptionRequired: boolean;
  indicateEncryptionRequired: boolean;
}

export interface BluetoothDescriptor {
  uuid: string;
  remoteId: string;
  serviceUuid: string;
  characteristicUuid: string;
  primaryServiceUuid?: string;
  lastValue: number[];
}

export interface BluetoothCharacteristic {
  uuid: string;
  remoteId: string;
  serviceUuid: string;
  properties: CharacteristicProperties;
  descriptors: BluetoothDescriptor[];
  isNotifying: boolean;
  lastValue: number[];
}

export interface BluetoothService {
  uuid: string;
  remoteId: string;
  primaryServiceUuid?: string;
  characteristics: BluetoothCharacteristic[];
}

// ----------------------------------------------------------------------------
// Check options.dart
// ----------------------------------------------------------------------------

export interface MsdFilter {
  manufacturerId: number;
  data: number[];
  mask?: number[]; // Not in options.dart parser but exists in FBP
}

export interface ServiceDataFilter {
  serviceUuid: string;
  data: number[];
  mask?: number[];
}

export enum AndroidScanMode {
  Opportunistic = -1,
  LowPower = 0,
  Balanced = 1,
  LowLatency = 2,
}

export interface ScanOptions {
  withServices?: string[];
  withRemoteIds?: string[];
  withNames?: string[];
  withKeywords?: string[];
  withMsd?: MsdFilter[];
  withServiceData?: ServiceDataFilter[];
  timeout?: number; // seconds (parsed as duration in native)
  removeIfGone?: number; // seconds
  continuousUpdates?: boolean;
  continuousDivisor?: number;
  oneByOne?: boolean;
  androidLegacy?: boolean;
  androidScanMode?: AndroidScanMode;
  androidUsesFineLocation?: boolean;
  androidCheckLocationServices?: boolean;
  webOptionalServices?: string[];
}

export interface SetOptions {
  showPowerAlert?: boolean;
  restoreState?: boolean;
}

export interface ConnectOptions {
  timeout?: number; // seconds
  mtu?: number;
  autoConnect?: boolean;
  license?: 'free' | 'commercial';
}

export interface DisconnectOptions {
  timeout?: number;
  queue?: boolean;
  androidDelay?: number;
}

export interface DiscoverServicesOptions {
  subscribeToServicesChanged?: boolean;
  timeout?: number;
}

export interface ReadCharacteristicOptions {
  timeout?: number;
}

export interface WriteCharacteristicOptions {
  withoutResponse?: boolean;
  allowLongWrite?: boolean;
  timeout?: number;
}

export interface NotifyCharacteristicOptions {
  timeout?: number;
  forceIndications?: boolean;
}
