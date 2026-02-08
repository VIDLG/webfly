/** webfly_ble BLE WebF module (TS). Usage: import { getAdapterState, startScan, ... } from '@webfly/ble' */

import { createModuleInvoker, WebfModuleEventBus, type Result } from '../../webf_bridge/lib/webf_bridge';

export interface AdvertisementData {
  advName: string;
  txPowerLevel: number | null;
  appearance: number | null;
  connectable: boolean;
  manufacturerData: Record<string, number[]>;
  serviceData: Record<string, number[]>;
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

export interface MsdFilter {
  manufacturerId: number;
  data: number[];
}

export interface ServiceDataFilter {
  serviceUuid: string;
  data: number[];
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
  timeout?: number;
  removeIfGone?: number;
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
  timeout?: number;
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

const invoke = createModuleInvoker('Ble');

export function isSupported(): Promise<Result<boolean, string>> {
  return invoke<boolean>('isSupported');
}
export function getAdapterState(): Promise<Result<string, string>> {
  return invoke<string>('getAdapterState');
}
export function getScanResults(): Promise<Result<ScanResult[], string>> {
  return invoke<ScanResult[]>('getScanResults');
}
export function isScanning(): Promise<Result<boolean, string>> {
  return invoke<boolean>('isScanning');
}
export function getConnectedDevices(): Promise<Result<BluetoothDevice[], string>> {
  return invoke<BluetoothDevice[]>('getConnectedDevices');
}
export function turnOn(): Promise<Result<void, string>> {
  return invoke<void>('turnOn');
}
export function startScan(options?: ScanOptions): Promise<Result<void, string>> {
  return invoke<void>('startScan', options);
}
export function stopScan(): Promise<Result<void, string>> {
  return invoke<void>('stopScan');
}
export function connect(deviceId: string, options?: ConnectOptions): Promise<Result<void, string>> {
  return invoke<void>('connect', deviceId, options);
}
export function disconnect(deviceId: string, options?: DisconnectOptions): Promise<Result<void, string>> {
  return invoke<void>('disconnect', deviceId, options);
}
export function discoverServices(
  deviceId: string,
  options?: DiscoverServicesOptions
): Promise<Result<BluetoothService[], string>> {
  return invoke<BluetoothService[]>('discoverServices', deviceId, options);
}
export function readCharacteristic(
  deviceId: string,
  serviceUuid: string,
  characteristicUuid: string,
  options?: ReadCharacteristicOptions
): Promise<Result<number[], string>> {
  return invoke<number[]>('readCharacteristic', deviceId, serviceUuid, characteristicUuid, options);
}
export function writeCharacteristic(
  deviceId: string,
  serviceUuid: string,
  characteristicUuid: string,
  data: number[],
  options?: WriteCharacteristicOptions
): Promise<Result<void, string>> {
  return invoke<void>('writeCharacteristic', deviceId, serviceUuid, characteristicUuid, data, options);
}
export function setNotifyValue(
  deviceId: string,
  serviceUuid: string,
  characteristicUuid: string,
  enable: boolean,
  options?: NotifyCharacteristicOptions
): Promise<Result<void, string>> {
  return invoke<void>('setNotifyValue', deviceId, serviceUuid, characteristicUuid, enable, options);
}

// ---------------------------------------------------------------------------
// BLE-specific event bus (WebfModuleEventBus from webf_bridge)
// ---------------------------------------------------------------------------

export type BleConnectionState = 'connected' | 'disconnected' | 'disconnecting';

export interface BleConnectionStateChangedPayload {
  deviceId: string;
  connectionState: BleConnectionState;
}

export interface BleCharacteristicReceivedPayload {
  deviceId: string;
  serviceUuid: string;
  characteristicUuid: string;
  value: number[];
}

export type BleEventType = 'connectionStateChanged' | 'characteristicReceived';
export interface BleEventPayloadMap {
  connectionStateChanged: BleConnectionStateChangedPayload;
  characteristicReceived: BleCharacteristicReceivedPayload;
}

export class BleEventBus extends WebfModuleEventBus<BleEventType, BleEventPayloadMap> {
  protected override get moduleName(): string {
    return 'Ble';
  }
}

const defaultBleEventBus = new BleEventBus();

export function addBleListener<K extends BleEventType>(
  eventType: K,
  handler: (data: BleEventPayloadMap[K]) => void
): () => void {
  return defaultBleEventBus.addListener(eventType, handler);
}
