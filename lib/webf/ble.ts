/**
 * BLE WebF module: types + method API.
 * Matches webf/ble.dart + native/ble dto.dart + options.dart.
 *
 * Usage:
 *   import { getAdapterState, getScanResults, startScan, isBleError, type ScanResult } from '@native/webf/ble';
 *   const value = await getAdapterState();
 *   const list = await getScanResults();
 *   const res = await startScan({ timeout: 15 });
 */

// ----------------------------------------------------------------------------
// Response and DTO types
// ----------------------------------------------------------------------------

import {
  createModuleInvoker,
  getWebf,
  isWebfError,
  type WebFModuleEvent,
  type WebfResponse,
} from './bridge';

/** BLE module response shape (alias of WebfResponse for API compatibility). */
export type BleResponse<T> = WebfResponse<T>;

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

// ----------------------------------------------------------------------------
// Module API: method names, args, result types, invoke
// ----------------------------------------------------------------------------
//
// Return shape:
// - Direct value methods (isSupported, getAdapterState, getScanResults, isScanning, getConnectedDevices):
//   Success: raw value. Error: BleResponse<never>.
// - Result methods (turnOn, startScan, ...): Success/Error: BleResponse<T>.
//

export type BleDirectValueMethodName =
  | 'isSupported'
  | 'getAdapterState'
  | 'getScanResults'
  | 'isScanning'
  | 'getConnectedDevices';

export type BleDeviceArgs<O = unknown> = [deviceId: string, options?: O];

export type BleCharacteristicReadArgs = [
  deviceId: string,
  serviceUuid: string,
  characteristicUuid: string,
  options?: ReadCharacteristicOptions,
];

export type BleCharacteristicWriteArgs = [
  deviceId: string,
  serviceUuid: string,
  characteristicUuid: string,
  data: number[],
  options?: WriteCharacteristicOptions,
];

export type BleCharacteristicNotifyArgs = [
  deviceId: string,
  serviceUuid: string,
  characteristicUuid: string,
  enable: boolean,
  options?: NotifyCharacteristicOptions,
];

export type BleModuleMethodName =
  | 'isSupported'
  | 'getAdapterState'
  | 'turnOn'
  | 'startScan'
  | 'stopScan'
  | 'getScanResults'
  | 'isScanning'
  | 'getConnectedDevices'
  | 'connect'
  | 'disconnect'
  | 'discoverServices'
  | 'readCharacteristic'
  | 'writeCharacteristic'
  | 'setNotifyValue';

export interface BleModuleApi {
  isSupported: { args: [] | undefined; result: boolean };
  getAdapterState: { args: [] | undefined; result: string };
  turnOn: { args: [] | undefined; result: void };
  startScan: { args: [ScanOptions?] | [] | undefined; result: void };
  stopScan: { args: [] | undefined; result: void };
  getScanResults: { args: [] | undefined; result: ScanResult[] };
  isScanning: { args: [] | undefined; result: boolean };
  getConnectedDevices: { args: [] | undefined; result: BluetoothDevice[] };
  connect: { args: BleDeviceArgs<ConnectOptions>; result: void };
  disconnect: { args: BleDeviceArgs<DisconnectOptions>; result: void };
  discoverServices: { args: BleDeviceArgs<DiscoverServicesOptions>; result: BluetoothService[] };
  readCharacteristic: { args: BleCharacteristicReadArgs; result: number[] };
  writeCharacteristic: { args: BleCharacteristicWriteArgs; result: void };
  setNotifyValue: { args: BleCharacteristicNotifyArgs; result: void };
}

export type BleModuleArgs<M extends BleModuleMethodName> = BleModuleApi[M]['args'];

export type BleModuleResult<M extends BleModuleMethodName> = BleModuleApi[M]['result'];

// ----------------------------------------------------------------------------
// WebF bridge + method API
// ----------------------------------------------------------------------------

const invoke = createModuleInvoker('Ble');

/** Type guard: true when native returned { error: { code, message } }. */
export function isBleError(x: unknown): x is BleResponse<never> {
  return isWebfError(x);
}

// ----------------------------------------------------------------------------
// All methods return BleResponse<T>: { result: T } on success, { error } on failure
// ----------------------------------------------------------------------------

export function isSupported(): Promise<BleResponse<boolean>> {
  return invoke<BleResponse<boolean>>('isSupported');
}

export function getAdapterState(): Promise<BleResponse<string>> {
  return invoke<BleResponse<string>>('getAdapterState');
}

export function getScanResults(): Promise<BleResponse<ScanResult[]>> {
  return invoke<BleResponse<ScanResult[]>>('getScanResults');
}

export function isScanning(): Promise<BleResponse<boolean>> {
  return invoke<BleResponse<boolean>>('isScanning');
}

export function getConnectedDevices(): Promise<BleResponse<BluetoothDevice[]>> {
  return invoke<BleResponse<BluetoothDevice[]>>('getConnectedDevices');
}

// ----------------------------------------------------------------------------
// Result methods (BleResponse<T> on success/error)
// ----------------------------------------------------------------------------

export function turnOn(): Promise<BleResponse<void>> {
  return invoke<BleResponse<void>>('turnOn');
}

export function startScan(options?: ScanOptions): Promise<BleResponse<void>> {
  return invoke<BleResponse<void>>('startScan', options);
}

export function stopScan(): Promise<BleResponse<void>> {
  return invoke<BleResponse<void>>('stopScan');
}

export function connect(deviceId: string, options?: ConnectOptions): Promise<BleResponse<void>> {
  return invoke<BleResponse<void>>('connect', deviceId, options);
}

