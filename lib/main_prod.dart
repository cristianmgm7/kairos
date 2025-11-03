import 'package:flutter/material.dart';
import 'package:kairos/core/config/flavor_config.dart';
import 'package:kairos/main.dart' as main_app;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FlavorConfig.initialize(Flavor.prod);
  await main_app.main();
}
