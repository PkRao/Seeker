import 'dart:ui';

import 'package:dfi_seekr/core/constants/app_colors.dart';
import 'package:dfi_seekr/core/services/seeckr_battery_provisioning_controller.dart';
import 'package:dfi_seekr/core/utils/logger.dart';
import 'package:dfi_seekr/presentation/widgets/qr_code_reader.dart';
import 'package:flutter/material.dart';

class BatteryInfoTile extends StatefulWidget {
  final Map data;
  final MacProgrammingController macController;

  const BatteryInfoTile({super.key, required this.data, required this.macController});

  @override
  State<BatteryInfoTile> createState() => _BatteryInfoTileState();
}

class _BatteryInfoTileState extends State<BatteryInfoTile> {
  bool isLinking = false;

  bool get isLinked => (widget.data["mac"] ?? "") != "";

  Color batteryColor(double charge) {
    if (charge < 20) return Colors.redAccent;
    if (charge < 50) return Colors.orangeAccent;
    if (charge < 75) return Colors.yellowAccent.shade700;
    return Colors.greenAccent;
  }


  Color tempColor(double t) {
    if (t > 55) return Colors.redAccent;
    if (t > 45) return Colors.orangeAccent;
    if (t > 30) return Colors.yellowAccent.shade700;
    return Colors.greenAccent;
  }

  @override
  Widget build(BuildContext context) {
    /*
     {
 "index": "B1",
 "mac": "AA:BB:CC:DD:EE:FF",
 "voltage": 2392,
 "temperature": 2718,
 "percentage": 82,
 "BSN":"252011890",
 "valid":true
 }

    final voltage = widget.data["voltage"] ?? 0;
    final temperature = widget.data["temperature"] ?? 0;
    final charge = widget.data["percentage"] ?? 0;
    final mac = widget.data["mac"] ?? "";
    final bsn = widget.data["BSN"] ?? "";
    final live = (widget.data["valid"]??true).toString()=="true";
    */
    final voltage = widget.data["voltage"] ?? 0;
    final temperature = widget.data["temp"] ?? 0;
    final charge = widget.data["%"] ?? 0;
    final mac = widget.data["mac"] ?? "";
    final bsn = widget.data["BSN"] ?? "";
    final live = (widget.data["valid"] ?? true).toString() == "true";

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          width: 170,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: isLinked ? [Colors.white30, Colors.white10] : [AppColors.bgStart, AppColors.bgEnd],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: isLinked ? Colors.white54 : Colors.white24, width: 2),
            boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 18, offset: Offset(0, 6))],
          ),
          // child: SingleChildScrollView(
            // physics: const NeverScrollableScrollPhysics(),
            // child:        FittedBox(fit:BoxFit.scaleDown,
