import 'package:flutter/material.dart';

import 'features/home/home_page.dart';

class CijiApp extends StatelessWidget {
  const CijiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '词迹 Ciji',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF00897B),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}
