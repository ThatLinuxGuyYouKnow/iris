import 'package:flutter/material.dart';
import 'package:iris/provider/screen_provider.dart';
import 'package:provider/provider.dart';

import 'package:iris/screens/master_screen.dart';
import 'package:iris/themes/theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [ChangeNotifierProvider<ScreenProvider>(create: (_) => ScreenProvider())],
      child: MaterialApp(
        title: 'Iris',
        theme: buildAppTheme(),
        home: MasterScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
