import 'dart:async';
import 'dart:ui';

import 'package:dfi_seekr/core/constants/app_colors.dart';
import 'package:dfi_seekr/core/services/bluetooth_service.dart';
import 'package:dfi_seekr/core/services/generalMethods.dart';
import 'package:dfi_seekr/core/services/seeckr_battery_provisioning_controller.dart';
import 'package:dfi_seekr/core/utils/logger.dart';
import 'package:dfi_seekr/presentation/widgets/animated_gradient_button.dart';
import 'package:dfi_seekr/presentation/widgets/buttons.dart';
import 'package:dfi_seekr/presentation/widgets/dialogBox.dart';
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
  bool isLoading = false;
  bool isLiveData = false;
  String previuserror = "";

  List<String> list = [];
  bool configMAc = false;
  bool adminConfig = false;
  int _adminTapCount = 0;
  Timer? _adminTapResetTimer;
  bool _showSerialInput = false;
  final TextEditingController _serialController = TextEditingController();
  bool _isSerialSubmitting = false;
  bool _canSerialSubmitting = false;

  @override
  void dispose() {
    macController.stopBatInfoPolling();
    macController.errorText.removeListener(_errorListener);
    widget.bluetooth.isConnected.removeListener(_listener);
    _serialController.dispose();
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
        seekerInfoUuid: Uuid.parse("f043176a-5168-11ee-be56-0242ac120024"),
      );
      macController.errorText.addListener(_errorListener);

      macController.startNotifications();
      macController.startDeviceNotifications();
      macController.getSeekrInfo();
      Future.delayed(const Duration(seconds: 5));

      macController.startBatInfoPolling();
      Future.delayed(const Duration(seconds: 16), () {
        isLiveData = true;
      });
      Timer.periodic(Duration(seconds: 60), (_) async {
        previuserror = "";
      });
    } catch (_) {}
  }

  void _errorListener() {
    final msg = macController.errorText.value;

    if (previuserror != msg && msg != null && msg.isNotEmpty && mounted) {
      previuserror = msg;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg, style: TextStyle(color: AppColors.lightBg)),
          backgroundColor: AppColors.card,
          duration: Duration(seconds: 4),
        ),
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

  Color batteryColor(double charge) {
    if (charge < 20) return Colors.redAccent;
    if (charge < 50) return Colors.orangeAccent;
    if (charge < 75) return Colors.yellowAccent.shade700;
    return Colors.greenAccent;
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
                    if (macController.deviceInfo.value.isEmpty) {
                      await Future.delayed(const Duration(milliseconds: 1500));
                    }
                    if (macController.deviceInfo.value.isNotEmpty) {
                      if (macController.deviceInfo.value["Batteries"] != null &&
                          int.parse((macController.deviceInfo.value["Batteries"] ?? 0).toString()) > 0) {
                        // ⚙ Configure Batteries
                        popUpDialog(
                          context,
                          "Ok",
                          "",
                          title: "Warning",
                          content: '''\nYou need to scan QR codes, one by one, in the correct sequence.
Please proceed carefully while scanning, as the scanning order is important.''',
                          onPressLeftBtn: () async {
                            printFunc("no pair"); //     () async {
                            Navigator.of(context, rootNavigator: true).pop();
                          },
                          onPressRightBtn: () async {
                            printFunc("ok pair"); //     () async {

                            Navigator.of(context, rootNavigator: true).pop();

                            setState(() {
                              assignBat = true;
                            });
                            await Future.delayed(const Duration(milliseconds: 1200));

                            list.clear();
                            setState(() {
                              configMAc = false;
                            });

                            for (int i = 0; i < macController.deviceInfo.value["Batteries"]; i++) {
                              final mac = await QRScannerWidget(context, "QR Code Battery ${i + 1}");
                              printFunc("returned mac : $mac");
                              setState(() {
                                if (!(list.contains(mac)))
                                  list.add(mac ?? "");
                                else {
                                  if (list.contains(mac)) {
                                    list.add("");
                                  }
                                }
                              });
                              // if (mac != null && mac.isNotEmpty) {

                              // }
                              printFunc("List : $list");
                              await Future.delayed(const Duration(milliseconds: 800)); // optional gap
                            }
                            setState(() {
                              if (list.length.toString() ==
                                      (macController.deviceInfo.value["Batteries"].toString()) &&
                                  list.every((e) => e.isNotEmpty)) {
                                configMAc = true;
                              } else if (list.isEmpty) {
                                assignBat = false;
                              }
                            });
                          },
                        );
                      } else {
                        popUpDialog(
                          context,
                          "Ok",
                          "",
                          title: "Note",
                          content: '''\nDevice is not configured\n Ask the admin to configure first\n''',
                          onPressRightBtn: () async {
                            printFunc("Ok");

                            Future.delayed(Duration(milliseconds: 600), () {
                              Navigator.of(context, rootNavigator: true).pop();
                            });
                          },
                          onPressLeftBtn: () async {},
                        );
                      }
                    }
                  } else if (value == 2) {
                    // 🧹 Clear All Batteries
                    setState(() {
                      isLoading = true;
                    });
                    if (await macController.clearAllMacs()) {
                      macController.batInfo.value = [];
                      macController.getSeekrInfo();
                    }
                    setState(() {
                      isLoading = false;
                    });
                  } else if (value == 3) {
                    // 🔌 Disconnect Device
                    await widget.bluetooth.disconnect(widget.bluetooth.connectedDeviceId ?? "");
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
                        child: Row(
                          children: const [
                            Icon(Icons.bluetooth_disabled_outlined, color: Colors.orangeAccent, size: 18),
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
        physics: const NeverScrollableScrollPhysics(),
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
                return Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              _adminTapCount++;

                              // Reset timer on every tap
                              _adminTapResetTimer?.cancel();
                              _adminTapResetTimer = Timer(const Duration(seconds: 1), () {
                                _adminTapCount = 0; // taps must be continuous
                              });

                              if (_adminTapCount == 5) {
                                print("You have entered 5 times");

                                setState(() {
                                  adminConfig = true;
                                  _adminTapCount = 0;
                                  _adminTapResetTimer?.cancel();
                                });
                              }
                            },
                            child: const Icon(
                              Icons.bluetooth_connected,
                              color: Colors.lightBlueAccent,
                              size: 30,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.bluetooth.connectedDevice?.name ?? "BLE_Seeker",
                                style: const TextStyle(fontSize: 18, color: Colors.white),
                              ),
                              Text(
                                widget.bluetooth.connectedDevice?.id ?? macController.deviceInfo.value["MAC"],
                                style: const TextStyle(fontSize: 12, color: Colors.white70),
                              ),
                              // const SizedBox(height: 10),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(
                        width: 48,
                        height: 48,
                        child: RotatingRefreshButton(
                          onPressed: () async {
                            printFunc("bussy status : ${macController.isBusy.value}");
                            printFunc("isLoading status : ${isLoading}");
                            setState(() {});
                            macController.stopBatInfoPolling();
                            await macController.getSeekrInfo();
                            macController.startBatInfoPolling();
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            Container(
              margin: EdgeInsets.only(left: 20, right: 20),
              width: screenSize.width,
              child: Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: ValueListenableBuilder<Map>(
                      valueListenable: macController.deviceInfo,
                      builder: (_, deviceInfo, __) {
                        printFunc("BAT Info ${deviceInfo}");
                        getSize(context);
                        if (deviceInfo.isEmpty) {
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.numbers, color: AppColors.lightBg),
                                  const SizedBox(width: 10),
                                  Text(
                                    "-",
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.lightBg,
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Icon(Icons.charging_station_outlined, color: Colors.amberAccent),
                                  const SizedBox(width: 10),

                                  Text(
                                    "-",
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.amber,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(width: 1),
                            ],
                          );
                        } else {
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.numbers, color: AppColors.lightBg),
                                  const SizedBox(width: 10),
                                  Text(
                                    "${deviceInfo["SerialNo"] ?? " ----"}",
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.lightBg,
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Icon(Icons.charging_station_outlined, color: Colors.amberAccent),
                                  const SizedBox(width: 10),

                                  Text(
                                    "${deviceInfo["Batteries"]}",
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.amber,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(width: 1),
                            ],
                          );
                        }
                      },
                    ),
                  ),
                  ValueListenableBuilder<List<Map?>>(
                    valueListenable: macController.batInfo,
                    builder: (_, batInfo, __) {
                      printFunc("BAT Info ${batInfo}");
                      printFunc("BAT Info live  ${isLiveData}");
                      getSize(context);
                      var avgVolt = 0.0;
                      var avgCharge = 0.0;
                      int noOfLiveBat = 0;
                      for (int i = 0; i < batInfo.length; i++) {
                        if (batInfo[i] != null) {
                          if (batInfo[i]?["valid"] == true &&
                              batInfo[i]?["voltage"] != null &&
                              batInfo[i]?["voltage"]! > 0) {
                            noOfLiveBat++;
                            avgVolt += num.parse((batInfo[i]!["voltage"] ?? 0).toString());
                            avgCharge += num.parse((batInfo[i]!["%"] ?? 0).toString());
                          }
                        }
                      }

                      avgVolt = (avgVolt / (noOfLiveBat)) / 100;
                      avgCharge = (avgCharge / (noOfLiveBat));
                      // avgVolt = batInfo.where((e) => (e["voltage"] ?? 0) > 0).map((e) => (e["voltage"] as num).toDouble()).reduce((a, b) => a + b) / batInfo.where((e) => (e["voltage"] ?? 0) > 0).length;
                      //  avgVolt =batInfo.any((e) => num.tryParse(e["voltage"].toString()) != null && num.tryParse(e["voltage"].toString())! > 0)
                      //      ? batInfo.map((e) => num.tryParse(e["voltage"].toString()) ?? 0).where((v) => v > 0).reduce((a, b) => a + b) /
                      //      batInfo.map((e) => num.tryParse(e["voltage"].toString()) ?? 0).where((v) => v > 0).length
                      //      : 0.0;
                      //  avgVolt = batInfo.any((e) => (e?["voltage"] ?? 0) > 0) ? batInfo.where((e) => (e?["voltage"] ?? 0) > 0).map((e) => (e?["voltage"] as num).toDouble()).reduce((a, b) => a + b) / batInfo.where((e) => (e?["voltage"] ?? 0) > 0).length : 0.0;

                      return Row(
                        children: [
                          Icon(
                            Icons.battery_alert_outlined,
                            color: batteryColor(avgCharge), //AppColors.neonAccent,
                          ),
                          Text(
                            "${(avgVolt ?? 0.0).toStringAsFixed(2)}",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: batteryColor(avgCharge), // AppColors.neonAccent,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),
            (adminConfig == true)
                ? ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                    child: Container(
                      width: screenSize.width * 0.7,
                      constraints: BoxConstraints(
                        maxHeight: screenSize.height * 0.35, // 👈 responsive
                      ),
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
                        mainAxisAlignment: MainAxisAlignment.start,

                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          // 🔽 SCROLLABLE TEXT AREA
                          Container(
                            width: double.infinity,
                            height: 40,
                            // color: Colors.amber,
                            child: Stack(
                              children: [
                                Positioned(
                                  right: 00,
                                  top: 0,
                                  child: IconButton(
                                    onPressed: () {
                                      setState(() {
                                        adminConfig = false;
                                        _serialController.clear();
                                      });
                                    },
                                    icon: Icon(Icons.close_outlined, color: Colors.redAccent, size: 20),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Expanded(
                          Text(
                            "Developer Option",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white60.withOpacity(0.95),
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Divider
                          Container(height: 1, color: Colors.white.withOpacity(0.16)),
                          Expanded(child: const SizedBox(height: 0)),
                          InkWell(
                            onTap: () {
                              popUpDialog(
                                context,
                                "Quad",
                                "Duo",
                                title: "Note",
                                content: '''\nSelect Number of batteries to be configured''',
                                onPressRightBtn: () async {
                                  printFunc("Quad"); //
                                  popUpDialog(
                                    context,
                                    "Ok",
                                    "",
                                    title: "Note",
                                    content: '''\nBattery configuration will be set to 4\n''',
                                    onPressRightBtn: () async {
                                      await macController.batteryAdminConfig("QUAD");
                                      printFunc("Ok");

                                      Future.delayed(Duration(milliseconds: 600), () {
                                        Navigator.of(context, rootNavigator: true).pop();
                                      });
                                      Future.delayed(Duration(milliseconds: 600), () {
                                        Navigator.of(context, rootNavigator: true).pop();
                                        setState(() {});
                                      });
                                    },
                                    onPressLeftBtn: () async {},
                                  );
                                },
                                onPressLeftBtn: () async {
                                  popUpDialog(
                                    context,
                                    "Ok",
                                    "",
                                    title: "Note",
                                    content: '''\nBattery configuration will be set to 2\n''',
                                    onPressRightBtn: () async {
                                      await macController.batteryAdminConfig("PAIR");
                                      printFunc("Ok");
                                      Future.delayed(Duration(milliseconds: 600), () {
                                        Navigator.of(context, rootNavigator: true).pop();
                                      });
                                      Future.delayed(Duration(milliseconds: 600), () {
                                        Navigator.of(context, rootNavigator: true).pop();
                                        setState(() {});
                                      });
                                    },
                                    onPressLeftBtn: () async {},
                                  );
                                },
                              );
                            },
                            child: Row(
                              children: const [
                                Icon(Icons.settings_outlined, color: Colors.cyanAccent, size: 18),
                                SizedBox(width: 10),
                                Text("Configure Batteries", style: TextStyle(color: Colors.white)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          InkWell(
                            onTap: () async {
                              setState(() {
                                _showSerialInput = !_showSerialInput;
                              });
                            },
                            child: Row(
                              children: const [
                                Icon(Icons.confirmation_number, color: Colors.orangeAccent, size: 18),
                                SizedBox(width: 10),
                                Text("Seekr Serial Number", style: TextStyle(color: Colors.white)),
                              ],
                            ),
                          ),

                          // 🔽 INPUT FIELD (SHOW / HIDE)
                          AnimatedSize(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeInOut,
                            child:
                                _showSerialInput
                                    ? Padding(
                                      padding: const EdgeInsets.only(top: 12),
                                      child: Row(
                                        children: [
                                          // 🔹 Input
                                          Expanded(
                                            child: Container(
                                              height: 42,
                                              padding: const EdgeInsets.symmetric(horizontal: 14),
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(20),
                                                gradient: LinearGradient(
                                                  colors: [Colors.white30, Colors.white10],
                                                ),
                                                border: Border.all(color: Colors.white24),
                                              ),
                                              child: TextField(
                                                controller: _serialController,
                                                style: const TextStyle(color: Colors.white),
                                                keyboardType: TextInputType.number,
                                                maxLength: 5,

                                                onChanged: (value) {
                                                  setState(() {
                                                    _canSerialSubmitting = false;
                                                  });
                                                  if (value.length == 5) {
                                                    printFunc("SSN : $value");
                                                    if (!value.isEmpty) {
                                                      // check numeric only
                                                      final int? number = int.tryParse(value);
                                                      if (number != null) {
                                                        // check range (0 – 65535)
                                                        if (number > 0 && number < 65535)
                                                          setState(() {
                                                            _canSerialSubmitting = true;
                                                          });
                                                      }
                                                    }
                                                  }
                                                },
                                                decoration: InputDecoration(
                                                  hintText: "Serial Number",
                                                  maintainHintSize: true,
                                                  hintStyle: TextStyle(color: Colors.white38),
                                                  border: InputBorder.none,
                                                  counterText: "", // 👈 hides "0/4"
                                                ),
                                              ),
                                            ),
                                          ),

                                          const SizedBox(width: 12),

                                          // 🔹 Glass OK Button
                                          if (_canSerialSubmitting)
                                            GestureDetector(
                                              onTap:
                                                  _isSerialSubmitting
                                                      ? null
                                                      : () async {
                                                        final serial = _serialController.text.trim();
                                                        if (serial.isEmpty) return;

                                                        setState(() {
                                                          _isSerialSubmitting = true;
                                                        });

                                                        printFunc("Serial Entered: $serial");
                                                        await macController.setSeekrSerial(serial);

                                                        // 🔹 Simulate API / BLE call
                                                        await Future.delayed(const Duration(seconds: 3));

                                                        if (!mounted) return;

                                                        setState(() {
                                                          _isSerialSubmitting = false;
                                                          _canSerialSubmitting = false;
                                                          _showSerialInput = false; // 👈 hide input
                                                          _serialController.clear();
                                                        });
                                                      },
                                              child: Container(
                                                height: 42,
                                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                                decoration: BoxDecoration(
                                                  borderRadius: BorderRadius.circular(30),
                                                  border: Border.all(
                                                    color: Colors.cyanAccent.withOpacity(0.6),
                                                  ),
                                                  gradient: LinearGradient(
                                                    colors: [
                                                      Colors.white.withOpacity(0.25),
                                                      Colors.white.withOpacity(0.08),
                                                    ],
                                                  ),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.cyanAccent.withOpacity(0.25),
                                                      blurRadius: 14,
                                                    ),
                                                  ],
                                                ),
                                                child: Center(
                                                  child:
                                                      _isSerialSubmitting
                                                          ? const SizedBox(
                                                            width: 18,
                                                            height: 18,
                                                            child: CircularProgressIndicator(
                                                              strokeWidth: 2,
                                                              color: Colors.cyanAccent,
                                                            ),
                                                          )
                                                          : const Text(
                                                            "OK",
                                                            style: TextStyle(
                                                              color: Colors.cyanAccent,
                                                              fontWeight: FontWeight.w600,
                                                              letterSpacing: 0.6,
                                                            ),
                                                          ),
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    )
                                    : const SizedBox.shrink(),
                          ),
                          const SizedBox(height: 16),
                          InkWell(
                            onTap: () {
                              popUpDialog(
                                context,
                                "Ok",
                                "",
                                title: "Note",
                                content: '''\nAre you sure you want to clear all configuration ?\n''',
                                onPressRightBtn: () async {
                                  await macController.clearAdminConfig();
                                  printFunc("Ok");
                                  Future.delayed(Duration(milliseconds: 600), () {
                                    Navigator.of(context, rootNavigator: true).pop();
                                    setState(() {});
                                  });
                                },
                                onPressLeftBtn: () {},
                              );
                            },
                            child: Row(
                              children: const [
                                Icon(Icons.delete_forever_outlined, color: Colors.redAccent, size: 18),
                                SizedBox(width: 10),
                                Text("Clear All Configuration", style: TextStyle(color: Colors.white)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 60),
                        ],
                      ),
                    ),
                  ),
                )
                : assignBat == true
                ? ClipRRect(
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
                          // const SizedBox(height: 18),
                          // Row(
                          //   mainAxisAlignment: MainAxisAlignment.spaceAround,
                          //   children: [
                          //     ElevatedButton(
                          //       onPressed: () async {
                          //         list.clear();
                          //         setState(() {
                          //           configMAc = false;
                          //         });
                          //
                          //         for (int i = 0; i < 2; i++) {
                          //           final mac = await QRScannerWidget(context, "QR Code Battery ${i + 1}");
                          //           if (mac != null && mac.isNotEmpty) {
                          //             setState(() {
                          //               list.add(mac);
                          //             });
                          //           }
                          //
                          //           await Future.delayed(const Duration(milliseconds: 800)); // optional gap
                          //         }
                          //
                          //         setState(() {
                          //           configMAc = true;
                          //         });
                          //       },
                          //       child: Text("Pair", style: TextStyle(color: Colors.white54)),
                          //     ),
                          //     ElevatedButton(
                          //       onPressed: () async {
                          //         list.clear();
                          //         setState(() {
                          //           configMAc = false;
                          //         });
                          //         for (int i = 0; i < 4; i++) {
                          //           final mac = await QRScannerWidget(context, "QR Code Battery ${i + 1}");
                          //           if (mac != null && mac.isNotEmpty) {
                          //             setState(() {
                          //               list.add(mac);
                          //             });
                          //           }
                          //
                          //           await Future.delayed(const Duration(milliseconds: 800)); // optional gap
                          //         }
                          //         setState(() {
                          //           configMAc = true;
                          //         });
                          //       },
                          //       child: Text("Quad", style: TextStyle(color: Colors.white54)),
                          //     ),
                          //   ],
                          // ),
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
                                        await Future.delayed(
                                          const Duration(milliseconds: 500),
                                        ); // optional gap

                                        final mac = await QRScannerWidget(
                                          context,
                                          "QR Code Battery ${i + 1}",
                                        );
                                        if (mac != null && mac.isNotEmpty) {
                                          await Future.delayed(
                                            const Duration(milliseconds: 800),
                                          ); // optional gap

                                          setState(() {
                                            if (list.contains(mac)) {
                                              list[i] = "";
                                            } else {
                                              list[i] = mac;
                                              configMAc = true;
                                            }
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
                              child: StandardButton(
                                text: "Proceed",
                                onPressed:
                                    list.length >= 2
                                        ? () async {
                                          // 👉 Proceed action
                                          printFunc("Proceed clicked with MACs: $list");
                                          // list[0]="C2:9B:27:7F:50:00";
                                          // list[1]="DD:18:AD:D4:BD:04";
                                          // list.add("C2:9B:27:7F:50:09");
                                          // list.add("C3:76:63:4E:4B:19");
                                          setState(() {
                                            configMAc = false;
                                            isLoading = true;
                                            assignBat = false;
                                          });
                                          // call API / navigate / start BLE config here
                                          await macController.programMacs(macList: list);
                                          await macController.getSeekrInfo();

                                          setState(() {
                                            assignBat = false;
                                            list.clear();
                                            configMAc = false;
                                            isLoading = false;
                                          });
                                        }
                                        : () {},
                              ),
                            ),
                          ValueListenableBuilder<bool>(
                            valueListenable: macController.isBusy,
                            builder: (_, isBusy, __) {
                              getSize(context);
                              if (isBusy && !assignBat && !configMAc) {
                                return const Center(
                                  child: SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.cyanAccent,
                                    ),
                                  ),
                                );
                              } else {
                                return SizedBox();
                              }
                            },
                          ),
                          // _valueTile("time", "$timestamp",  Colors.blueAccent),
                        ],
                      ),
                    ),
                  ),
                )
                : ValueListenableBuilder<List<Map?>>(
                  valueListenable: macController.batInfo,
                  builder: (_, batInfo, __) {
                    printFunc("BAT Info ${batInfo}");
                    printFunc("BAT Info live  ${isLiveData}");
                    getSize(context);
                    return ValueListenableBuilder<bool>(
                      valueListenable: macController.isBusy,
                      builder: (_, isbussy, __) {
                        getSize(context);
                        if (isbussy && isLoading) {
                          return const Center(
                            child: SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.cyanAccent),
                            ),
                          );
                        } else {
                          if (batInfo.isEmpty) {
                            return Container(
                              height: screenSize.height * 0.7,
                              width: screenSize.width * 0.9,
                              child: Center(
                                child: Column(
                                  children: [
                                    SizedBox(
                                      child: Image.asset('assets/images/dreamFly2.jpg'),
                                      width: 200,
                                      height: 200,
                                    ),
                                    isLiveData
                                        ? const Center(child: Text("No data"))
                                        : CircularProgressIndicator(strokeWidth: 2, color: Colors.cyanAccent),
                                  ],
                                ),
                              ),
                            );
                          }

                          return Container(
                            padding: EdgeInsets.only(bottom: 10),
                            margin: EdgeInsets.only(bottom: 15),
                            height: screenSize.height * 0.7,
                            width: screenSize.width * 0.9,
                            child: GridView.builder(
                              // physics:const BouncingScrollPhysics(),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 0.6, // 🔥 makes tile taller
                                crossAxisSpacing: 30,
                                mainAxisSpacing: 20,
                              ),
                              itemCount:
                                  int.tryParse(macController.deviceInfo.value["Batteries"].toString()) ??
                                  batInfo.length,
                              itemBuilder: (BuildContext context, int index) {
                                return BatteryInfoTile(
                                  data: batInfo[index] ?? {},
                                  macController: macController,
                                );
                              },
                            ),
                          );
                        }
                      },
                    );
                  },
                ),
          ],
        ),
      ),
    );
  }
}
