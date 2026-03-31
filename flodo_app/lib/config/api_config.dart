import 'dart:io';

import 'package:flutter/foundation.dart';

/// Your machine’s LAN address (macOS: `ipconfig getifaddr en0`).
/// Update if your Wi‑Fi IP changes.
const String kTaskApiLanHost = '192.168.1.11';

/// Port your FastAPI server listens on (e.g. `uvicorn ... --port 8001`).
const int kTaskApiPort = 8001;

/// When **true**, Android uses `10.0.2.2` (emulator → host). When **false**, uses
/// [kTaskApiLanHost] (physical device on the same Wi‑Fi as the server).
const bool kAndroidUseEmulatorLoopback = false;

String taskApiBaseUrl() {
  if (kIsWeb) {
    return 'http://$kTaskApiLanHost:$kTaskApiPort';
  }
  if (Platform.isAndroid) {
    final host = kAndroidUseEmulatorLoopback ? '10.0.2.2' : kTaskApiLanHost;
    return 'http://$host:$kTaskApiPort';
  }
  // iOS simulator / desktop: LAN IP works for a device build; use 127.0.0.1 locally if needed.
  return 'http://$kTaskApiLanHost:$kTaskApiPort';
}
