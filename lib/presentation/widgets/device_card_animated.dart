import 'dart:async';

import 'package:dfi_seekr/routes/app_routes.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/bluetooth_service.dart';

class DeviceCardAnimated extends StatefulWidget {
  final String id;
  final String name;
  final int rssi;
  final Future<bool> Function() onConnect;
  final VoidCallback onConnected;
  final BluetoothService service;
  final bool connected;

  final dynamic onDisconnect;

  const DeviceCardAnimated({
    super.key,
    required this.id,
    required this.name,
    required this.rssi,
    required this.onConnect,
    required this.onConnected,
    required this.onDisconnect,
    required this.service,
    required this.connected,
  });

  @override
  State<DeviceCardAnimated> createState() => _DeviceCardAnimatedState();
}

class _DeviceCardAnimatedState extends State<DeviceCardAnimated> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool connecting = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _rssiColor(int rssi) {
    if (rssi > -60) return AppColors.neonBlue;
    if (rssi > -80) return AppColors.neonAccent;
    return Colors.white24;
  }

  @override
  Widget build(BuildContext context) {
    final slide = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    final bool isConnected = widget.connected;

    return SlideTransition(
      position: slide,
      child: Card(
        color: Color(0x7F3C424B), // AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: ListTile(
          onTap: () async {
            if (isConnected) {
              await Future.delayed(Duration(seconds: 1));
              Navigator.pushNamed(context, AppRoutes.deviceDetail, arguments: {"bluetooth": widget.service});
            }
          },
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          title: Text(widget.name, style: const TextStyle(color: Colors.white)),
          subtitle: Text(widget.id, style: const TextStyle(color: Colors.white70)),
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                center: Alignment.topCenter,
                colors: [_rssiColor(widget.rssi).withOpacity(0.9), Colors.transparent],
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.device_hub, color: _rssiColor(widget.rssi)),
                const SizedBox(height: 4),
                Text(widget.rssi.toString(), style: const TextStyle(color: Colors.white, fontSize: 11)),
              ],
            ),
          ),
          trailing: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child:
                isConnected
                    ? ElevatedButton(
                      key: const ValueKey('connected'),
                      onPressed: () async {
                        setState(() => connecting = true);

                        await widget.service.disconnect(widget.id);
                        widget.onDisconnect();

                        setState(() {
                          setState(() => connecting = false);
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        backgroundColor: Colors.white10,
                      ),
                      child:
                          connecting
                              ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                              : Container(
                                key: const ValueKey('connected'),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  gradient: const LinearGradient(
                                    colors: [AppColors.neonBlue, AppColors.neonAccent],
                                  ),
                                ),
                                child: const Text('Connected', style: TextStyle(color: Colors.black)),
                              ),
                      // const Text('connected'),
                    )
                    /*
            Container(
              key: const ValueKey('connected'),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: const LinearGradient(colors: [AppColors.neonBlue, AppColors.neonAccent]),
              ),
              child: const Text('Connected', style: TextStyle(color: Colors.black)),
            )
*/
                    : ElevatedButton(
                      key: const ValueKey('connect'),
                      onPressed: () async {
                        setState(() => connecting = true);

                        // if another device is connected, disconnect it first via service
                        if (widget.service.connectedDeviceId != null &&
                            widget.service.connectedDeviceId != widget.id) {
                          await widget.service.disconnect(widget.service.connectedDeviceId!);
                        }

                        final ok = await widget.onConnect();

                        // parent (dashboard) will be notified through widget.onConnected()
                        connecting = false;
                        if (mounted)
                        setState(() {
                        });

                        if (ok) {
                          widget.onConnected();

                          // Navigator.pushNamed(
                          //   context,
                          //   AppRoutes.deviceDetail,
                          //   arguments: {"bluetooth": widget.service},
                          // );                  // Navigator.pushNamed(context, AppRoutes.deviceDetail, arguments: {"deviceId": widget.id});
                        }
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.white10),
                      child:
                          connecting
                              ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                              : const Text('Connect'),
                    ),
          ),
        ),
      ),
    );
  }
}
