import 'dart:ui';

import 'package:dfi_seekr/core/constants/app_colors.dart';
import 'package:dfi_seekr/core/services/generalMethods.dart';
import 'package:dfi_seekr/presentation/widgets/buttons.dart';
import 'package:flutter/material.dart';

popUpDialog(
  BuildContext context,
  String rightBtn,
  String leftBtn, {
  required String title,
  required String content,
  required Function() onPressRightBtn,
  required Function() onPressLeftBtn,
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
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
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
                  maxHeight: screenSize.height * 0.4, // 👈 responsive
                ),
                padding: const EdgeInsets.only(top: 16, left: 16, right: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    colors: [Colors.white30, Colors.white10],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(color: Colors.white12, width: 1.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black54,
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // 🔽 SCROLLABLE TEXT AREA
                    // Expanded(
                    const SizedBox(height: 16),

                    // Divider
                    Expanded(
                      // child:
                      // Flexible(
                      //   fit: FlexFit.loose,
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Text(
                          "$content \n",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white60.withOpacity(0.95),
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                      // ),
                    ),
                    Container(height: 1, color: Colors.white.withOpacity(0.16)),
                    // const SizedBox(height: 16),

                    // 🔽 FIXED BUTTONS
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8.0,
                        vertical: 16,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          (leftBtn.isNotEmpty)
                              ? GlassButton(
                                text: leftBtn,
                                onPressed: onPressLeftBtn,
                                borderColor: Colors.white24,
                                textColor: Colors.white70,
                              )
                              : SizedBox(),
                          GlassButton(
                            text: rightBtn,
                            onPressed: onPressRightBtn,
                            borderColor: Colors.cyanAccent.withOpacity(0.6),
                            glowColor: Colors.cyanAccent,
                            // borderColor: Colors.white24,
                            textColor: Colors.cyanAccent,
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
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text("No"),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text("Yes"),
            ),
          ],
        ),
  );
}
