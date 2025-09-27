import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'pages/home_page.dart'; // 你的 HomePage

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env"); // 確保你的 .env 已存在根目錄
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFF0B6623), // 麻將桌綠
        primaryColor: const Color(0xFF006400), // 深綠
        colorScheme: ColorScheme.fromSwatch().copyWith(
          primary: const Color(0xFF006400),
          secondary: const Color(0xFFFFD700), // 金色代表寶牌
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF006400),
          foregroundColor: Colors.white,
          elevation: 4,
        ),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Colors.white),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF006400),
            foregroundColor: Colors.white,
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color.fromARGB(255, 53, 176, 197),
          foregroundColor: Colors.white,
        ),
      ),
      home: const HomePage(), // 你的主頁面
    );
  }
}
