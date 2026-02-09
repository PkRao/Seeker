import 'dart:async';
import 'dart:convert';

import 'package:dfi_seekr/core/utils/logger.dart';
import 'package:dfi_seekr/presentation/widgets/dialogBox.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

class MacProgrammingController {
  final FlutterReactiveBle ble;
  final String deviceId;
  final int interval = 10;

  final Uuid serviceUuid;
  final Uuid writeUuid;
  final Uuid notifyUuid;
  final Uuid seekerInfoUuid;

  late QualifiedCharacteristic _writeChar;
  late QualifiedCharacteristic _notifyChar;
  late QualifiedCharacteristic _notifyDeviceInfo;

  StreamSubscription<List<int>>? _notifySub;
  StreamSubscription<List<int>>? _notifySubSeeker;

  // UI state
  final ValueNotifier<bool> isBusy = ValueNotifier(false);
  final ValueNotifier<String> progressText = ValueNotifier("");
  final ValueNotifier<List<Map?>> batInfo = ValueNotifier([]);
  final ValueNotifier<Map<String, dynamic>> deviceInfo = ValueNotifier({});
  final ValueNotifier<String?> errorText = ValueNotifier(null);

  // ACK handling
  Completer<bool>? _ackCompleter;

  // bat polling
  Timer? _batInfoTimer;
  bool _isBatPolling = false;
  String _notifyBuffer = "";
  String _notifSeekerInfoyBuffer = "";
  String? _lastChangeErrorReason;

  MacProgrammingController({
    required this.ble,
    required this.deviceId,
    required this.serviceUuid,
    required this.writeUuid,
    required this.notifyUuid,
    required this.seekerInfoUuid,
  }) {
    _writeChar = QualifiedCharacteristic(
      deviceId: deviceId,
      serviceId: serviceUuid,
      characteristicId: writeUuid,
    );

    _notifyChar = QualifiedCharacteristic(
      deviceId: deviceId,
      serviceId: serviceUuid,
      characteristicId: notifyUuid,
    );
    _notifyDeviceInfo = QualifiedCharacteristic(
      deviceId: deviceId,
      serviceId: serviceUuid,
      characteristicId: seekerInfoUuid,
    );
  }

  /// Call ONCE after connection
  void startNotifications() {
    _notifySub = ble
        .subscribeToCharacteristic(_notifyChar)
        .listen(
          _handleNotify,
          onError: (e) {
            errorText.value = "❌ Notify error "; //: $e";
          },
        );
  }

  /// Call ONCE after connection
  void startDeviceNotifications() {
    _notifySubSeeker = ble
        .subscribeToCharacteristic(_notifyDeviceInfo)
        .listen(
          _handleNotifyDeviceInfo,
          onError: (e) {
            errorText.value = "❌ Device Notify error"; //: $e";
          },
        );
  }

  void dispose() {
    _notifySub?.cancel();
    _notifySubSeeker?.cancel();
  }

