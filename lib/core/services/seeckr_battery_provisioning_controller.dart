import 'dart:async';
import 'dart:convert';
import 'package:dfi_seekr/core/utils/logger.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

class MacProgrammingController {
  final FlutterReactiveBle ble;
  final String deviceId;

  final Uuid serviceUuid;
  final Uuid writeUuid;
  final Uuid notifyUuid;

  late QualifiedCharacteristic _writeChar;
  late QualifiedCharacteristic _notifyChar;

  StreamSubscription<List<int>>? _notifySub;

  // UI state
  final ValueNotifier<bool> isBusy = ValueNotifier(false);
  final ValueNotifier<String> progressText = ValueNotifier("");
  final ValueNotifier<List<Map?> >batInfo = ValueNotifier([]);
  final ValueNotifier<String?> errorText = ValueNotifier(null);

  // ACK handling
  Completer<bool>? _ackCompleter;
// bat polling
  Timer? _batInfoTimer;
  bool _isBatPolling = false;
  String _notifyBuffer = "";
  bool _liveDataActive = false;
  String _liveDataBuffer = "";

  MacProgrammingController({
    required this.ble,
    required this.deviceId,
    required this.serviceUuid,
    required this.writeUuid,
    required this.notifyUuid,
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
  }

  /// Call ONCE after connection
  void startNotifications() {
    _notifySub = ble.subscribeToCharacteristic(_notifyChar).listen(
      _handleNotify,
      onError: (e) {
        errorText.value = "Notify error: $e";
      },
    );
  }

  void dispose() {
    _notifySub?.cancel();
  }

  // ===============================
  // NOTIFY HANDLER (ACK / NACK)
  // ===============================
  void _handleNotify(List<int> data) {
    final chunk = utf8.decode(data);
    printFunc("RAW CHUNK: $chunk");
    // if (!(_notifyBuffer.contains(chunk))) {
    // }
    _notifyBuffer += chunk;

    while (_notifyBuffer.contains("\n")) {
      final newlineIndex = _notifyBuffer.indexOf("\n");
      final line =
      _notifyBuffer.substring(0, newlineIndex).trim();

      _notifyBuffer =
          _notifyBuffer.substring(newlineIndex + 1);

      if (line.isEmpty) continue;

      // -------------------------------
      // LIVE DATA START
      // -------------------------------
      if (line.contains("\$LIVE_DATA_START")) {
        _liveDataActive = true;
        _liveDataBuffer = "";
        printFunc("📥 LIVE DATA STREAM START");
        continue;
      }

      // -------------------------------
      // LIVE DATA END
      // -------------------------------
      if (line.contains("\$LIVE_DATA_END")) {
        _liveDataActive = false;
        printFunc("📥 LIVE DATA STREAM END");
printFunc("$_liveDataBuffer");
        try {
          final json = jsonDecode(_liveDataBuffer.trim());

          // IMPORTANT: matches your HTML
          final devices = json["devices"] as List;
          batInfo.value = devices
              .map<Map<String, dynamic>>((e) {
            final map = Map<String, dynamic>.from(e);
            final now = DateTime.now();
            map["time"] =
            "${now.hour.toString().padLeft(2, '0')}:"
                "${now.minute.toString().padLeft(2, '0')}:"
                "${now.second.toString().padLeft(2, '0')}";
            return map;
          })
              .toList();

          printFunc(
              "✅ LIVE DATA PARSED (${batInfo.value.length} batteries)");
          printFunc(
              "✅ LIVE DATA PARSED \n (${batInfo.value})");
        } catch (e) {
          printFunc("❌ LIVE DATA JSON ERROR: $e");
          errorText.value="❌ LIVE DATA JSON ERROR :\n $e";
        }

        _liveDataBuffer = "";
        continue;
      }

      // -------------------------------
      // LIVE DATA CONTENT
      // -------------------------------
      if (_liveDataActive) {
        _liveDataBuffer += line;
        continue;
      }

      // -------------------------------
      // NORMAL ACK JSON
      // -------------------------------
      try {
        final json = jsonDecode(line);
        printFunc("📩 ACK RECEIVED: $json");


        if (json["ack"] == "SET_MAC") {

          _ackCompleter?.complete(json["status"] == "OK");
        }
        else  if (json["ack"] == "DELETE") {
          _ackCompleter?.complete(json["status"] == "OK");
          errorText.value="Battery Deleted";

        }
        else  if (json["ack"] == "CHANGE") {
          _ackCompleter?.complete(json["status"] == "OK");
          if(json["status"] == "OK") {
            errorText.value = "👍 Battery Added";
          }else{

            errorText.value=json["reason"];
            if (_ackCompleter != null && !_ackCompleter!.isCompleted) {
              _ackCompleter!.complete(false);
            }}
        }
      } catch (_) {
        printFunc("📄 RAW TEXT: $line");
      }
    }
  }

  // ===============================
  // WRITE WITH ACK + TIMEOUT
  // ===============================
  Future<bool> _sendWithAck(

      var payload, {
        Duration timeout = const Duration(seconds: 15),
      }) async
  {
    printFunc("📥 RX: $payload");

    _ackCompleter = Completer<bool>();

    await ble.writeCharacteristicWithResponse(
      _writeChar,
      value: utf8.encode((payload) + "\n"),
    );

    try {
      bool result=await _ackCompleter!.future.timeout(timeout);
      printFunc("Acknolegment : -> $result");
      return result;
    } catch (_) {
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

      if (!success) {
        errorText.value = "Clear all batteries failed";
      }
    } catch (e) {
      errorText.value = "Clear failed: $e";
      printFunc("Exception clear all : ${errorText.value}");
      success = false;
    }

    isBusy.value = false;
    return success;
  }

  // ===============================
  // De Link Tracker
  // ===============================
  Future<void> deleteTrackr(String index) async {
    isBusy.value = true;
    errorText.value = null;
printFunc("DELETE-$index\n");

    try {
      await ble.writeCharacteristicWithResponse(
        _writeChar,
        value: utf8.encode("DELETE-$index\n"));
    } catch (e) {
      errorText.value = "Delete failed: $e";
      printFunc("Exception clear all : ${errorText.value}");
    }

    isBusy.value = false;
  }

  // ===============================
  // PROGRAM MACs (MAIN FLOW)
  // ===============================
  Future<bool> programMacs({
    required List<String> macList,
    int retryCount = 2,
  }) async
  {
    isBusy.value = true;
    errorText.value = null;

    final total = macList.length;
    bool success = false;

    for (int i = 0; i < macList.length; i++) {
      final index = i + 1;
      progressText.value = "Sending B$index / B$total";


      for (int attempt = 1; attempt <= retryCount; attempt++) {
        final payload = "MAC$index,${macList[i]}";
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
          errorText.value = "Failed at B$index (MAC: ${macList[i]})";
          isBusy.value = false;
          success=false;
        }
      }

    }

    progressText.value = "✅ All MACs programmed";
    isBusy.value = false;
    printFunc("${progressText.value }");
    return success;
  }

