import 'dart:async';

import 'package:dfi_seekr/core/services/hive_service.dart';
import 'package:dfi_seekr/core/utils/logger.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

class BluetoothService {
  BluetoothService._internal();

  static final BluetoothService _instance = BluetoothService._internal();

  factory BluetoothService() => _instance;

  final FlutterReactiveBle _ble = FlutterReactiveBle();

  FlutterReactiveBle get ble => _ble;
  final Map<String, DiscoveredDevice> _devices = {};
  final Map<String, bool> connectionStatus = {};
  final ValueNotifier<Map<String, bool>> connectionStatusNotifier =
  ValueNotifier({});

  final Map<String, StreamSubscription<ConnectionStateUpdate>> _connectionSubs = {};

  DiscoveredDevice? connectedDevice;
  String? connectedDeviceId;
  bool isScanning = false;
  StreamSubscription<DiscoveredDevice>? _scanSub;

  final _devicesController = StreamController<List<DiscoveredDevice>>.broadcast();

  Stream<List<DiscoveredDevice>> get devicesStream => _devicesController.stream;

  ValueNotifier<bool> isConnected = ValueNotifier(false);

  void _emitDevices() {
    final list = _devices.values.toList();
    _devicesController.add(List<DiscoveredDevice>.from(list));
  }

  // ---------------- SCAN ----------------
  void startScan({Duration timeout = const Duration(seconds: 30)}) {
    _devices.clear();
    stopScan();

    if (connectedDevice != null && (connectionStatus[connectedDevice!.id] ?? false)) {
      _devices[connectedDevice!.id] = connectedDevice!;
    }

    isScanning = true;
    final lastId = HiveService().getString(HiveService.lastSavedDevice);
    bool autoConnect = false;

    printFunc("Last connected id : $lastId");
    _scanSub = _ble
        .scanForDevices(
          withServices: [],
          scanMode: ScanMode.lowLatency,
          requireLocationServicesEnabled: false,
        )
        .listen(
          (device) {
            printFunc("Devcie : ${device.name}");
            if (!device.name.toLowerCase().startsWith('ble')) return;

            _devices[device.id] = device;
            connectionStatus.putIfAbsent(device.id, () => false);
            printFunc("device id : ${device.id} - state : ${connectionStatus[lastId]} ");
            if (lastId == device.id && connectionStatus[lastId] == false) {
              autoConnect = true;
            }
            _emitDevices();
          },
          onError: (err) {
            printFunc("Scan error: $err");
          },
        );

    Future.delayed(timeout, () {
      stopScan();
      if (lastId != null && autoConnect) autoReconnect(lastId);
    });
  }

  void stopScan() {
    isScanning = false;
    _scanSub?.cancel();
    _scanSub = null;
  }

  // ---------------- CONNECT ----------------
  Future<bool> connect(String deviceId) async {
    printFunc("Connecting to $deviceId");

    await _connectionSubs[deviceId]?.cancel();
    _connectionSubs.remove(deviceId);

    final completer = Completer<bool>();
    bool seenConnected = false;
    bool ignoreFirstFalseDisconnect = true;

    final sub = _ble
        .connectToDevice(id: deviceId, connectionTimeout: const Duration(seconds: 12))
        .listen(
          (ConnectionStateUpdate update) async {
        printFunc("REAL-TIME CONNECT STATE: ${update.connectionState} - ${update.connectionState == DeviceConnectionState.connected}");

        if (update.connectionState == DeviceConnectionState.connected) {
          printFunc("✅ Connected to $deviceId");

          connectionStatus[deviceId] = true;
          connectionStatusNotifier.value = Map.from(connectionStatus); // ✅ ADD

          connectedDeviceId = deviceId;
          connectedDevice = _devices[deviceId] ?? connectedDevice;
          isConnected.value = true;
          HiveService().saveString(HiveService.lastSavedDevice, deviceId);

          if (_devices[deviceId] == null && connectedDevice != null) {
            _devices[deviceId] = connectedDevice!;
          }

          _emitDevices();

          if (!seenConnected) {
            seenConnected = true;
            if (!completer.isCompleted) completer.complete(true);
          }
        }

        if (update.connectionState == DeviceConnectionState.disconnected) {
          if (!seenConnected && ignoreFirstFalseDisconnect) {
            ignoreFirstFalseDisconnect = false;
            printFunc("⚠️ Ignored transient disconnect for $deviceId");
            return;
          }

          printFunc("❌ Real disconnect from $deviceId");

          connectionStatus[deviceId] = false;
          connectionStatusNotifier.value = Map.from(connectionStatus); // ✅ ADD
  printFunc("Conection notifier : ${ connectionStatusNotifier.value["7C:00:37:A1:71:AA"]}");
          if (connectedDeviceId == deviceId) {
            connectedDeviceId = null;
            connectedDevice = null;
            isConnected.value = false;
          }
          if (!completer.isCompleted) completer.complete(false);

          _emitDevices();

        }
      },
      onError: (err) {
        printFunc("❌ Connection Error: $err");

        connectionStatus[deviceId] = false;
        connectionStatusNotifier.value = Map.from(connectionStatus); // ✅ ADD

        _emitDevices();
        if (!completer.isCompleted) completer.complete(false);
      },
    );

    _connectionSubs[deviceId] = sub;

    Future.delayed(const Duration(seconds: 15), () {
      if (!completer.isCompleted) {
        printFunc("❌ Timeout connecting to $deviceId");
        completer.complete(false);
      }
    });

    final result = await completer.future;
    isConnected.value = result;
    return result;
  }

  // ---------------- AUTO RECONNECT ----------------
  Future<void> autoReconnect(String deviceId) async {
    printFunc("AUTO RECONNECT TRY → $deviceId");
    final ok = await connect(deviceId);
    if (ok)
      printFunc("✅ Auto-reconnected to $deviceId");
    else
      printFunc("❌ Auto reconnect failed for $deviceId");
  }

  // ---------------- DISCONNECT ----------------
  Future<void> disconnect(String deviceId) async {

    // ✅ Cancel BLE connection stream (this disconnects device)
    await _connectionSubs[deviceId]?.cancel();
    _connectionSubs.remove(deviceId);

    // await _stopListeningToBroadcasts();

    connectionStatus[deviceId] = false;
    if (connectedDeviceId == deviceId) {
      connectedDeviceId = null;
      connectedDevice = null;
      isConnected.value = false;

    }
    connectionStatusNotifier.value = Map.from(connectionStatus); // ✅ notify UI

    _emitDevices();
  }

  String checkIfDeviceConnected() {
    if (connectedDevice == null) return "Not Connected";
    final id = connectedDevice!.id;
    return (connectionStatus[id] == true) ? "Connected" : "Not Connected";
  }

  void dispose() {
    stopScan();
    for (final s in List<StreamSubscription<ConnectionStateUpdate>>.from(_connectionSubs.values)) {
      try {
        s.cancel();
      } catch (_) {}
    }
    _connectionSubs.clear();
    _devicesController.close();
  }
}



