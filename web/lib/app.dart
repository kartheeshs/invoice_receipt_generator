import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'pages/home_shell.dart';
import 'state/app_state.dart';
import 'theme/app_theme.dart';

class InvoiceApp extends StatelessWidget {
  const InvoiceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState(),
      child: MaterialApp(
        title: '和式請求書ジェネレーター',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        home: const HomeShell(),
      ),
    );
  }
}