  // ===============================
  // NOTIFY Helper function for live data (ACK / NACK)
  // ===============================
  //
  Future<void> _processJson(String jsonString) async {
    try {
      final json = jsonDecode(jsonString);
      printFunc("📩 JSON RECEIVED: $json");

      // -------------------------------
      // LIVE DATA JSON
      // -------------------------------
      if (json.containsKey("devices")) {
        final devices = json["devices"] as List;

        // Total batteries you expect
        int totalBatteries = int.tryParse((deviceInfo.value["Batteries"] ?? "4").toString()) ?? 4;

        // Create empty slots
        final List<Map<String, dynamic>?> ordered = List.filled(totalBatteries, null);

        for (final e in devices) {
          final map = Map<String, dynamic>.from(e);
          // final String indexStr = (map["index"] ?? "").toString().toLowerCase(); // b1
          // final int? pos = int.tryParse(indexStr.replaceAll("b", ""));

          final int? pos = int.tryParse(
            (map["index"] ?? "").toString().toLowerCase().replaceAll(RegExp(r'[^0-9]'), ''),
          );

          if (pos == null || pos <= 0 || pos > totalBatteries) continue;

          final now = DateTime.now();
          map["time"] =
              "${now.hour.toString().padLeft(2, '0')}:"
              "${now.minute.toString().padLeft(2, '0')}:"
              "${now.second.toString().padLeft(2, '0')}";

          ordered[pos - 1] = map; // b1 → index 0
        }

        // Optional: Fill missing batteries with defaults
        batInfo.value = List.generate(totalBatteries, (i) {
          return ordered[i] ??
              // {};
              {"index": "B${i + 1}", "mac": "", "voltage": 0, "%": 0, "temp": 0, "BSN": "", "valid": false};
        });

        printFunc("✅ LIVE DATA PARSED \n(${batInfo.value} batteries)");
        return;
      }

      // -------------------------------
      // ACK JSON
      // -------------------------------
      if (json.containsKey("ack")) {
        printFunc("📩 ACK RECEIVED: $json");

        if (json["ack"] == "SET_MAC") {
          _ackCompleter?.complete(json["status"] == "OK");
        } else if (json["ack"] == "TOTAL") {
          _ackCompleter?.complete(json["status"] == "OK");
          // errorText.value = "👍 Battery Deleted";
        } else if (json["ack"] == "DELETE") {
          _ackCompleter?.complete(json["status"] == "OK");
          if (json["status"] == "OK") errorText.value = "👍 Battery Deleted";
        } else if (json["ack"] == "CLEAR") {
          _lastChangeErrorReason = "";
          _ackCompleter?.complete(json["status"] == "OK");
          // errorText.value = "👍 Battery Deleted";
        } else if (json["ack"] == "COUNT") {
          if (json["status"] == "OK") {
            deviceInfo.value = {};
            batInfo.value = [];
            await getSeekrInfo();
            errorText.value = "👍 Battery Configured";
          } else {
            errorText.value = "❌ Battery configuration failed"; //: $e";
          }
        } else if (json["ack"] == "CLEAR_SEEKER_INFO") {
          if (json["status"] == "OK") {
            deviceInfo.value = {};
            batInfo.value = [];

            await getSeekrInfo();
            errorText.value = "👍 Configuration Cleared";
          } else {
            errorText.value = "❌ Clear configuration failed"; //: $e";
          }
        } else if (json["ack"] == "SSN") {
          if (json["status"] == "OK") {
            await getSeekrInfo();
            errorText.value = "👍 Configured Serial Number";
          } else {
            errorText.value = "❌ SSN configuration failed"; //: $e";
          }
        } else if (json["ack"] == "CHANGE") {
          if (json["status"] == "OK") {
            _ackCompleter?.complete(json["status"] == "OK");

            errorText.value = "👍 Battery Linked";
          } else if (json["status"] == "WAIT") {
          } else {
            errorText.value = json["reason"].toString();
            _lastChangeErrorReason = json["reason"].toString();

            printFunc("Change ack : ${json["reason"]}");
            printFunc("Change ack error: ${errorText.value}");
            Future.delayed(Duration(milliseconds: 500));
            _ackCompleter?.complete(json["status"] == "OK");

            if (_ackCompleter != null && !_ackCompleter!.isCompleted) {
              _ackCompleter!.complete(false);
            }
          }
        } else if (json["ack"] == "LIVE_DATA") {
          printFunc("✅ Live data ACK received");
        }
      }
      if (json.containsKey("type")) {
        if (json["type"] == "DEVICE_INFO") {
          deviceInfo.value = json;
        }
      }
    } catch (e) {
      printFunc("❌ JSON PARSE ERROR: $e");
      // errorText.value = "❌ failed ";
    }
  }

