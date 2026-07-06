import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/app_colors.dart';

/// Ecran "a venir" : le cahier des charges prevoit la realisation de la
/// moitie des pages de chaque espace pendant le stage ; les autres pages
/// seront developpees dans la seconde moitie du projet.
class PagePlaceholder extends StatelessWidget {
  final String titre;
  const PagePlaceholder({super.key, required this.titre});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 34),
          decoration: BoxDecoration(
            color: AppColors.grisFond,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: const Color(0xFFC2CAD6)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.construction, size: 40, color: AppColors.texteLeger),
              const SizedBox(height: 14),
              Text(titre,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.ibmPlexSans(
                      fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.texte)),
              const SizedBox(height: 8),
              Text(
                'Cette page fait partie de la seconde moitié du projet.\n'
                'Elle sera développée lors de la prochaine phase.',
                textAlign: TextAlign.center,
                style: GoogleFonts.ibmPlexSans(
                    fontSize: 12.5, color: const Color(0xFF5A6577), height: 1.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
