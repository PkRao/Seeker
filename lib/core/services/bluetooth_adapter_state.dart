import 'package:dfi_seekr/core/utils/logger.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter/foundation.dart';

class BluetoothStateManager {
  // Notifier that UI can listen to
  static ValueNotifier<BluetoothAdapterState> btStateNotifier =
  ValueNotifier(BluetoothAdapterState.off);

  static bool _isStarted = false;

  // Call only once (example: from SplashScreen)
  static void startListening() {
    // if (_isStarted) return;
    _isStarted = true;

    // Listen and update notifier
    FlutterBluePlus.adapterState.listen((state) {
      btStateNotifier.value = state;
      printFunc("🔄 Bluetooth State Updated → $state");
    });
  }
}
