import 'dart:async';

import 'package:dfi_seekr/presentation/screens/bluetooth/bt_off_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BluetoothMainScreen extends StatefulWidget {
  final Widget Function() onBluetoothOn;

  const BluetoothMainScreen({super.key, required this.onBluetoothOn});

  @override
  State<BluetoothMainScreen> createState() => _BluetoothMainScreenState();
}

class _BluetoothMainScreenState extends State<BluetoothMainScreen> {
  BluetoothAdapterState _adapterState = BluetoothAdapterState.unknown;

  late StreamSubscription<BluetoothAdapterState> _adapterStateStateSubscription;

  @override
  void initState() {
    super.initState();
    _adapterStateStateSubscription = FlutterBluePlus.adapterState.listen((state) {
      _adapterState = state;
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget screen =
        _adapterState == BluetoothAdapterState.on
            // ?  DfuHomePage(SelectedBatch: widget.SelectedBatch, allClients: widget.allClients)
            ? widget.onBluetoothOn()
            : BluetoothOffScreen(adapterState: _adapterState);

    return screen;
  }

  @override
  void dispose() {
    _adapterStateStateSubscription.cancel();
    super.dispose();
  }
}
