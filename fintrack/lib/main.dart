import 'package:flutter/material.dart';
import 'core/config/token_storage.dart';
import 'features/auth/screen/login_page.dart';
import 'features/nav/main_nav.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: FutureBuilder<bool>(
        future: TokenStorage().hasAccessToken(),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data == true) {
            return const MainNav();
          } else {
            return const LoginPage();
          }
        },
      ),
    );
  }
}
