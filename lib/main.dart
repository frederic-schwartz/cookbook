import 'package:flutter/material.dart';
import 'services/data_migration_service.dart';
import 'screens/startup_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    final migrationService = DataMigrationService();
    await migrationService.performInitialMigration();
  } catch (e) {
    // Migration error handled silently
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cookbook',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const StartupScreen(),
    );
  }
}

