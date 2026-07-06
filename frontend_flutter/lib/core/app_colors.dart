import 'package:flutter/material.dart';

/// Charte graphique SOCADEL (identique a la maquette UX/UI) :
/// uniquement le bleu, le vert, le rouge, le gris et le blanc,
/// conformement au logo de l'entreprise et au cahier des charges.
class AppColors {
  AppColors._();

  // Bleus institutionnels
  static const Color primaire = Color(0xFF15357A);
  static const Color primaireFonce = Color(0xFF0F2350);
  static const Color primaireNuit = Color(0xFF0B1B3D);
  static const Color bleuClair = Color(0xFF1763C7);
  static const Color fondBleuClair = Color(0xFFEAF0FB);

  // Fonds et surfaces
  static const Color fond = Color(0xFFF4F6F9);
  static const Color blanc = Color(0xFFFFFFFF);
  static const Color bordure = Color(0xFFE6EAF0);
  static const Color bordureInput = Color(0xFFD4DAE3);
  static const Color separateur = Color(0xFFF0F2F5);

  // Textes
  static const Color texte = Color(0xFF16202E);
  static const Color texteSecondaire = Color(0xFF67748A);
  static const Color texteLeger = Color(0xFF8A93A0);
  static const Color texteLabel = Color(0xFF3A475C);

  // Statuts des compteurs (identiques a la maquette)
  static const Color vert = Color(0xFF1F9D55);
  static const Color vertFond = Color(0xFFE7F6EE);
  static const Color orange = Color(0xFFD98A00);
  static const Color orangeFond = Color(0xFFFDF2DD);
  static const Color rouge = Color(0xFFD63B3B);
  static const Color rougeSombre = Color(0xFFB32626);
  static const Color rougeFond = Color(0xFFFDEAEA);
  static const Color gris = Color(0xFF9AA3AF);
  static const Color grisFond = Color(0xFFEEF0F3);
  static const Color bleuFond = Color(0xFFE8F0FC);

  // Divers
  static const Color jaune = Color(0xFFE8A100);
  static const Color inactifNav = Color(0xFF9AA3B2);
}
