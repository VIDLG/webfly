# WebFly 🚀

**WebFly** is a powerful Flutter-based launcher and runtime for web applications with native capabilities. Unlike traditional web containers like Expo Go or WebF Go, WebFly provides deep integration with native device features while maintaining the flexibility of web development.

## 🌟 Why WebFly?

### Native Capabilities Built-in

WebFly isn't just a web viewer - it's a fully-featured native runtime with integrated device APIs:

- **🔵 Bluetooth Low Energy (BLE)** - Direct access to BLE devices via `webf_bluetooth`
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

- Flutter 3.38.7 or higher
- Dart SDK ^3.10.7
- Android SDK (for Android builds)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/your-org/webfly.git
   cd webfly
   ```

2. **Install Flutter dependencies**
   ```bash
   cd flutter
   flutter pub get
   ```

3. **Install web dependencies** (for use cases)
   ```bash
   pnpm install
   ```

4. **Run the app**
   ```bash
   # From root directory
   pnpm flutter

   # Or from flutter directory
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

```javascript
// Bluetooth LE scanning
if (window.webf?.bluetooth) {
  const devices = await window.webf.bluetooth.scan();
  // Connect and interact with BLE devices
}

// SQLite database
if (window.webf?.sqflite) {
  const db = await window.webf.sqflite.openDatabase('mydb.db');
  await db.execute('CREATE TABLE IF NOT EXISTS users (id INTEGER PRIMARY KEY, name TEXT)');
}

// Native sharing
if (window.webf?.share) {
  await window.webf.share.share({
    title: 'Check this out!',
    text: 'Amazing web app with native features',
    url: 'https://example.com'
  });
}
```

## 🛠️ Development

### Project Structure

```
webfly/
├── flutter/                 # Flutter application
│   ├── lib/
│   │   ├── pages/          # App screens
│   │   │   └── launcher/   # Launcher page & widgets
│   │   ├── services/       # Business logic
│   │   ├── widgets/        # Reusable components
│   │   └── router/         # Navigation setup
│   ├── assets/             # Images, logos
│   └── pubspec.yaml        # Flutter dependencies
│
├── src/                    # Web app development
│   └── pages/              # Example web pages
│
└── contrib/                # WebF contributions
    └── webf/               # WebF engine source
```

### Building from Source

**Android APK**
```bash
cd flutter
flutter build apk --release
```

**Android App Bundle**
```bash
flutter build appbundle --release
```

### Customization

**Add Custom Native Plugins:**
1. Add plugin dependency to `flutter/pubspec.yaml`
2. Integrate with WebF bridge in `services/`
3. Expose API to JavaScript context

**Modify UI Theme:**
- Edit `flutter/lib/main.dart` for app-wide theme
- Customize launcher widgets in `pages/launcher/widgets/`

## ⚙️ Configuration

### App Settings

Access via the settings button (⚙️) in the launcher:

- **WebF Inspector**: Enable/disable developer overlay
- **Cache Controllers**: Keep WebF controllers alive between navigations

### Bundle Server

For development, the built-in HTTP server serves assets from:
- Port: Auto-assigned (check console logs)
- Base URL: `http://localhost:{port}/`
- Asset path: `flutter/assets/use_cases/`

## 📦 Dependencies

### Core
- `webf: ^0.24.6` - Web rendering engine
- `hooks_riverpod: ^3.2.0` - State management
- `go_router: ^17.0.1` - Navigation

### Native Capabilities
- `webf_bluetooth: ^1.0.0` - BLE support
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

