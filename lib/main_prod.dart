import 'package:blueprint_app/core/config/flavor_config.dart';
import 'package:blueprint_app/main.dart' as main_app;
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FlavorConfig.initialize(Flavor.prod);
  await main_app.main();
}
