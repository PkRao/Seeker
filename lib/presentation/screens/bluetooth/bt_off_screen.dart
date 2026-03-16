import 'dart:io';

import 'package:dfi_seekr/core/constants/app_colors.dart';
import 'package:dfi_seekr/core/utils/logger.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BluetoothOffScreen extends StatelessWidget {
  const BluetoothOffScreen({super.key, this.adapterState});

  final BluetoothAdapterState? adapterState;

  Widget buildBluetoothOffIcon(BuildContext context) {
    return Icon(
      Icons.bluetooth_disabled,
      size: 200.0,
      color: AppColors.neonBlue.withOpacity(0.9),
      shadows: [
        Shadow(color: Colors.black, blurRadius: 0.1, offset: Offset(0.4, 0.4)),
      ],
    );
  }

  Widget buildTitle(BuildContext context) {
    return Text(
      'Bluetooth is Turned off',
      style: TextStyle(
        color: AppColors.darkBg,
        fontWeight: FontWeight.w800,
        fontSize: 16,
        // fontFamily:
      ),
    );
  }

  Widget buildTurnOnButton(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(20.0),
      child: ElevatedButton(
        style: ButtonStyle(
          elevation: MaterialStatePropertyAll(5),
          backgroundColor: MaterialStatePropertyAll(AppColors.darkBg),
          shadowColor: MaterialStatePropertyAll(Colors.black),
          shape: MaterialStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        child: Text(
          'TURN ON',
          style: TextStyle(
            color: AppColors.neonBlue,
            // fontFamily: baseFont,
            fontWeight: FontWeight.w500,
          ),
        ),
        onPressed: () async {
          try {
            if (!kIsWeb && Platform.isAndroid) {
              await FlutterBluePlus.turnOn();
            }
          } catch (e, backtrace) {
            //showsnack bar
            // ShowSnackBarMessage(
            //     context, prettyException('Error Turning On :', e), false);
            printFunc("$e");
            printFunc("backtrace: $backtrace");
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      // key: Snackbar.snackBarKeyA,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.bgStart, AppColors.bgEnd],
            // Your gradient colors
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                buildBluetoothOffIcon(context),
                buildTitle(context),
                if (!kIsWeb && Platform.isAndroid) buildTurnOnButton(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String prettyException(String prefix, dynamic e) {
    if (e is FlutterBluePlusException) {
      return "$prefix ${e.description}";
    } else if (e is PlatformException) {
      return "$prefix ${e.message}";
    }
    return prefix + e.toString();
  }
}
