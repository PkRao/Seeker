import 'package:dfi_seekr/core/services/hive_service.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:permission_handler/permission_handler.dart';

import 'routes/app_routes.dart';
import 'routes/route_generator.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  // open default box (example)
  await Hive.openBox('${HiveService.boxName}');

  await _requestPermissions();
  runApp(const SeekrApp());
}

Future<void> _requestPermissions() async {
  await Permission.location.request();
  await Permission.bluetooth.request();
  await Permission.bluetoothScan.request();
  await Permission.bluetoothConnect.request();
  await Permission.camera.request();
}

class SeekrApp extends StatelessWidget {
  const SeekrApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Seekr',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.transparent,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
      ),
      initialRoute: AppRoutes.splash,
      onGenerateRoute: RouteGenerator.generateRoute,
    );
  }
}
