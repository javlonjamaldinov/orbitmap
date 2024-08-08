import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:orbitmap/src/presentation/log/map_log.dart';
import 'package:orbitmap/src/presentation/screen/map_screen.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
   await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  await SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MapLogo(),
    );
  }
}