export function disconnect(deviceId: string, options?: DisconnectOptions): Promise<BleResponse<void>> {
  return invoke<BleResponse<void>>('disconnect', deviceId, options);
}

export function discoverServices(
  deviceId: string,
  options?: DiscoverServicesOptions
): Promise<BleResponse<BluetoothService[]>> {
  return invoke<BleResponse<BluetoothService[]>>('discoverServices', deviceId, options);
}

export function readCharacteristic(
  deviceId: string,
  serviceUuid: string,
  characteristicUuid: string,
  options?: ReadCharacteristicOptions
): Promise<BleResponse<number[]>> {
  return invoke<BleResponse<number[]>>('readCharacteristic', deviceId, serviceUuid, characteristicUuid, options);
}

export function writeCharacteristic(
  deviceId: string,
  serviceUuid: string,
  characteristicUuid: string,
  data: number[],
  options?: WriteCharacteristicOptions
): Promise<BleResponse<void>> {
  return invoke<BleResponse<void>>('writeCharacteristic', deviceId, serviceUuid, characteristicUuid, data, options);
}

export function setNotifyValue(
  deviceId: string,
  serviceUuid: string,
  characteristicUuid: string,
  enable: boolean,
  options?: NotifyCharacteristicOptions
): Promise<BleResponse<void>> {
  return invoke<BleResponse<void>>('setNotifyValue', deviceId, serviceUuid, characteristicUuid, enable, options);
}

// ----------------------------------------------------------------------------
// BLE events (native → JS via webf module dispatchEvent)
// ----------------------------------------------------------------------------
//
// Event types and payloads match webf/ble.dart BleEventType + *Payload.
// Use addBleListener(eventType, handler) for typed subscription, or the
// specific onBleConnectionStateChanged / onBleCharacteristicReceived.

export type BleConnectionState = 'connected' | 'disconnected' | 'disconnecting';

export interface BleConnectionStateChangedData {
  deviceId: string;
  connectionState: BleConnectionState;
}

export interface BleCharacteristicReceivedData {
  deviceId: string;
  serviceUuid: string;
  characteristicUuid: string;
  value: number[];
}

/** Event type names. Matches Dart BleEventType. */
export type BleEventType = 'connectionStateChanged' | 'characteristicReceived';

/** Payload type for each event. Use with addBleListener for typed handler. */
export interface BleEventPayloadMap {
  connectionStateChanged: BleConnectionStateChangedData;
  characteristicReceived: BleCharacteristicReceivedData;
}

/** Full event name for webf.on (module:type). Use for low-level subscribe. */
export const BLE_EVENT_NAMES = {
  connectionStateChanged: 'Ble:connectionStateChanged',
  characteristicReceived: 'Ble:characteristicReceived',
} as const;

const BLE_EVENT_PREFIX = 'Ble:';

function subscribeBleEvent<T>(
  eventType: string,
  handler: (data: T) => void
): () => void {
  const eventName = BLE_EVENT_PREFIX + eventType;
  const webf = getWebf();
  const wrapped = (e: WebFModuleEvent) => handler(e.detail as T);
  if (webf?.on) {
    webf.on(eventName, wrapped);
    return () => webf.off?.(eventName, wrapped);
  }
  if (webf?.addEventListener) {
    webf.addEventListener(eventName, wrapped);
    return () => webf.removeEventListener?.(eventName, wrapped);
  }
  return () => {};
}

/**
 * Subscribe to a BLE event by type. Typed payload for demo/React.
 * @param eventType - 'connectionStateChanged' | 'characteristicReceived'
 * @param handler - receives typed payload (BleEventPayloadMap[eventType])
 * @returns Unsubscribe function.
 */
export function addBleListener<K extends BleEventType>(
  eventType: K,
  handler: (data: BleEventPayloadMap[K]) => void
): () => void {
  return subscribeBleEvent<BleEventPayloadMap[K]>(eventType, handler);
}

/**
 * Subscribe to BLE device connection state changes.
 * @returns Unsubscribe function.
 */
export function onBleConnectionStateChanged(
  handler: (data: BleConnectionStateChangedData) => void
): () => void {
  return addBleListener('connectionStateChanged', handler);
}

/**
 * Subscribe to BLE characteristic value received (notifications / read response).
 * @returns Unsubscribe function.
 */
export function onBleCharacteristicReceived(
  handler: (data: BleCharacteristicReceivedData) => void
): () => void {
  return addBleListener('characteristicReceived', handler);
}

// ----------------------------------------------------------------------------
// Demo-friendly API (addListener style, mirrors WebFBluetooth.addListener)
// ----------------------------------------------------------------------------

export interface BleEventsAPI {
  /**
   * Subscribe to a BLE event. Typed payload by event type.
   * @param eventType - 'connectionStateChanged' | 'characteristicReceived'
   * @param handler - (event, detail) for compatibility; detail is the typed payload.
   * @returns Unsubscribe function.
   */
  addListener<K extends BleEventType>(
    eventType: K,
    handler: (event: { type: K; detail: BleEventPayloadMap[K] }) => void
  ): () => void;
}

/** Event subscription API for demo / React. Use addListener(eventType, handler). */
export const BleEvents: BleEventsAPI = {
  addListener<K extends BleEventType>(
    eventType: K,
    handler: (event: { type: K; detail: BleEventPayloadMap[K] }) => void
  ): () => void {
    return addBleListener(eventType, (data) =>
      handler({ type: eventType, detail: data } as { type: K; detail: BleEventPayloadMap[K] })
    );
  },
};
