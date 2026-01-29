import 'package:dfi_seekr/core/constants/app_colors.dart';
import 'package:flutter/cupertino.dart';

Widget ring(double size, double delay, double opacity, _controller) {
  return AnimatedBuilder(
    animation: _controller,
    builder: (context, child) {
      final t = (_controller.value + delay) % 1.0;
      final scale = 1.0 + t * 1.8;
      return Opacity(opacity: (1.0 - t) * opacity, child: Transform.scale(scale: scale, child: child));
    },
    child: Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.neonBlue.withOpacity(0.6), width: 2),
      ),
    ),
  );
}
