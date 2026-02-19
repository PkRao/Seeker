import 'dart:async';

import 'package:dfi_seekr/core/services/bluetooth_adapter_state.dart';
import 'package:dfi_seekr/core/services/bluetooth_service.dart';
import 'package:dfi_seekr/presentation/widgets/dif_logo.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/ui/seeker_base_scaffold.dart';
import '../../../routes/app_routes.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  final BluetoothService _bluetooth = BluetoothService();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    _scaleAnim = Tween<double>(
      begin: 1.0,
      end: 1.08,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    BluetoothStateManager.startListening();
    _bluetooth.cleanupStaleConnection();
    Timer(const Duration(milliseconds: 6000), () {
      Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SeekerBaseScaffold(
      applyPadding: false,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                ring(160, 0.0, 0.4, _controller),
                ring(220, 0.12, 0.3, _controller),
                ring(300, 0.24, 0.2, _controller),
                ScaleTransition(
                  scale: _scaleAnim,
                  child: Image.asset(
                    'assets/images/dreamFly2.jpg',
                    width: 200,
                    height: 200,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Seekr',
              style: TextStyle(
                color: AppColors.neonBlue,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
