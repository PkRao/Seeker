import 'package:flutter/material.dart';

Future<bool?> showExitDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder:
        (context) => AlertDialog(
          title: const Text("Exit App"),
          content: const Text("Are you sure you want to exit?"),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text("No")),
            ElevatedButton(onPressed: () => Navigator.of(context).pop(true), child: const Text("Yes")),
          ],
        ),
  );
}
