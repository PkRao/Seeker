/*
import 'dart:async';
import 'package:dfi_seekr/core/utils/logger.dart';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:dfi_seekr/core/services/hive_service.dart';
import '../../../core/services/bluetooth_service.dart';
import '../../widgets/device_card_animated.dart';
import '../../widgets/glow_bluetooth_icon.dart';
import '../../../core/ui/seeker_base_scaffold.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final BluetoothService _bluetooth = BluetoothService();

  final ValueNotifier<List<DiscoveredDevice>> devicesNotifier = ValueNotifier([]);
  final ValueNotifier<bool> isScanning = ValueNotifier(false);
  StreamSubscription<List<DiscoveredDevice>>? _devicesSub;
  // StreamSubscription<List<DiscoveredDevice>>? _devicesSub;

  @override
  void initState() {
    super.initState();

    // subscribe to service stream
    _devicesSub = _bluetooth.devicesStream.listen((list) {
      // sort: connected devices first
      final sorted = List<DiscoveredDevice>.from(list);
      sorted.sort((a, b) {
        final aCon = _bluetooth.connectionStatus[a.id] ?? false;
        final bCon = _bluetooth.connectionStatus[b.id] ?? false;
        if (aCon == bCon) return 0;
        return aCon ? -1 : 1; // connected first
      });

      devicesNotifier.value = sorted;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final lastId = HiveService().getString("${ HiveService.lastSavedDevice}");
      if (lastId != null) {
        // Try to auto reconnect; connect() will emit and force re-sort via devicesStream
      // await  _bluetooth.disconnect(lastId);
      }
       await discoverDevices();

      await _tryAutoReconnect();

    });

  }

  Future<void> _tryAutoReconnect() async {
    final lastId = HiveService().getString("${ HiveService.lastSavedDevice}");
    if (lastId != null) {
      // Try to auto reconnect; connect() will emit and force re-sort via devicesStream
    Future.delayed(const Duration(seconds: 10), () async{

      await _bluetooth.autoReconnect(lastId);
    }
    );
    // _bluetooth. startHeartbeat(lastId);

    }
    updateList();

  }

  Future<void> discoverDevices() async {
    isScanning.value = true;
    devicesNotifier.value = [];
    devicesNotifier.value.clear();


    _bluetooth.startScan();

    // stop scanning after 30s and update flag
    Future.delayed(const Duration(seconds: 10), () {
      _bluetooth.stopScan();
      isScanning.value = false;
    });
    }

  @override
  void dispose() {
    _devicesSub?.cancel();
    devicesNotifier.dispose();
    isScanning.dispose();
    _bluetooth.dispose();
    super.dispose();
  }

  Future<bool> _connectDevice(String id) async {
    return await _bluetooth.connect(id);
  }

  @override
  Widget build(BuildContext context) {
    return SeekerBaseScaffold(
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: Column(
        children: [
          const SizedBox(height: 12),
          ValueListenableBuilder<bool>(
            valueListenable: isScanning,
            builder: (context, scanning, _) => Column(
              children: [

            InkWell(
                  onTap: () async {
                    if (!scanning) {
                      await discoverDevices();
                    } else {
                      _bluetooth.stopScan();
                      isScanning.value = false;
                    }
                  },
                  child: GlowBluetoothIcon(scanning: scanning),
                ),
                const SizedBox(height: 10),
                Text(
                  scanning ? "Scanning..." : "Tap to Scan",
                  style: const TextStyle(color: Colors.white70),
                )
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ValueListenableBuilder<List<DiscoveredDevice>>(
              valueListenable: devicesNotifier,
              builder: (context, devices, _) {
                if (devices.isEmpty) {
                  return const Center(
                    child: Text("No devices found", style: TextStyle(color: Colors.white54)),
                  );
                }
                return ListView.builder(
                  itemCount: devices.length,
                  itemBuilder: (context, index) {
                    final d = devices[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: DeviceCardAnimated(
                        key: ValueKey(d.id),    // ✅ ADD THIS
                        id: d.id,
                        name: d.name,
                        rssi: d.rssi,
                        onConnect: () => _connectDevice(d.id),
                        onConnected: () {
                          updateList();
                        },
                        service: _bluetooth,
                      ),
                    );
                  },
                );

*/
/*
                return ListView.builder(
                  itemCount: devices.length,
                  itemBuilder: (context, index) {
                    final d = devices[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: DeviceCardAnimated(
                        id: d.id,
                        name: d.name,
                        rssi: d.rssi,
                        service: _bluetooth,
                        onConnect: () => _connectDevice(d.id),
                        onConnected: () {
                        updateList();
                        },
                      ),
                    );
                  },
                );
*/ /*

              },
            ),
          ),
        ],
      ),
    );
  }

  void updateList() {
    final updated = List<DiscoveredDevice>.from(devicesNotifier.value);
    updated.sort((a, b) {
      final aCon = _bluetooth.connectionStatus[a.id] ?? false;
      final bCon = _bluetooth.connectionStatus[b.id] ?? false;
      if (aCon == bCon) return 0;
      return aCon ? -1 : 1;
    });
    devicesNotifier.value = updated;
  }
}
*/

// dashboard.dart
import 'dart:async';

import 'package:dfi_seekr/core/services/generalMethods.dart';
import 'package:dfi_seekr/core/services/hive_service.dart';
import 'package:dfi_seekr/core/utils/logger.dart';
import 'package:dfi_seekr/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

