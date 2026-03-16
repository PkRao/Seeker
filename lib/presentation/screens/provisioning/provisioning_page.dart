import 'package:dfi_seekr/presentation/widgets/qr_code_reader.dart';
import 'package:dfi_seekr/presentation/widgets/text_fields.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/ui/seeker_base_scaffold.dart';

class ProvisioningPage extends StatefulWidget {
  const ProvisioningPage({super.key});

  @override
  State<ProvisioningPage> createState() => _ProvisioningPageState();
}

class _ProvisioningPageState extends State<ProvisioningPage> {
  String? scanned;
  TextEditingController macIdController = TextEditingController();

  @override
  Widget build(BuildContext context) {

    return SeekerBaseScaffold(
      appBar: AppBar(
        title: const Text('Provision Tracker'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),
          const Text(
            'Scan Seecker QR (MAC ID expected)',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () async {
              await QRScannerWidget(context, "QRCode");

              setState(() {});
            },
            child: Container(
              margin: EdgeInsets.fromLTRB(30, 15, 30, 5),
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.darkBg),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        CupertinoIcons.qrcode,
                        size: 35,
                        color: AppColors.darkBg,
                        shadows: [Shadow(color: Colors.black, blurRadius: 0.4)],
                      ),
                      SizedBox(width: 10),
                      Text(
                        "Scan QR-Code",
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.darkBg,
                          fontWeight: FontWeight.w500,
                          shadows: [
                            Shadow(color: Colors.black, blurRadius: 0.4),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Icon(
                    CupertinoIcons.chevron_right_2,
                    color: AppColors.darkBg,
                    shadows: [Shadow(color: Colors.black, blurRadius: 0.4)],
                  ),
                ],
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: Container(
                  margin: EdgeInsets.only(left: 30),
                  height: 1,
                  color: Colors.black,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(15),
                child: Text(
                  "OR",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ),
              Expanded(
                child: Container(
                  margin: EdgeInsets.only(right: 30),
                  height: 1,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          TextFeildNewUser(
            hintText: "Enter the MacID",
            Controller: macIdController,
            onChanged: (value) {},
            enable: true,
            etext:
                macIdController.text.trim().isEmpty
                    ? "Please Enter MAC-Id"
                    : "",
          ),
          const SizedBox(height: 12),
          if (scanned != null)
            Text(
              'Scanned: $scanned',
              style: const TextStyle(color: Colors.white70),
            ),
        ],
      ),
    );
  }
}