  // ===============================
  // Change/Replace Bat
  // ===============================
  Future<bool> changeTrackr({
    required String macId,
    required String index,
  }) async
  {
    isBusy.value = true;
    errorText.value = null;

    bool success = false;

      progressText.value = "Sending $index";


      for (int attempt = 1; attempt <= 2; attempt++) {
        final payload = "CHANGE-$index,${macId}";
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

        if (attempt == 2) {
          errorText.value = "Failed at B$index (MAC: ${macId})";
          isBusy.value = false;
          success=false;
        }

    }

    progressText.value = "✅ All MACs programmed";
    isBusy.value = false;
    printFunc("${progressText.value }");
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

    _batInfoTimer = Timer.periodic(const Duration(seconds: 10), (_) async {
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
  Future<bool> _readBatInfoWithAck(
      String payload, {
        Duration timeout = const Duration(seconds: 10),
      }) async {

    _ackCompleter = Completer<bool>();

    try {
      await ble.writeCharacteristicWithResponse(
        _writeChar,
        value: utf8.encode("$payload\n"),
      );
    } catch (e) {
      printFunc("❌ BLE write failed (likely disconnected): $e");
      stopBatInfoPolling(); // VERY IMPORTANT
      return false;
    }


    try {
      bool result =await _ackCompleter!.future.timeout(timeout);
    return result;
    } catch (_) {
      return false;
    }
  }


}
