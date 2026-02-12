export interface DeviceLed {
  index: number
  x: number
  y: number
  guard?: string
}

export interface DeviceStrip {
  id: string
  name: string
  ledCount: number
  path?: string
  leds: DeviceLed[]
}

export interface DeviceRotorGuard {
  cx: number
  cy: number
  radius: number
}

export interface DeviceConfig {
  id: string
  name: string
  description: string
  coordinateUnit: string
  canvas: { width: number; height: number; origin: string }
  rotorGuards?: Record<string, DeviceRotorGuard>
  strips: DeviceStrip[]
}
