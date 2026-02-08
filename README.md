# WebFly 🚀

English | [简体中文](README.zh-CN.md)

<div align="center">

<img src="assets/logo/webfly_logo.png" alt="WebFly Logo" width="120" height="120" />

[![Flutter](https://img.shields.io/badge/Flutter-3.38.7-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.10.7-0175C2?logo=dart)](https://dart.dev)
[![WebF](https://img.shields.io/badge/WebF-0.24.11-FF6B6B)](https://github.com/openwebf/webf)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

**⭐ If you find WebFly useful, please consider giving it a star! ⭐**

*Native capabilities meet web flexibility - The ultimate hybrid runtime*

</div>

---

**WebFly** is a powerful Flutter-based launcher and runtime for web applications with native capabilities. Unlike traditional web containers like Expo Go or WebF Go, WebFly provides deep integration with native device features while maintaining the flexibility of web development.

## 🌟 Why WebFly?

### Native Capabilities Built-in

WebFly isn't just a web viewer - it's a fully-featured native runtime with integrated device APIs:

- **🔵 Bluetooth Low Energy (BLE)** - Direct access to BLE devices via `@webfly/ble` (powered by `flutter_blue_plus` in `packages/webfly_ble`)
- **🔐 Permissions** - Runtime permission requests via `@webfly/permission` (no startup prompts; request when needed)
- **💾 SQLite Database** - Local database storage with `webf_sqflite`
- **🔗 Native Sharing** - System share sheet integration via `webf_share`
- **📱 Native UI Components** - Seamless Flutter-Web hybrid interfaces
- **🎯 QR Code Scanner** - Built-in mobile scanner for quick app launching

### vs. Expo Go / WebF Go

| Feature | WebFly | Expo Go / WebF Go |
|---------|--------|-------------------|
| **Native APIs** | ✅ Pre-integrated (BLE, SQLite, Share) | ❌ Limited to basic APIs |
| **Custom Native Code** | ✅ Fully customizable | ❌ Requires ejecting |
| **Offline Database** | ✅ SQLite built-in | ⚠️ Limited storage |
| **Device Integration** | ✅ Deep native integration | ⚠️ Basic only |
| **Development** | ✅ Hot reload + Native debugging | ✅ Hot reload only |
| **Distribution** | ✅ Standalone APK/IPA | ⚠️ Requires host app |

## 📸 Screenshots

<div align="center">
  <img src="docs/screenshots/homepage.png" alt="Home Page" width="200" />
  <img src="docs/screenshots/use_cases.png" alt="Use Cases" width="200" />
  <img src="docs/screenshots/settings.png" alt="Settings" width="200" />
  <img src="docs/screenshots/native_diagnostics.png" alt="Diagnostics" width="200" />
</div>
<div align="center">
  <img src="docs/screenshots/light_theme.png" alt="Light Theme" width="200" />
   <img src="docs/screenshots/native_diag_ble.png" alt="BLE Diagnostics" width="200" />
</div>

## 🎯 Key Features

### 1. **Hybrid Routing System**
- Seamless navigation between web routes and Flutter screens
- Shared WebF controllers for performance
- Route focus management and lifecycle handling

### 2. **Smart URL History**
- Recently visited URLs with quick access
- Swipe-to-delete gesture
- Edit mode with batch operations
- Persistent history across sessions

### 3. **QR Code Launcher**
- Instant app loading via QR scan
- Supports both URL and path parameters
- Perfect for demo and testing

### 4. **Developer Tools**
- WebF Inspector overlay for debugging
- JavaScript console integration
- Network request monitoring
- Configurable settings panel

### 5. **Asset HTTP Server**
- Built-in local server for bundled assets
- Hot reload support during development
- Efficient asset delivery

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (Dart ^3.10.7)
- Android SDK (for Android builds)
- pnpm (for frontend; optional if only running Flutter)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/your-org/webfly.git
   cd webfly
   ```

2. **Initialize submodules**
  ```bash
  git submodule update --init --recursive
  ```

3. **Install Flutter dependencies**
   ```bash
   flutter pub get
   ```

4. **Install web dependencies** (for use cases)
   ```bash
  cd frontend
  pnpm install
   ```

5. **Run the app**
   ```bash
  # From repo root
  flutter run
   ```

## 📱 Usage

### Launching Web Apps

**Method 1: Manual URL Entry**
- Enter a bundle URL (e.g., `http://example.com/bundle.js`)
- Optionally specify a custom path in Advanced options
- Tap "Launch" to start

**Method 2: QR Code Scan**
- Tap the QR code icon
- Scan a QR code containing the bundle URL
- App launches automatically

**Method 3: History**
- Tap any recent URL to fill the input
- Tap the arrow button to launch directly
- Swipe left to delete entries

### Native API Usage in Web Apps

WebFly exposes native modules via `webf.invokeModuleAsync(moduleName, method, ...args)`. The frontend uses typed wrappers from `@webfly/ble` and `@webfly/permission` (Result-based, neverthrow).

**BLE** (`@webfly/ble`):

```javascript
import { startScan, getScanResults, connect, addBleListener } from '@webfly/ble';

const res = await startScan({ timeout: 5000 });
if (res.isOk()) { /* use getScanResults(), connect(), etc. */ }
using bus = new (await import('@webfly/ble')).BleEventBus(); // or addBleListener for single subscription
```

**Permissions** (`@webfly/permission`):

```javascript
import { checkStatus, request } from '@webfly/permission';

const status = await checkStatus('camera');
const granted = await request('camera'); // Shows system dialog when needed
```

**SQLite** (`webf_sqflite`):

```javascript
if (window.webf?.invokeModuleAsync) {
  const db = await window.webf.invokeModuleAsync('Sqflite', 'openDatabase', 'mydb.db');
  // ...
}
```

**Native sharing** (`webf_share`):

```javascript
if (window.webf?.share) {
  await window.webf.share.share({ title: '...', text: '...', url: '...' });
}
```

## 🛠️ Development

### Project Structure

```
webfly/
├── lib/                    # Flutter app sources (Host Application)
│   ├── main.dart           # App entry & WebF module registration
│   ├── ui/                 # Launcher, scanner, native diagnostics, webf views
│   ├── services/           # Asset HTTP server
│   ├── store/              # App settings, URL history
│   └── webf/               # WebF modules (AppSettings) & protocol
├── packages/               # Shared & feature packages
│   ├── webf_bridge/        # Shared WebF bridge (Dart + TS): wire format, createModuleInvoker, WebfModuleEventBus
│   ├── webfly_ble/         # BLE WebF module (Dart + TS), flutter_blue_plus
│   └── webfly_permission/  # Permission WebF module (Dart + TS), permission_handler
├── frontend/               # Web Application (React + Vite)
│   └── src/                # Pages (BLE Demo, Permission Demo, etc.), hooks, config
├── assets/                 # Static assets & bundled use_cases
├── platforms/              # Platform templates (android, etc.)
├── docs/                   # Documentation & screenshots
└── pubspec.yaml            # Flutter dependencies (webf_bridge, webfly_ble, webfly_permission)
```

### Architecture Overview

WebFly adopts a **Hybrid Architecture**:
1.  **Flutter Host**: Provides the native shell, manages permissions, accesses hardware (BLE, storage), and renders the UI chrome (navigation, settings).
2.  **WebF Runtime**: A high-performance web rendering engine based on Flutter, responsible for rendering the web application content.
3.  **Local Asset Server**: A built-in HTTP server (`shelf`) that serves the compiled web app from local assets, ensuring offline availability and fast load times.
4.  **React Frontend**: The UI logic for the business application is built with standard web technologies (React, Vite) and UI components (`@openwebf/react-cupertino-ui`).

### Development Tools

WebFly includes custom Rust-based tools (invoked via `just`) to keep platform directories reproducible and to streamline dev workflows.

### Flutter Tasks (Just)

Run these from the repository root:

```bash
# Generate platform directories (copies templates from platforms/)
just gen-platforms

# Generate logos only (without applying to launcher icons)
just logo

# Generate logos + apply (launcher icons + native splash)
just gen-logo

# Run on Android (auto-select device)
just android

# Build a release APK
just build-apk
```

**Web Development**
```bash
# Start Vite dev server
cd frontend
pnpm dev

# Build web app
pnpm build

# Build use cases
pnpm build:use-cases
```

### Building from Source

**Android APK**
```bash
# Via just (recommended):
just build-apk

# Or manually:
flutter build apk --release --obfuscate --split-debug-info=build/app/outputs/symbols
```

**Android App Bundle**
```bash
flutter build appbundle --release
```

### Customization

**Add Custom Native Plugins:**
1. Create a package under `packages/` (or add dependency to `pubspec.yaml`).
2. Use `webf_bridge` (Dart: `webfOk`/`webfErr`/`toWebfJson`; TS: `createModuleInvoker`, `WebfModuleEventBus`) for wire format and event bus.
3. Register the module in `lib/main.dart` with `WebF.defineModule(...)` and expose API to the frontend (e.g. `@webfly/ble`-style wrapper).

**Modify UI Theme:**
- Edit `lib/main.dart` for app-wide theme.
- Customize launcher widgets in `lib/ui/launcher/widgets/`.

## ⚙️ Configuration

### Permissions & AndroidManifest

- **Bluetooth, notification, etc.** are declared in both `android/app/src/main/AndroidManifest.xml` and `platforms/android/AndroidManifest.main.xml` (kept in sync). This includes `BLUETOOTH_SCAN`, `BLUETOOTH_CONNECT`, `POST_NOTIFICATIONS` (Android 13+), and others.
- **Runtime request**: The app does not request permissions at startup. Request when needed, e.g. open **Permission Demo**, tap **Request** for the desired permission (bluetooth, notification, etc.) to trigger the system dialog; or call `request('bluetoothScan')` / `request('notification')` from your code when using that feature.
- **If still denied**: Make sure you tapped Request for that permission in Permission Demo; if you previously chose “Don’t ask again”, grant the permission in system **Settings → Apps → WebFly → Permissions**.
- **Adding new permissions**: After adding `<uses-permission>` in `android/app/src/main/AndroidManifest.xml`, update `platforms/android/AndroidManifest.main.xml` the same way so both stay in sync.

### App Settings

Access via the settings button (⚙️) in the launcher:

- **WebF Inspector**: Enable/disable developer overlay
- **Cache Controllers**: Keep WebF controllers alive between navigations

### Bundle Server

For development, the built-in HTTP server serves assets from:
- Port: Auto-assigned (check console logs)
- Base URL: `http://localhost:{port}/`
- Asset path: `assets/use_cases/`

## 📦 Dependencies

### Core
- `webf: ^0.24.11` - Web rendering engine
- `signals_flutter: ^6.3.0` - State management
- `go_router: ^17.0.1` - Navigation

### Packages (monorepo)
- `webf_bridge` - Shared bridge: wire format (Dart), `createModuleInvoker` / `WebfModuleEventBus` (TS)
- `webfly_ble` - BLE WebF module (Dart + TS), uses `flutter_blue_plus`
- `webfly_permission` - Permission WebF module (Dart + TS), uses `permission_handler`

### Native & Web
- `webf_sqflite: ^1.0.1` - SQLite database
- `webf_share: ^1.1.0` - Native sharing
- `mobile_scanner: ^7.1.4` - QR code scanning

### Utilities
- `shared_preferences: ^2.5.4` - Local storage
- `shelf: ^1.4.2` - HTTP server

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📄 License

[Add your license here]

## 🙏 Acknowledgments

Built on top of [WebF](https://github.com/openwebf/webf) - the high-performance web rendering engine for Flutter.

---

**Made with ❤️ for developers who want native power with web flexibility**

