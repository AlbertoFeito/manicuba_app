import 'package:flutter/material.dart';
import 'config/theme.dart';
import 'config/constants.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      theme: AppTheme.getLightTheme(),
      debugShowCheckedModeBanner: false,
      home: const HomeScreen(),
    );
  }
}
