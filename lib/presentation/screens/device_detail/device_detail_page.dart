import 'dart:ui';

import 'package:dfi_seekr/core/constants/app_colors.dart';
import 'package:dfi_seekr/core/services/bluetooth_service.dart';
import 'package:dfi_seekr/core/services/generalMethods.dart';
import 'package:dfi_seekr/core/services/seeckr_battery_provisioning_controller.dart';
import 'package:dfi_seekr/core/utils/logger.dart';
import 'package:dfi_seekr/presentation/widgets/animated_gradient_button.dart';
import 'package:dfi_seekr/presentation/widgets/qr_code_reader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

import '../../../core/ui/seeker_base_scaffold.dart';
import '../../widgets/battery_info_tile.dart';

class DeviceDetailPage extends StatefulWidget {
  // final String deviceId;
  final BluetoothService bluetooth;

  const DeviceDetailPage({super.key, required this.bluetooth});

  @override
  State<StatefulWidget> createState() {
    return _DeviceDetailPageState();
  }
}

class _DeviceDetailPageState extends State<DeviceDetailPage> {
  final ValueNotifier<bool> connectionStatus = ValueNotifier(false);
  late MacProgrammingController macController;
  bool assignBat = false;

  List<String> list = [];
  bool configMAc = false;
  @override
  void dispose() {
    macController.stopBatInfoPolling();
    macController.errorText.removeListener(_errorListener);
    widget.bluetooth.isConnected.removeListener(_listener);

    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      widget.bluetooth.isConnected.addListener(_listener);
    });

    try {
      macController = MacProgrammingController(
        ble: widget.bluetooth.ble,
        deviceId: widget.bluetooth.connectedDeviceId!,
        serviceUuid: Uuid.parse("f043176a-5168-11ee-be56-0242ac120021"),
        writeUuid: Uuid.parse("f043176a-5168-11ee-be56-0242ac120022"),
        notifyUuid: Uuid.parse("f043176a-5168-11ee-be56-0242ac120023"),
      );

      macController.startNotifications();
      macController.startBatInfoPolling();




      macController.errorText.addListener(_errorListener);

    } catch (_) {}
  }
 void _errorListener  () {
  final msg = macController.errorText.value;
  if (msg != null && msg.isNotEmpty && mounted) {
  ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(content: Text(msg), backgroundColor: Colors.redAccent,duration:Duration(seconds:4)),
  );
  macController.errorText.value = null;
  }
}
  void _listener() {
    if (widget.bluetooth.isConnected.value == false) {
      // ✅ Auto close the page
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return SeekerBaseScaffold(
      appBar: AppBar(
        title: const Text('Seekr Dashboard'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          ValueListenableBuilder<bool>(
            valueListenable: macController.isBusy,
            builder: (context, busy, _) {
              return PopupMenuButton<int>(
                enabled: !busy,
                tooltip: "Options",
                position: PopupMenuPosition.under,
                color: Colors.black87,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.white24),
                ),
                icon: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.neonBlueSoft, width: 2),
                    boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6)],
                  ),
                  child: const Icon(Icons.more_vert, color: AppColors.neonAccent, size: 20),
                ),
                onSelected: (value) async {
                  if (value == 1) {
                    // ⚙ Configure Batteries
                    await Future.delayed(const Duration(milliseconds: 300));
                    setState(() {
                      assignBat = !assignBat;
                    });
                  } else if (value == 2) {
                    // 🧹 Clear All Batteries

                    if (await macController.clearAllMacs()) macController.batInfo.value = [];
                  }
                  else if (value == 3) {
                    // 🔌 Disconnect Device
                    await widget.bluetooth.disconnect(widget.bluetooth.connectedDeviceId??"");
                    if (mounted) Navigator.of(context).pop();
                  }
                },
                itemBuilder:
                    (context) => [
                      PopupMenuItem<int>(
                        value: 1,
                        child: Row(
                          children: const [
                            Icon(Icons.settings_outlined, color: Colors.cyanAccent, size: 18),
                            SizedBox(width: 10),
                            Text("Configure Batteries", style: TextStyle(color: Colors.white)),
                          ],
                        ),
                      ),
                      PopupMenuItem<int>(
                        value: 2,
                        child: Row(
                          children: const [
                            Icon(Icons.delete_forever_outlined, color: Colors.redAccent, size: 18),
                            SizedBox(width: 10),
                            Text("Clear All Batteries", style: TextStyle(color: Colors.white)),
                          ],
                        ),
                      ),
                      const PopupMenuItem<int>(
                        value: 3,
                        child:Row(
                          children: const [
                            Icon(Icons.bluetooth_disabled_outlined, color:Colors.orangeAccent, size: 18),
                            SizedBox(width: 10),
                            Text("Disconnect", style: TextStyle(color: Colors.white)),
                          ],
                        ),
                      ),
                    ],
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 15.0, bottom: 0, top: 10),
              child: Text(
                "Connected Device",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
            ),

            ValueListenableBuilder(
              valueListenable: widget.bluetooth.isConnected,
              builder: (context, value, _) {
                return InkWell(
                  onTap: () {
                    setState(() {});
                    printFunc("Devcie id : ${widget.bluetooth.connectedDeviceId}");
                    printFunc("Devcie name : ${widget.bluetooth.connectedDevice?.name}");
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.bluetooth_connected, color: Colors.lightBlueAccent, size: 30),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.bluetooth.connectedDevice?.name ?? "Unknown",
                                  style: const TextStyle(fontSize: 20, color: Colors.white),
                                ),
                                Text(
                                  widget.bluetooth.connectedDevice?.id ?? "-",
                                  style: const TextStyle(fontSize: 14, color: Colors.white70),
                                ),
                              ],
                            ),
                          ],
                        ),
                        SizedBox(
                          width: 48,
                          height: 48,
                          child: RotatingRefreshButton(
                            onPressed: () {
                              macController.startBatInfoPolling();
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 28),

            if (assignBat)
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                  child: Container(
                    width: screenSize.width * 0.7,
                    // height: 240,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        colors: [Colors.white30, Colors.white10],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border.all(color: Colors.white12, width: 1.0),
                      boxShadow: [
                        BoxShadow(color: Colors.black54, blurRadius: 18, offset: const Offset(0, 6)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Battery Combination",
                              style: TextStyle(
                                color: Colors.white60.withOpacity(0.95), //AppColors.neonAccent,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                setState(() {
                                  assignBat = false;
                                  list.clear();
                                  configMAc = false;
                                });
                              },
                              icon: Icon(Icons.close, color: AppColors.errorText),
                            ),
                          ],
                        ),

                        const SizedBox(height: 18),

                        // Divider line
                        Container(height: 1, color: Colors.white.withOpacity(0.16)),
                        const SizedBox(height: 18),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            ElevatedButton(
                              onPressed: () async {
                                list.clear();
                                setState(() {
                                  configMAc = false;
                                });

                                for (int i = 0; i < 2; i++) {
                                  final mac = await QRScannerWidget(context, "QR Code Battery ${i + 1}");
                                  if (mac != null && mac.isNotEmpty) {
                                    setState(() {
                                      list.add(mac);
                                    });
                                  }

                                  await Future.delayed(const Duration(milliseconds: 800)); // optional gap
                                }

                                setState(() {
                                  configMAc = true;
                                });
                              },
                              child: Text("Pair", style: TextStyle(color: Colors.white54)),
                            ),
                            ElevatedButton(
                              onPressed: () async {
                                list.clear();
                                setState(() {
                                  configMAc = false;
                                });
                                for (int i = 0; i < 4; i++) {
                                  final mac = await QRScannerWidget(context, "QR Code Battery ${i + 1}");
                                  if (mac != null && mac.isNotEmpty) {
                                    setState(() {
                                      list.add(mac);
                                    });
                                  }

                                  await Future.delayed(const Duration(milliseconds: 800)); // optional gap
                                }
                                setState(() {
                                  configMAc = true;
                                });
                              },
                              child: Text("Quad", style: TextStyle(color: Colors.white54)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ValueListenableBuilder<bool>(
                          valueListenable: macController.isBusy,
                          builder: (context, busy, _) {
                            if (!busy) return SizedBox();
                            return ValueListenableBuilder<String>(
                              valueListenable: macController.progressText,
                              builder: (_, text, __) {
                                return Text(text, style: const TextStyle(color: Colors.white));
                              },
                            );
                          },
                        ),

                        const SizedBox(height: 12),
                        ListView.builder(
                          shrinkWrap: true, // 👈 allows height to grow
                          physics: const NeverScrollableScrollPhysics(), // 👈 disables inner scrolling
                          itemCount: list.length,
                          itemBuilder: (context, i) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  IconButton(
                                    onPressed: () async {
                                      setState(() {
                                        configMAc = false;
                                      });
                                      await Future.delayed(const Duration(milliseconds: 500)); // optional gap

                                      final mac = await QRScannerWidget(context, "QR Code Battery ${i + 1}");
                                      if (mac != null && mac.isNotEmpty) {
                                        await Future.delayed(
                                          const Duration(milliseconds: 800),
                                        ); // optional gap

                                        setState(() {
                                          list[i] = mac;
                                          configMAc = true;
                                        });
                                      }
                                    },
                                    icon: Icon(Icons.edit, color: AppColors.neonBlue),
                                  ),
                                  Text(
                                    "B${i + 1} - ${list[i]}",
                                    style: const TextStyle(fontSize: 16, color: Colors.white70),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 14),
                        if (configMAc)
                          SizedBox(
                            width: double.infinity,
                            height: 44,
                            child: ElevatedButton(
                              onPressed:
                                  list.length >= 2
                                      ? () async {
                                        // 👉 Proceed action
                                        printFunc("Proceed clicked with MACs: $list");
                                        configMAc = false;
                                        setState(() {});
                                        // call API / navigate / start BLE config here
                                        await macController.programMacs(macList: list);
                                        setState(() {
                                          assignBat = false;
                                          list.clear();
                                          configMAc = false;
                                        });
                                      }
                                      : null, // disabled if not enough batteries
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                padding: EdgeInsets.zero,
                              ),
                              child: Ink(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF00E5FF), // cyan glow
                                      Color(0xFF1DE9B6), // teal
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(color: Color(0x5500E5FF), blurRadius: 12, spreadRadius: 1),
                                  ],
                                ),
                                child: const Center(
                                  child: Text(
                                    "Proceed",
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),

                        // _valueTile("time", "$timestamp",  Colors.blueAccent),
                      ],
                    ),
                  ),
                ),
              ),
            if (!assignBat)
              ValueListenableBuilder<List<Map?>>(
                valueListenable: macController.batInfo,
                builder: (_, batInfo, __) {
                  getSize(context);
                  if (batInfo.isEmpty) {
                    return const Center(child: Text("No data"));
                  }
                  return Container(
                    padding: EdgeInsets.only(bottom: 15),
                    height: screenSize.height * 0.65,
                    width: screenSize.width * 0.9,
                    child: GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.55, // 🔥 makes tile taller
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemCount: batInfo.length,
                      itemBuilder: (BuildContext context, int index) {
                        return BatteryInfoTile(data: batInfo[index] ?? {}, macController: macController);
                        Container(
                          width: 200,
                          child: Card(child: Center(child: Text('${batInfo[index]?["mac"]}'))),
                        );
                      },
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
