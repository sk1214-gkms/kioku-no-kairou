import 'package:flutter/material.dart';
import 'ad_service.dart';
import 'screens/title_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AdService.instance.init(); // enabled=false の間は即 return
  runApp(const KiokuApp());
}

class KiokuApp extends StatelessWidget {
  const KiokuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'アムネジィ・ケース',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: Colors.deepPurple,
      ),
      home: const TitleScreen(),
    );
  }
}