  //
  // ===============================
  // DEVICE NOTIFY HANDLER (ACK / NACK)
  // ===============================
  void _handleNotifyDeviceInfo(List<int> data) {
    final chunk = utf8.decode(data);
    printFunc("RAW CHUNK Device info : $chunk");
    if (_notifSeekerInfoyBuffer.endsWith(chunk)) {
      errorText.value = 'Chunk repeated';
      return;
    }
    _notifSeekerInfoyBuffer += chunk;

    // Process buffer while it contains possible JSON
    while (true) {
      final startIndex = _notifSeekerInfoyBuffer.indexOf('{');
      if (startIndex == -1) return;

      int braceCount = 0;
      int endIndex = -1;

      for (int i = startIndex; i < _notifSeekerInfoyBuffer.length; i++) {
        if (_notifSeekerInfoyBuffer[i] == '{') braceCount++;
        if (_notifSeekerInfoyBuffer[i] == '}') braceCount--;

        if (braceCount == 0) {
          endIndex = i;
          break;
        }
      }

      // JSON not complete yet → wait for more chunks
      if (endIndex == -1) return;

      final jsonString = _notifSeekerInfoyBuffer.substring(startIndex, endIndex + 1);

      // Remove processed JSON from buffer
      _notifSeekerInfoyBuffer = _notifSeekerInfoyBuffer.substring(endIndex + 1);

      _processJson(jsonString.trim());
    }
  }

  // ===============================
  // NOTIFY HANDLER (ACK / NACK)
  // ===============================
  void _handleNotify(List<int> data) {
    final chunk = utf8.decode(data);
    printFunc("RAW CHUNK: $chunk");
    if (_notifyBuffer.endsWith(chunk)) {
      errorText.value = 'Chunk repeated';
      return;
    }
    _notifyBuffer += chunk.toString();

    // Process buffer while it contains possible JSON
    while (true) {
      final startIndex = _notifyBuffer.indexOf('{');
      if (startIndex == -1) return;

      int braceCount = 0;
      int endIndex = -1;

      for (int i = startIndex; i < _notifyBuffer.length; i++) {
        if (_notifyBuffer[i] == '{') braceCount++;
        if (_notifyBuffer[i] == '}') braceCount--;

        if (braceCount == 0) {
          endIndex = i;
          break;
        }
      }

      // JSON not complete yet → wait for more chunks
      if (endIndex == -1) return;

      final jsonString = _notifyBuffer.substring(startIndex, endIndex + 1);

      // Remove processed JSON from buffer
      _notifyBuffer = _notifyBuffer.substring(endIndex + 1);

      _processJson(jsonString.trim());
    }
  }

  // ===============================
  // WRITE WITH ACK + TIMEOUT
  // ===============================
  Future<bool> _sendWithAck(var payload, {Duration timeout = const Duration(seconds: 15)}) async {
    printFunc("📥 RX: $payload");

    _ackCompleter = Completer<bool>();

    await ble.writeCharacteristicWithResponse(_writeChar, value: utf8.encode((payload) + "\n"));

    try {
      bool result = await _ackCompleter!.future.timeout(timeout);
      printFunc("Acknolegment : -> $result");
      return result;
    } catch (e) {
      printFunc("Send with ack failed with exe : $e");
      return false; // timeout
    }
  }

  // ===============================
  // CLEAR MACS
  // ===============================
  Future<bool> clearAllMacs() async {
    isBusy.value = true;
    errorText.value = null;

    bool success = false;

    try {
      success = await _sendWithAck("CLEAR");

      if (success) {
        errorText.value = "👍 Configuration cleared";
      } else {
        errorText.value = "❌ Failed to Clear configuration";
      }
    } catch (e) {
      errorText.value = "❌ Clear Config failed"; //: $e";
      printFunc("Exception clear all : ${errorText.value}");
      success = false;
    }

    isBusy.value = false;
    return success;
  }

