# Secure Device Check

[![pub package](https://img.shields.io/pub/v/secure_device_check.svg)](https://pub.dev/packages/secure_device_check)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](https://opensource.org/licenses/MIT)

A production-ready Flutter plugin for **banking & fintech apps** that provides comprehensive device security checks and screen protection. Supports **Android** (Kotlin) and **iOS** (Swift).

## Features

| Feature | Android | iOS |
|---|---|---|
| 🔍 Emulator / Simulator Detection | ✅ Build properties, telephony checks | ✅ Compile-time + runtime checks |
| 🔓 Root / Jailbreak Detection | ✅ su binary, Magisk, BusyBox, unsafe props | ✅ 30+ file paths, Cydia, sandbox escape |
| 🛠️ Developer Options Detection | ✅ `Settings.Global` checks | ✅ Debugger + provisioning profile check |
| 🛡️ Screen Protection (Screenshot & Recording Block) | ✅ `FLAG_SECURE` — black screen | ✅ Secure text field overlay |

## Getting Started

### Installation

Add the dependency to your `pubspec.yaml`:

```yaml
dependencies:
  secure_device_check: ^1.0.2
```

Then run:

```bash
flutter pub get
```

### Platform Setup

- **Android**: No additional setup required. Minimum SDK: 24 (Android 7.0).
- **iOS**: No additional setup required. Minimum deployment target: iOS 13.0.

## Usage

```dart
import 'package:secure_device_check/secure_device_check.dart';
```

### Emulator / Simulator Detection

```dart
final isEmulator = await FlutterSecurityGuard.isEmulator();
if (isEmulator) {
  // App is running on an emulator or simulator
}
```

### Root / Jailbreak Detection

```dart
final isCompromised = await FlutterSecurityGuard.isDeviceCompromised();
if (isCompromised) {
  // Device is rooted (Android) or jailbroken (iOS)
}
```

### Developer Options Detection

```dart
final devOptions = await FlutterSecurityGuard.isDeveloperOptionsEnabled();

if (devOptions['developerOptions'] == true) {
  // Developer options are enabled
}

if (devOptions['usbDebugging'] == true) {
  // USB debugging is enabled
}
```

> **Note:** On iOS, `developerOptions` is `true` when a debugger is attached OR the app is signed with a development provisioning profile. `usbDebugging` is `true` when a debugger (Xcode / lldb) is actively attached.

### Screen Protection (Screenshot & Recording Block)

When enabled, **screenshots will appear black** and **screen recordings will show a black screen**.

```dart
// Enable — blocks screenshots and screen recording
await FlutterSecurityGuard.enableScreenProtection();

// Disable — restores normal behavior
await FlutterSecurityGuard.disableScreenProtection();
```

### Full Example

```dart
import 'package:flutter/material.dart';
import 'package:secure_device_check/secure_device_check.dart';

class SecurityScreen extends StatefulWidget {
  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  bool isEmulator = false;
  bool isCompromised = false;
  bool devOptionsOn = false;

  @override
  void initState() {
    super.initState();
    _checkSecurity();
    // Enable screen protection by default for sensitive screens
    FlutterSecurityGuard.enableScreenProtection();
  }

  @override
  void dispose() {
    FlutterSecurityGuard.disableScreenProtection();
    super.dispose();
  }

  Future<void> _checkSecurity() async {
    isEmulator = await FlutterSecurityGuard.isEmulator();
    isCompromised = await FlutterSecurityGuard.isDeviceCompromised();
    final devOpts = await FlutterSecurityGuard.isDeveloperOptionsEnabled();
    devOptionsOn = devOpts['developerOptions'] ?? false;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Security Check')),
      body: Column(
        children: [
          ListTile(
            title: const Text('Emulator'),
            trailing: Icon(isEmulator ? Icons.warning : Icons.check),
          ),
          ListTile(
            title: const Text('Root / Jailbreak'),
            trailing: Icon(isCompromised ? Icons.warning : Icons.check),
          ),
          ListTile(
            title: const Text('Developer Options'),
            trailing: Icon(devOptionsOn ? Icons.warning : Icons.check),
          ),
        ],
      ),
    );
  }
}
```

## API Reference

### `FlutterSecurityGuard`

| Method | Return Type | Description |
|---|---|---|
| `isEmulator()` | `Future<bool>` | Detects if the app runs on an emulator or simulator |
| `isDeviceCompromised()` | `Future<bool>` | Detects root (Android) or jailbreak (iOS) |
| `isDeveloperOptionsEnabled()` | `Future<Map<String, bool>>` | Returns `{'developerOptions': bool, 'usbDebugging': bool}` |
| `enableScreenProtection()` | `Future<void>` | Blocks screenshots & screen recording (content appears black) |
| `disableScreenProtection()` | `Future<void>` | Restores normal screenshot & recording behavior |

## Platform-Specific Notes

### Android

- **Emulator detection** uses `Build.FINGERPRINT`, `Build.MODEL`, `Build.HARDWARE`, telephony operator name, and more.
- **Root detection** checks for `su` binary paths, Magisk, BusyBox, and dangerous system properties (`ro.debuggable`, `ro.secure`).
- **Developer options** reads `Settings.Global.DEVELOPMENT_SETTINGS_ENABLED` and `Settings.Global.ADB_ENABLED`.
- **Screen protection** uses `FLAG_SECURE` which causes screenshots to render as black and screen recordings to show a blank/black screen.

### iOS

- **Simulator detection** uses `#if targetEnvironment(simulator)` at compile time, plus runtime environment variable checks.
- **Jailbreak detection** checks 30+ known file paths, attempts `cydia://` URL scheme, writes outside the sandbox, and checks for symbolic links.
- **Developer options** detects debugger attachment via `sysctl` `P_TRACED` flag and checks for a development provisioning profile (`get-task-allow` entitlement).
- **Screen protection** reparents all Flutter views into a secure `UITextField` container view, making all content invisible to screenshots and screen recordings.

## License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.
