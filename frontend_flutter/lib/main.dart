import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'core/app_colors.dart';
import 'pages/login_page.dart';

/// SOCADEL Geoloc — Application mobile de geolocalisation des compteurs
/// electriques de SOCADEL dans la ville de Douala (agence de Koumassi).
///
/// Architecture (cahier des charges) :
///   Mobile Flutter -> API Frontend (BFF, 8080) -> API Backend (8081)
///   -> Couche de services metier -> Base MySQL (XAMPP).
void main() {
  runApp(const SocadelGeolocApp());
}

class SocadelGeolocApp extends StatelessWidget {
  const SocadelGeolocApp({super.key});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: AppColors.primaireFonce,
      statusBarIconBrightness: Brightness.light,
    ));
    final base = ThemeData(
      useMaterial3: false,
      scaffoldBackgroundColor: AppColors.fond,
      primaryColor: AppColors.primaire,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primaire,
        primary: AppColors.primaire,
      ),
    );
    return MaterialApp(
      title: 'SOCADEL Géoloc',
      debugShowCheckedModeBanner: false,
      theme: base.copyWith(
        textTheme: GoogleFonts.ibmPlexSansTextTheme(base.textTheme),
      ),
      home: const LoginPage(),
    );
  }
}
