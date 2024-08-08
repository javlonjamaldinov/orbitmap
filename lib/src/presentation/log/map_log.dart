import 'dart:async'; // Импортируйте для Future
import 'package:flutter/material.dart';
import 'package:orbitmap/src/data/helper/global.dart';
import 'package:orbitmap/src/presentation/screen/map_screen.dart';
import 'package:orbitmap/src/widgets/custom_loading.dart';

class MapLogo extends StatefulWidget {
  const MapLogo({super.key});

  @override
  _MapLogoState createState() => _MapLogoState();
}

class _MapLogoState extends State<MapLogo> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 10), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const MapScreen(),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    mq = MediaQuery.sizeOf(context);

    return Scaffold(
      body: SizedBox(
        width: double.infinity,
        child: Column(
          children: [
            const Spacer(flex: 3),
            Center(
              child: Padding(
                padding: EdgeInsets.all(mq.width * .06),
                child: Image.asset(
                  'assets/images/logo.png',
                  width: mq.width * .2,
                ),
              ),
            ),
            const Spacer(),
            const CustomLoading(),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}
