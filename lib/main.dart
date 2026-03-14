import 'package:arcana_forge/app.dart';
import 'package:arcana_forge/config/firebase_bootstrap.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final bootstrapResult = await FirebaseBootstrap.initialize();

  runApp(
    ArcanaForgeApp(
      bootstrapResult: bootstrapResult,
    ),
  );
}