  // ===============================
  // De Link Tracker
  // ===============================
  Future<bool> deleteTrackr(String index) async {
    isBusy.value = true;
    errorText.value = null;
    printFunc("DELETE-$index\n");
    bool success = false;

    try {
      success = await _sendWithAck("DELETE-$index");

      if (success) {
        errorText.value = "👍 Battery ${index.toUpperCase()} unlinked.";
      } else {
        errorText.value = "❌ Failed to unlink battery (${index.toUpperCase()})";
      }
    } catch (e) {
      errorText.value = "❌ Unlink failed"; //: $e";
      printFunc("Unlink clear all : ${errorText.value}");
      success = false;
    }

    isBusy.value = false;
    return success;
  }

  // ===============================
  // PROGRAM MACs (MAIN FLOW)
  // ===============================
  Future<bool> programMacs({required List<String> macList, int retryCount = 2}) async {
    isBusy.value = true;
    errorText.value = null;

    final total = macList.length;
    bool success = false;
    String payload = "TOTAL,${macList.length}";

    for (int i = 0; i < macList.length; i++) {
      final index = i + 1;
      progressText.value = "Sending B$index / B$total";
      payload = payload + ",${macList[i]}";
    }
    for (int attempt = 1; attempt <= retryCount; attempt++) {
      // {
      //   "cmd": "SET_MAC",
      //   "index": "B$index",
      //   "total": total,
      //   "mac": macList[i],
      // };

      final ack = await _sendWithAck(payload);

      if (ack) {
        success = true;
        break;
      }

      if (attempt == retryCount) {
        errorText.value = "❌ Failed to Configure Batteries";

        isBusy.value = false;
        success = false;
        return success;
      }
    }

    progressText.value = "👍 All Batteries Configured";
    errorText.value = "👍 All Batteries Configured";
    isBusy.value = false;
    printFunc("${progressText.value}");
    return success;
  }

  // ===============================
  // Change/Replace Bat
  // ===============================
  Future<bool> changeTrackr(
    BuildContext context, {
    required String macId,
    required String index,
    required bool safePair,
  }) async {
    isBusy.value = true;
    errorText.value = null;
    _lastChangeErrorReason = "";

    bool success = false;

    progressText.value = "Sending $index";

    for (int attempt = 1; attempt <= 2; attempt++) {
      final payload = "CHANGE-$index,${macId},${safePair}";
      // {
      //   "cmd": "SET_MAC",
      //   "index": "B$index",
      //   "total": total,
      //   "mac": macList[i],
      // };

      final ack = await _sendWithAck(payload);
      printFunc("ACK FROM CHANGE : $ack , ${errorText.value}");
      if (ack) {
        success = true;
        errorText.value = "👍 Battery liked";

        break;
      }

      if (attempt == 1) {
        errorText.value = "Retrying to Link Battery (${index.toUpperCase()})";
      } else if (attempt == 2) {
        Future.delayed(Duration(milliseconds: 300));
        printFunc("Attempt 2 is done :: \n${_lastChangeErrorReason} : safe : $safePair");
        if ((_lastChangeErrorReason == "DEVICE_NOT_AVAILABLE") && safePair) {
          popUpDialog(
            context,
            "Yes",
            "No",

            title: "Warning",
            content: "Battery is not live\nDo you want to pair anyways?",
            onPressRightBtn: () async {
              printFunc("YEs pair"); //     () async {
              Navigator.of(context, rootNavigator: true).pop();
              await changeTrackr(context, macId: macId, index: index, safePair: false);
            },
            onPressLeftBtn: () {
              printFunc("No pair"); //     () async {

              Navigator.of(context, rootNavigator: true).pop();
            },
          );
        } else {
          errorText.value = "❌ Failed to link battery (${index.toUpperCase()})";

          isBusy.value = false;
          success = false;
          return success;
        }
      }
    }

    // progressText.value = "👍 Battery liked";
    isBusy.value = false;
    printFunc("${progressText.value}");
    return success;
  }

