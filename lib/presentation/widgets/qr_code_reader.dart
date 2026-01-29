// import 'dart:ui';
// import 'package:dfi_seekr/core/utils/logger.dart';
// import 'package:flutter/material.dart';
// import 'package:mobile_scanner/mobile_scanner.dart';
//
// /// ===============================
// /// QR SCANNER DIALOG FUNCTION
// /// ===============================
// Future<String?> QRScannerWidget(
//     BuildContext context,
//     String title,
//     ) {
//   return showDialog<String>(
//     barrierDismissible: false,
//     context: context,
//     builder: (context) {
//       return BackdropFilter(
//         filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
//         child: AlertDialog(
//           backgroundColor: Colors.black87,
//           elevation: 6,
//           title: Text(
//             title,
//             style: const TextStyle(
//               color: Colors.white,
//               fontSize: 18,
//               fontWeight: FontWeight.w600,
//             ),
//           ),
//           content: const QRScannerScreen(),
//         ),
//       );
//     },
//   );
// }
//
// /// ===============================
// /// QR SCANNER SCREEN
// /// ===============================
// class QRScannerScreen extends StatefulWidget {
//   const QRScannerScreen({super.key});
//
//   @override
//   State<QRScannerScreen> createState() => _QRScannerScreenState();
// }
//
// class _QRScannerScreenState extends State<QRScannerScreen> {
//   final MobileScannerController controller = MobileScannerController();
//   bool isScanned = false;
//
//   void _onDetect(BarcodeCapture capture) {
//     if (isScanned) return;
//
//     final String? code = capture.barcodes.first.rawValue;
//     printFunc("Code : $code");
//
//     if (code == null || code.isEmpty) return;
//
//     isScanned = true;
//     controller.stop();
//
//     Future.delayed(const Duration(milliseconds: 400), () {
//       Navigator.pop(context, code); // ✅ RETURN VALUE
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final size = MediaQuery.of(context).size;
//
//     return SizedBox(
//       width: size.width * 0.85,
//       height: size.width * 0.85,
//       child: ClipRRect(
//         borderRadius: BorderRadius.circular(12),
//         child: MobileScanner(
//           controller: controller,
//           onDetect: _onDetect,
//         ),
//       ),
//     );
//   }
//
//   @override
//   void dispose() {
//     controller.dispose();
//     super.dispose();
//   }
// }

import 'dart:ui';

import 'package:dfi_seekr/core/utils/logger.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// ===============================
/// QR SCANNER DIALOG FUNCTION
/// ===============================
Future<String?> QRScannerWidget(BuildContext context, String title) {
  return showDialog<String>(
    barrierDismissible: false,
    context: context,
    builder: (context) {
      return BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: AlertDialog(
          backgroundColor: Colors.black87,
          elevation: 6,
          title: Text(
            title,
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
          ),
          content: const QRScannerScreen(),
        ),
      );
    },
  );
}

/// ===============================
/// QR SCANNER SCREEN
/// ===============================
class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final MobileScannerController controller = MobileScannerController();

  bool isScanned = false;
  bool showInvalidMsg = false;

  // ✅ MAC ADDRESS REGEX
  final RegExp macRegex = RegExp(r'^([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})$');

  void _onDetect(BarcodeCapture capture) {
    if (isScanned) return;

    final String? code = capture.barcodes.first.rawValue;
    printFunc("Scanned Code : $code");

    if (code == null || code.isEmpty) return;

    // ✅ Validate MAC
    if (!macRegex.hasMatch(code.trim())) {
      setState(() {
        showInvalidMsg = true;
      });
      return; // ❌ don't close dialog
    }

    // ✅ Valid MAC
    setState(() {
      showInvalidMsg = false;
      isScanned = true;
    });

    controller.stop();

    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) {
        Navigator.pop(context, code.trim());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ❌ INVALID MESSAGE
        if (showInvalidMsg)
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text(
              "Scan valid MAC ID",
              style: TextStyle(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),

        SizedBox(
          width: size.width * 0.85,
          height: size.width * 0.85,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: MobileScanner(controller: controller, onDetect: _onDetect),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