import '../../../core/services/bluetooth_service.dart';
import '../../../core/ui/seeker_base_scaffold.dart';
import '../../widgets/device_card_animated.dart';
import '../../widgets/glow_bluetooth_icon.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final BluetoothService _bluetooth = BluetoothService();

  final ValueNotifier<List<DiscoveredDevice>> devicesNotifier = ValueNotifier([]);
  final ValueNotifier<bool> isScanning = ValueNotifier(false);

  StreamSubscription<List<DiscoveredDevice>>? _devicesSub;

  @override
  void initState() {
    super.initState();

    // Listen to the service device stream and sort + push into the ValueNotifier
    _bluetooth.cleanupStaleConnection();

    _devicesSub = _bluetooth.devicesStream.listen((list) {
      final sorted = List<DiscoveredDevice>.from(list);

      // sort: connected first, then by RSSI descending
      sorted.sort((a, b) {
        final aCon = _bluetooth.connectionStatus[a.id] ?? false;
        final bCon = _bluetooth.connectionStatus[b.id] ?? false;
        if (aCon != bCon) return aCon ? -1 : 1; // connected first
        // if same connected state, put higher RSSI (less negative) first
        return b.rssi.compareTo(a.rssi);
      });

      // assign new list (triggers UI rebuild)
      devicesNotifier.value = sorted;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _bluetooth.isConnected.addListener(_listener);
      await discoverDevices();

      await _tryAutoReconnect();
    });
  }

  void _listener() {
    if (_bluetooth.isConnected.value == true) {
      // ✅ Auto close the page
      if (mounted) {
        Navigator.pushNamed(context, AppRoutes.deviceDetail, arguments: {"bluetooth": _bluetooth});
      }
    }
  }

  Future<void> _tryAutoReconnect() async {
    final lastId = HiveService().getString(HiveService.lastSavedDevice);
    if (lastId != null) {
      // small delay so scan/discovery can start first
      Future.delayed(const Duration(seconds: 3), () {
        _bluetooth.autoReconnect(lastId);
      });
    }
  }

  Future<void> discoverDevices() async {
    isScanning.value = true;
    devicesNotifier.value = [];
    devicesNotifier.value.clear();

    _bluetooth.startScan(timeout: const Duration(seconds: 10));

    Future.delayed(const Duration(seconds: 10), () {
      _bluetooth.stopScan();
      isScanning.value = false;
    });
  }

  @override
  void dispose() {
    _devicesSub?.cancel();
    devicesNotifier.dispose();
    isScanning.dispose();
    _bluetooth.dispose();
    super.dispose();
  }

  Future<bool> _connectDevice(String id) async {
    return await _bluetooth.connect(id);
  }

  void updateList() {
    // Re-sort current list and emit a new instance
    final updated = List<DiscoveredDevice>.from(devicesNotifier.value);
    updated.sort((a, b) {
      final aCon = _bluetooth.connectionStatus[a.id] ?? false;
      final bCon = _bluetooth.connectionStatus[b.id] ?? false;
      if (aCon != bCon) return aCon ? -1 : 1;
      return b.rssi.compareTo(a.rssi);
    });
    devicesNotifier.value = updated;
  }

  @override
  Widget build(BuildContext context) {
    getSize(context);
    return SeekerBaseScaffold(
      isDashboard: true,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: Column(
        children: [
          const SizedBox(height: 12),
          ValueListenableBuilder<bool>(
            valueListenable: isScanning,
            builder:
                (context, scanning, _) => Column(
                  children: [
                    InkWell(
                      onTap: () async {
                        if (!scanning) {
                          await discoverDevices();
                        } else {
                          _bluetooth.stopScan();
                          isScanning.value = false;
                        }
                      },
                      child: GlowBluetoothIcon(scanning: scanning),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      scanning ? "Scanning..." : "Tap to Scan",
                      style: const TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                  ],
                ),
          ),

          // const SizedBox(height: 16),
          // ElevatedButton(
          //   onPressed: () async {
          //
          //     // Navigator.pushNamed(context, AppRoutes.deviceDetail, arguments: {"bluetooth": _bluetooth});
          //   },
          //   child: Text("Testing Button", style: TextStyle(color: Colors.white54)),
          // ),
          Expanded(
            child: ValueListenableBuilder<List<DiscoveredDevice>>(
              valueListenable: devicesNotifier,
              builder: (context, devices, _) {
                if (devices.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ValueListenableBuilder<bool>(
                          valueListenable: isScanning,
                          builder:
                              (context, scanning, _) => Column(
                                children: [
                                  !scanning
                                      ? SizedBox(
                                        child: Image.asset('assets/images/dreamFly2.jpg'),
                                        width: 200,
                                        height: 200,
                                      )
                                      : GlowBluetoothIcon(
                                        scanning: scanning,
                                        icon: Image.asset('assets/images/dreamFly2.jpg'),
                                        width: 200,
                                        height: 200,
                                      ),
                                  Text(
                                    scanning ? "\n\n\n\n\n\n\n" : "No devices found\n\n\n\n\n\n\n",
                                    style: TextStyle(fontSize: 14, color: Colors.white54),
                                  ),
                                ],
                              ),
                        ),
                      ],
                    ),
                  );
                }

                return ValueListenableBuilder<Map<String, bool>>(
                  valueListenable: _bluetooth.connectionStatusNotifier, // ✅ LISTEN
                  builder: (context, statusMap, _) {
                    printFunc("Conection notifier updated : ${statusMap["7C:00:37:A1:71:AA"]}");

                    return ListView.builder(
                      itemCount: devices.length,
                      itemBuilder: (context, index) {
                        final d = devices[index];
                        final isConnected = statusMap[d.id] ?? false;

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: DeviceCardAnimated(
                            key: ValueKey(d.id),
                            id: d.id,
                            name: d.name,
                            rssi: d.rssi,
                            connected: isConnected,
                            onConnect: () => _connectDevice(d.id),
                            onConnected: updateList,
                            onDisconnect: updateList,
                            service: _bluetooth,
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
