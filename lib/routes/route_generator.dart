import 'package:flutter/material.dart';

import '../presentation/screens/dashboard/dashboard_page.dart';
import '../presentation/screens/device_detail/device_detail_page.dart';
import '../presentation/screens/provisioning/provisioning_page.dart';
import '../presentation/screens/splash/splash_screen.dart';
import 'app_routes.dart';

class RouteGenerator {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case AppRoutes.dashboard:
        return MaterialPageRoute(builder: (_) => const DashboardPage());
      case AppRoutes.deviceDetail:
        final args = settings.arguments as Map?;
        final bluetooth = args?['bluetooth'];
        return MaterialPageRoute(builder: (_) => DeviceDetailPage(bluetooth: bluetooth));
      case AppRoutes.provisioning:
        return MaterialPageRoute(builder: (_) => const ProvisioningPage());
      default:
        return MaterialPageRoute(builder: (_) => const Scaffold(body: Center(child: Text('Page not found'))));
    }
  }
}