child:
              isLinked
                    ? _linkedUI(context, live, bsn, mac, charge * 1.0, voltage, temperature)
                    : _notLinkedUI(context),
          // ),
          // ),
        ),
      ),
    );
  }

  // ================= LINKED UI =================
  Widget _linkedUI(
    BuildContext context,
    bool live,
    String bsn,
    String mac,
    double charge,
    int voltage,
    int temperature,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              margin: EdgeInsets.only(right: 5),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: live ? Colors.greenAccent : Colors.redAccent,
                boxShadow: [
                  BoxShadow(
                    color: (!live ? Colors.greenAccent : Colors.redAccent).withOpacity(0.8),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
            Text(
              "Battery- ${(widget.data["index"]).toString().toUpperCase()}",
              style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const Spacer(),
            InkWell(
              onTap: () async {
                setState(() {
                  isLinking = true;
                });
                printFunc("data : ${widget.data}");

                bool Status = await widget.macController.deleteTrackr(widget.data["index"]);
                await Future.delayed(Duration(seconds: widget.macController.interval - 3));

                setState(() {
                  isLinking = false;
                });
              }, // 👈 YOU HANDLE
              child:
                  isLinking
                      ? const Center(
                        child: SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.cyanAccent),
                        ),
                      )
                      : const Icon(Icons.link_off, color: Colors.redAccent, size: 20),
            ),
          ],
        ),

        const SizedBox(height: 16),

        FittedBox(fit:BoxFit.scaleDown,
          child: Text(
            "ID: $bsn",
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            softWrap: false,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ),
        const SizedBox(height: 6),

        FittedBox(fit:BoxFit.scaleDown,
          child: Text(
            "MAC: $mac",
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            softWrap: false,
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ),

        const SizedBox(height: 14),
        Container(height: 1, color: Colors.white38),
        const SizedBox(height: 12),
Expanded(
  child: Center(
    child: SingleChildScrollView(child: Column(children: [
      _valueTile(
        icon: Icons.battery_charging_full,
        label: "Charge",
        value: "${charge.toStringAsFixed(2)} %",
        glowColor: batteryColor(charge),
        ),
        const SizedBox(height: 10),

        _valueTile(
        icon: Icons.electric_bolt,
        label: "Voltage",
        value: "${(voltage / 100).toStringAsFixed(2)} V",
        glowColor: batteryColor(charge),
        ),
        const SizedBox(height: 10),

        _valueTile(
        icon: Icons.thermostat,
        label: "Temp",
        value: "${(temperature / 100).toStringAsFixed(2)}°C",
        glowColor: tempColor((temperature / 100).abs()),
        ),],),

    ),
  ),
),
      ],
    );
  }

  // ================= NOT LINKED UI =================
  Widget _notLinkedUI(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.battery_unknown, color: Colors.white38, size: 36),
        const SizedBox(height: 10),

        FittedBox(fit:BoxFit.scaleDown,
            child: const Text("Link Battery", maxLines: 1, overflow: TextOverflow.clip, style: TextStyle( color: Colors.white54, fontSize: 10))),

        const SizedBox(height: 12),

        SizedBox(
          width: double.infinity,
          height: 36,
          child:
              isLinking
                  ? const Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.cyanAccent),
                    ),
                  )
                  : OutlinedButton.icon(
                    onPressed: () async {
                      final mac = await QRScannerWidget(
                        context,
                        "QR Code Battery ${widget.data["index"] ?? "0"}",
                      );

                      if (mac == null || mac.isEmpty) return;

                      setState(() => isLinking = true); // ✅ show loader

                      await widget.macController.changeTrackr(
                        context,
                        macId: mac,
                        index: widget.data["index"] ?? "b1",
                        safePair: true,
                      );

                      // ⏳ keep loader for 10 seconds
                      await Future.delayed(Duration(seconds: widget.macController.interval - 1));

                      setState(() => isLinking = false);
                    },
                    icon: const Icon(Icons.link, size: 18, color: Colors.cyanAccent),
                    label: const Text("Link Battery",  maxLines: 1,style: TextStyle(
    fontSize: 10,color: Colors.cyanAccent)),

    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.cyanAccent),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
        ),
      ],
    );
  }

  // ================= VALUE TILE =================
  Widget _valueTile({
    bool title = false,
    required IconData icon,
    required String label,
    required String value,
    required Color glowColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
      if(title)  Text(
          label,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            // glowing dot
            // Container(
            //   width: 8,
            //   height: 8,
            //   decoration: BoxDecoration(
            //     color: glowColor,
            //     shape: BoxShape.circle,
            //     boxShadow: [
            //       BoxShadow(
            //         color: glowColor.withOpacity(0.6),
            //         blurRadius: 8,
            //         spreadRadius: 1,
            //       ),
            //     ],
            //   ),
            // ),
            // const SizedBox(width: 8),

            // icon
            Icon(
              icon,
              size: 18,
              color: glowColor,
            ),
            const SizedBox(width: 6),

            // value text
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }
  // Widget _valueTile(String label, String value, Color glowColor) {
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
  //       const SizedBox(height: 3),
  //       Row(
  //         children: [
  //           Container(
  //             width: 8,
  //             height: 8,
  //             decoration: BoxDecoration(
  //               color: glowColor,
  //               shape: BoxShape.circle,
  //               boxShadow: [BoxShadow(color: glowColor.withOpacity(0.6), blurRadius: 8, spreadRadius: 1)],
  //             ),
  //           ),
  //           const SizedBox(width: 8),
  //           Text(
  //             value,
  //             style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
  //           ),
  //         ],
  //       ),
  //     ],
  //   );
  // }
}
