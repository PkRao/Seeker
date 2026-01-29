import 'package:dfi_seekr/core/constants/app_colors.dart';
import 'package:dfi_seekr/core/constants/constants.dart';
import 'package:dfi_seekr/core/services/bluetooth_service.dart';
import 'package:dfi_seekr/presentation/screens/bluetooth/bt_off_screen.dart';
import 'package:dfi_seekr/presentation/widgets/dialogBox.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' hide BluetoothService;

class SeekerBaseScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? bottomNav;
  final FloatingActionButton? fab;
  final bool applyPadding;
  final bool btCheck;
  final BluetoothService _bluetooth = BluetoothService();

  SeekerBaseScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.bottomNav,
    this.fab,
    this.applyPadding = true,
    this.btCheck = true,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // prevent auto pop
      onPopInvoked: (didPop) async {
        if (didPop) return;

        final shouldExit = await showExitDialog(context);

        if (shouldExit == true) {
          await _bluetooth.cleanupStaleConnection();
          Navigator.of(context).pop(); // exit app
        }
      },
      child: Scaffold(
        extendBody: true,
        extendBodyBehindAppBar: true,
        backgroundColor: Colors.transparent,
        appBar: appBar,
        floatingActionButton: fab,
        bottomNavigationBar: bottomNav,
        body: Container(
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.bgStart, AppColors.bgEnd],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Stack(
              children: [
                // ===== MAIN CONTENT =====
                Padding(
                  padding:
                      applyPadding
                          ? const EdgeInsets.symmetric(horizontal: 16, vertical: 10)
                          : EdgeInsets.zero,
                  child:
                      btCheck
                          ? StreamBuilder<BluetoothAdapterState>(
                            stream: FlutterBluePlus.adapterState,
                            initialData: BluetoothAdapterState.unknown,
                            builder: (context, snapshot) {
                              final state = snapshot.data;

                              if (state != BluetoothAdapterState.on) {
                                return BluetoothOffScreen(adapterState: state!);
                              }
                              return body;
                            },
                          )
                          : body,
                ),

                // ===== VERSION TEXT (BOTTOM CENTER) =====
                Positioned(
                  bottom: 6,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Text(
                      "v ${AppConst.appVersion}",
                      style: const TextStyle(fontSize: 11, color: Colors.white38, letterSpacing: 0.8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        /*
      Container(
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.bgStart, AppColors.bgEnd],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: applyPadding
                  ? const EdgeInsets.symmetric(horizontal: 16, vertical: 10)
                  : EdgeInsets.zero,
              child: btCheck
                  ? StreamBuilder<BluetoothAdapterState>(
                stream: FlutterBluePlus.adapterState,
                initialData: BluetoothAdapterState.unknown,
                builder: (context, snapshot) {
                  final state = snapshot.data;

                  if (state != BluetoothAdapterState.on) {
                    return BluetoothOffScreen(adapterState: state!);
                  }
                  return body;
                },
              )
                  : body,
            ),
          ),
        ),
        */
      ),
    );
  }
}
