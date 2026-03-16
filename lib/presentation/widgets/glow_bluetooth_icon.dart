import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

class GlowBluetoothIcon extends StatefulWidget {
  final bool scanning;
  final Widget? icon;
  final double height;
  final double width;

  const GlowBluetoothIcon({
    super.key,
    this.scanning = false,
    this.icon,
    this.height = 80,
    this.width = 80,
  });

  @override
  State<GlowBluetoothIcon> createState() => _GlowBluetoothIconState();
}

class _GlowBluetoothIconState extends State<GlowBluetoothIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    // _controller = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3400),
    )..repeat(reverse: true);
    _scaleAnim = Tween<double>(
      begin: 1.0,
      end: 1.3,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _ring(double size, double delay, double opacity) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = (_controller.value + delay) % 1.0;
        final scale = 1.0 + t * 1.8;
        return Opacity(
          opacity: (1.0 - t) * opacity,
          child: Transform.scale(scale: scale, child: child),
        );
      },
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.neonBlue.withOpacity(0.6),
            width: 2,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
      height: widget.height,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (widget.scanning) _ring(32, 0.0, 0.4),
          if (widget.scanning) _ring(44, 0.12, 0.3),
          if (widget.scanning) _ring(60, 0.24, 0.2),
          ScaleTransition(
            scale: _scaleAnim,
            child:
                widget.icon ??
                Icon(Icons.bluetooth, size: 35, color: AppColors.neonBlue),
          ),
        ],
      ),
    );
/*
    AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final angle = _controller.value * 6.2831;
        final glow =
            0.55 + 0.45 * (0.5 + 0.5 * (1 - (_controller.value - 0.5).abs()));
        return Transform.rotate(
          angle: widget.scanning ? angle : 0.0,
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.neonBlue.withOpacity(glow * 0.18),
                  blurRadius: 40,
                  spreadRadius: 4,
                ),
                BoxShadow(
                  color: AppColors.neonBlueSoft,
                  blurRadius: 80,
                  spreadRadius: 20,
                ),
              ],
            ),
            child: Icon(Icons.bluetooth, size: 55, color: AppColors.neonBlue),
          ),
        );
      },
    );*/
  }
}
