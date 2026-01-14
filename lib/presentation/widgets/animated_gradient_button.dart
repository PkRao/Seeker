import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

class AnimatedGradientButton extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;

  const AnimatedGradientButton({super.key, required this.label, required this.onPressed});

  @override
  State<AnimatedGradientButton> createState() => _AnimatedGradientButtonState();
}

class _AnimatedGradientButtonState extends State<AnimatedGradientButton> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onPressed,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, child) {
          final t = _ctrl.value;
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              gradient: LinearGradient(
                colors: [AppColors.neonBlue.withOpacity(0.9 * (0.5 + 0.5 * t)), AppColors.neonAccent],
              ),
            ),
            child: Center(child: Text(widget.label, style: const TextStyle(color: Colors.black))),
          );
        },
      ),
    );
  }
}
class RotatingRefreshButton extends StatefulWidget {
  final VoidCallback onPressed;

  const RotatingRefreshButton({required this.onPressed});

  @override
  State<RotatingRefreshButton> createState() =>
      _RotatingRefreshButtonState();
}

class _RotatingRefreshButtonState extends State<RotatingRefreshButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (_isAnimating) return;

    setState(() => _isAnimating = true);

    widget.onPressed();

    _controller.repeat();

    Future.delayed(const Duration(seconds: 9), () {
      if (!mounted) return;
      _controller.stop();
      _controller.reset();
      setState(() => _isAnimating = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: _handleTap,
      icon: AnimatedBuilder(
        animation: _controller,
        child: const Icon(
          Icons.refresh_outlined,
          color: Colors.lightBlueAccent,
          size: 30,
        ),
        builder: (_, child) {
          return Transform.rotate(
            angle: _controller.value * 6.283185307,
            child: child,
          );
        },
      ),
    );
  }
}
