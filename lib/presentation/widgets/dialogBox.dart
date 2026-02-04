import 'dart:ui';

import 'package:dfi_seekr/core/constants/app_colors.dart';
import 'package:dfi_seekr/core/services/generalMethods.dart';
import 'package:flutter/material.dart';

popUpDialog(
  BuildContext context,
  String btn1,
  String btn2, {
  required String title,
  required String content,
  required Function() onPressBtn1,
  required Function() onPressBtn2,
}) {
  return showDialog<String>(
    barrierDismissible: false,
    context: context,
    builder: (context) {
      return BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: AlertDialog(
          backgroundColor: Colors.black87,
          elevation: 6,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
              ),
              IconButton(
                onPressed: () {
                  Navigator.of(context, rootNavigator: true).pop();
                },
                icon: Icon(Icons.close, color: AppColors.errorText),
              ),
            ],
          ),
          content: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                width: screenSize.width * 0.7,
                constraints: BoxConstraints(
                  maxHeight: screenSize.height * 0.35, // 👈 responsive
                ),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    colors: [Colors.white30, Colors.white10],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(color: Colors.white12, width: 1.0),
                  boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 18, offset: const Offset(0, 6))],
                ),
                child: Column(
                  children: [
                    // 🔽 SCROLLABLE TEXT AREA
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Text(
                          content,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white60.withOpacity(0.95),
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Divider
                    Container(height: 1, color: Colors.white.withOpacity(0.16)),
                    const SizedBox(height: 16),

                    // 🔽 FIXED BUTTONS
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          (btn2.isNotEmpty)
                              ? ElevatedButton(
                                onPressed: onPressBtn2,
                                child: Text(btn2, style: TextStyle(color: Colors.white54)),
                              )
                              : SizedBox(),
                          ElevatedButton(
                            onPressed: onPressBtn1,
                            child: Text(btn1, style: TextStyle(color: Colors.white54)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

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
