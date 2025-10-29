import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; 
import 'screens/login_screen.dart';
import 'theme/app_colors.dart' as theme;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Alerta Comunitaria',
      theme: ThemeData(
        fontFamily: 'Roboto',
        primaryColor: theme.AppColors.primary,
        scaffoldBackgroundColor: theme.AppColors.backgroundDark,
        colorScheme: ColorScheme.dark(
          primary: theme.AppColors.primary,
          secondary: theme.AppColors.accentBlue,
          error: theme.AppColors.error,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: theme.AppColors.backgroundDark,
          elevation: 0,
          iconTheme: IconThemeData(color: theme.AppColors.textLight),
          titleTextStyle: TextStyle(
            color: theme.AppColors.textLight,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          selectedItemColor: theme.AppColors.accentBlue,
          unselectedItemColor: theme.AppColors.textMuted,
          backgroundColor: theme.AppColors.surfaceDark,
        ),
      ),
      home: const LoginScreen(),
    );
  }
}
