import 'dart:io';

import 'package:flutter/foundation.dart';

/// Set to `true` to use the deployed API (phones, any network). Set to `false` for local dev.
const bool kUseRemoteApi = true;

/// Deployed backend (no trailing slash — paths are appended as `/tasks`, etc.).
const String kRemoteApiBaseUrl = 'https://flodo-api.onrender.com';

/// Your machine’s LAN address (macOS: `ipconfig getifaddr en0`).
/// Update if your Wi‑Fi IP changes.
const String kTaskApiLanHost = '192.168.1.11';

/// Port your FastAPI server listens on (e.g. `uvicorn ... --port 8001`).
const int kTaskApiPort = 8001;

/// When **true**, Android uses `10.0.2.2` (emulator → host). When **false**, uses
/// [kTaskApiLanHost] (physical device on the same Wi‑Fi as the server).
const bool kAndroidUseEmulatorLoopback = false;

String taskApiBaseUrl() {
  if (kUseRemoteApi) {
    return kRemoteApiBaseUrl;
  }
  if (kIsWeb) {
    return 'http://$kTaskApiLanHost:$kTaskApiPort';
  }
  if (Platform.isAndroid) {
    final host = kAndroidUseEmulatorLoopback ? '10.0.2.2' : kTaskApiLanHost;
    return 'http://$host:$kTaskApiPort';
  }
  return 'http://$kTaskApiLanHost:$kTaskApiPort';
}
