import { useEffect, useState, useCallback } from 'react';
import {
  addBleListener,
  type BleConnectionState,
  type BleConnectionStateChangedData,
  type BleCharacteristicReceivedData,
} from '@native/webf/ble';

const DEFAULT_MAX_EVENT_LOGS = 50;

/**
 * Map of deviceId → connection state. Updated from connectionStateChanged events.
 * Use to show "which devices are connected" or "is this device connected?".
 */
export function useBleConnectionStates(): Record<string, BleConnectionState> {
  const [states, setStates] = useState<Record<string, BleConnectionState>>({});

  useEffect(() => {
    const unsub = addBleListener('connectionStateChanged', (data: BleConnectionStateChangedData) => {
      setStates((prev) => {
        const next = { ...prev, [data.deviceId]: data.connectionState };
        if (data.connectionState === 'disconnected') {
          delete next[data.deviceId];
        }
        return next;
      });
    });
    return unsub;
  }, []);

  return states;
}

/**
 * List of device IDs that are currently connected (from connection state events).
 */
export function useBleConnectedDeviceIds(): string[] {
  const states = useBleConnectionStates();
  return Object.keys(states).filter((id) => states[id] === 'connected');
}

/**
 * Latest value for a single characteristic (from characteristicReceived events).
 * Pass deviceId, serviceUuid, characteristicUuid to filter; returns null until first value.
 */
export function useBleCharacteristicValue(
  deviceId: string | null,
  serviceUuid: string | null,
  characteristicUuid: string | null
): { value: number[] | null; updatedAt: number } {
  const [result, setResult] = useState<{ value: number[] | null; updatedAt: number }>({
    value: null,
    updatedAt: 0,
  });

  useEffect(() => {
    if (!deviceId || !serviceUuid || !characteristicUuid) return;

    const unsub = addBleListener('characteristicReceived', (data: BleCharacteristicReceivedData) => {
      if (
        data.deviceId !== deviceId ||
        data.serviceUuid !== serviceUuid ||
        data.characteristicUuid !== characteristicUuid
      ) {
        return;
      }
      setResult({ value: data.value, updatedAt: Date.now() });
    });
    return unsub;
  }, [deviceId, serviceUuid, characteristicUuid]);

  return result;
}

/**
 * Event log lines from BLE events (connectionStateChanged, characteristicReceived)
 * plus optional local messages via pushLog (e.g. "Scan started").
 * Useful for debug UI or "recent activity".
 */
export function useBleEventLog(
  maxEntries: number = DEFAULT_MAX_EVENT_LOGS
): { logs: string[]; pushLog: (message: string) => void } {
  const [logs, setLogs] = useState<string[]>([]);

  const addLog = useCallback(
    (message: string) => {
      const ts = new Date().toLocaleTimeString();
      setLogs((prev) => [`[${ts}] ${message}`, ...prev.slice(0, maxEntries - 1)]);
    },
    [maxEntries]
  );

  useEffect(() => {
    const unsubConnection = addBleListener(
      'connectionStateChanged',
      (data: BleConnectionStateChangedData) => {
        addLog(`Connection: ${data.deviceId} → ${data.connectionState}`);
      }
    );
    const unsubCharacteristic = addBleListener(
      'characteristicReceived',
      (data: BleCharacteristicReceivedData) => {
        const hex = (b: number) => b.toString(16).padStart(2, '0');
        const valueStr =
          data.value.length <= 16
            ? data.value.map(hex).join(' ')
            : `${data.value.slice(0, 8).map(hex).join(' ')}…`;
        addLog(`Notify ${data.characteristicUuid}: ${valueStr}`);
      }
    );
    return () => {
      unsubConnection();
      unsubCharacteristic();
    };
  }, [addLog]);

  return { logs, pushLog: addLog };
}