  // ===============================
  // Read BAt Info
  // ===============================
  Future<void> startBatInfoPolling() async {
    if (_isBatPolling) return;

    _isBatPolling = true;
    final payload = "LIVE_DATA";
    // ✅ Call immediately
    if (!isBusy.value) {
      await _readBatInfoWithAck(payload);
    }

    _batInfoTimer = Timer.periodic(Duration(seconds: interval), (_) async {
      if (isBusy.value) return;

      await _readBatInfoWithAck(payload);
    });
  }

  void stopBatInfoPolling() {
    _batInfoTimer?.cancel();
    _batInfoTimer = null;
    _isBatPolling = false;
  }

  // ===============================
  // Read BAt WITH ACK + TIMEOUT
  // ===============================
  Future<bool> _readBatInfoWithAck(String payload) async {
    _ackCompleter = Completer<bool>();
    Duration timeout = Duration(seconds: interval - 1);
    printFunc("TX : ${payload}");
    try {
      await ble.writeCharacteristicWithResponse(_writeChar, value: utf8.encode("$payload\n"));
    } catch (e) {
      printFunc("❌ BLE write failed (likely disconnected): $e");
      stopBatInfoPolling(); // VERY IMPORTANT
      return false;
    }

    try {
      bool result = await _ackCompleter!.future.timeout(timeout);
      return result;
    } catch (_) {
      return false;
    }
  }

  // ===============================
  //Get Seekr info
  // ===============================
  Future<void> getSeekrInfo() async {
    isBusy.value = true;
    errorText.value = null;
    printFunc("DEVICE_INFO\n");

    try {
      await ble.writeCharacteristicWithResponse(_notifyDeviceInfo, value: utf8.encode("DEVICE_INFO\n"));
    } catch (e) {
      errorText.value = "❌ Fetch Device detail failed"; //: $e";
      printFunc("Exception Device detail failed : ${errorText.value}");
    }

    isBusy.value = false;
  }

  // ===============================
  // CLEAR Admin Config
  // ===============================
  Future<void> clearAdminConfig() async {
    isBusy.value = true;
    errorText.value = null;
    String cmd = ("CLEAR_SEEKER_INFO\n");
    printFunc(cmd);

    try {
      await ble.writeCharacteristicWithResponse(_notifyDeviceInfo, value: utf8.encode("$cmd"));
      await getSeekrInfo();
    } catch (e) {
      errorText.value = "❌ Clear configuration failed"; //: $e";
      printFunc("Exception clear all device : ${errorText.value}");
    }

    isBusy.value = false;
  }

  // ===============================
  // CLEAR Admin Config
  // ===============================
  Future<void> batteryAdminConfig(String batConfig) async {
    isBusy.value = true;
    errorText.value = null;
    String cmd = ("COUNT:$batConfig\n");
    printFunc("Sending Cmd : $cmd");

    try {
      await ble.writeCharacteristicWithResponse(_notifyDeviceInfo, value: utf8.encode("$cmd"));
      // await getSeekrInfo();
    } catch (e) {
      errorText.value = "❌ Battery configuration failed"; //: $e";
      printFunc("Exception clear all device : ${errorText.value}");
    }

    isBusy.value = false;
  }

  // ===============================
  // CLEAR Admin Config
  // ===============================
  Future<void> setSeekrSerial(String serial) async {
    isBusy.value = true;
    errorText.value = null;
    String cmd = "SSN:$serial\n";
    printFunc(cmd);

    try {
      await ble.writeCharacteristicWithResponse(_notifyDeviceInfo, value: utf8.encode("$cmd"));
      await getSeekrInfo();
    } catch (e) {
      errorText.value = "❌ Config serial number failed"; //: $e";
      printFunc("Exception clear all device : ${errorText.value}");
    }

    isBusy.value = false;
  }
}
