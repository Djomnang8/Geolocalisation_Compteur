import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/app_colors.dart';
import '../models/compteur.dart';
import 'statut.dart';

/// Petits composants reutilisables, fideles a la maquette UX/UI.

/// Logo SOCADEL (carre blanc arrondi). Si assets/logo.jpeg est absent,
/// une icone eclair de remplacement est affichee.
class LogoSocadel extends StatelessWidget {
  final double taille;
  const LogoSocadel({super.key, this.taille = 34});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: taille,
      height: taille,
      padding: EdgeInsets.all(taille * 0.1),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(taille * 0.26),
      ),
      child: Image.asset(
        'assets/logo.jpeg',
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) =>
            const Icon(Icons.bolt, color: AppColors.primaire),
      ),
    );
  }
}

/// Pastille de statut (texte colore sur fond teinte, arrondi 20).
class BadgeStatut extends StatelessWidget {
  final String texte;
  final Color couleur;
  final Color fond;
  const BadgeStatut({super.key, required this.texte, required this.couleur, required this.fond});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(color: fond, borderRadius: BorderRadius.circular(20)),
      child: Text(texte,
          style: GoogleFonts.ibmPlexSans(
              fontSize: 10.5, fontWeight: FontWeight.w600, color: couleur)),
    );
  }
}

/// Carte "compteur" de la maquette : icone compteur + point de statut,
/// reference en police mono, marque · zone, pastille de statut.
class CarteCompteur extends StatelessWidget {
  final Compteur compteur;
  final VoidCallback? onTap;
  const CarteCompteur({super.key, required this.compteur, this.onTap});

  @override
  Widget build(BuildContext context) {
    final meta = StatutMeta.de(compteur.statut);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        borderRadius: BorderRadius.circular(13),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.bordure),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F3F8),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: const Icon(Icons.speed, size: 20, color: AppColors.primaire),
                  ),
                  Positioned(
                    right: -3,
                    top: -3,
                    child: Container(
                      width: 13,
                      height: 13,
                      decoration: BoxDecoration(
                        color: meta.couleur,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(compteur.reference,
                        style: GoogleFonts.ibmPlexMono(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.texte)),
                    const SizedBox(height: 2),
                    Text('${compteur.marque ?? '—'} · ${compteur.zone ?? '—'}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.ibmPlexSans(
                            fontSize: 11.5, color: AppColors.texteLeger)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              BadgeStatut(
                  texte: StatutMeta.libelleComplet(compteur.statut, compteur.statutAutre),
                  couleur: meta.couleur,
                  fond: meta.fond),
            ],
          ),
        ),
      ),
    );
  }
}

/// Champ de saisie de la maquette (bordure 1.5 grise, arrondi 11).
class ChampSocadel extends StatelessWidget {
  final String label;
  final String? placeholder;
  final TextEditingController controleur;
  final bool motDePasse;
  final bool mono;
  final TextInputType? clavier;
  final int lignes;

  const ChampSocadel({
    super.key,
    required this.label,
    required this.controleur,
    this.placeholder,
    this.motDePasse = false,
    this.mono = false,
    this.clavier,
    this.lignes = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.ibmPlexSans(
                fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.texteLabel)),
        const SizedBox(height: 6),
        TextField(
          controller: controleur,
          obscureText: motDePasse,
          keyboardType: clavier,
          maxLines: lignes,
          style: mono
              ? GoogleFonts.ibmPlexMono(fontSize: 14, color: AppColors.texte)
              : GoogleFonts.ibmPlexSans(fontSize: 14, color: AppColors.texte),
          decoration: decorationSocadel(placeholder),
        ),
      ],
    );
  }
}

/// Decoration commune des champs (identique a la maquette).
InputDecoration decorationSocadel(String? placeholder) => InputDecoration(
      hintText: placeholder,
      hintStyle: GoogleFonts.ibmPlexSans(fontSize: 13.5, color: AppColors.texteLeger),
      filled: true,
      fillColor: Colors.white,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: const BorderSide(color: AppColors.bordureInput, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: const BorderSide(color: AppColors.primaire, width: 1.5),
      ),
    );

/// Bouton principal bleu de la maquette (plein, arrondi 12).
class BoutonPrincipal extends StatelessWidget {
  final String texte;
  final VoidCallback? onPressed;
  final Color couleur;
  final IconData? icone;
  final bool enCours;

  const BoutonPrincipal({
    super.key,
    required this.texte,
    required this.onPressed,
    this.couleur = AppColors.primaire,
    this.icone,
    this.enCours = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: enCours ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: couleur,
          foregroundColor: Colors.white,
          elevation: 4,
          shadowColor: couleur.withValues(alpha: 0.28),
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: enCours
            ? const SizedBox(
                width: 20, height: 20,
                child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icone != null) ...[Icon(icone, size: 19), const SizedBox(width: 9)],
                  Text(texte,
                      style: GoogleFonts.ibmPlexSans(
                          fontSize: 15, fontWeight: FontWeight.w600)),
                ],
              ),
      ),
    );
  }
}

/// Puce de filtre par statut (bordure/fond colores quand active).
class PuceFiltre extends StatelessWidget {
  final String label;
  final int? nombre;
  final bool active;
  final Color couleur;
  final VoidCallback onTap;

  const PuceFiltre({
    super.key,
    required this.label,
    this.nombre,
    required this.active,
    required this.couleur,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: active ? couleur : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: active ? couleur : const Color(0xFFE1E6EE), width: 1.5),
        ),
        child: Text(
          nombre == null ? label : '$label · $nombre',
          style: GoogleFonts.ibmPlexSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: active ? Colors.white : couleur),
        ),
      ),
    );
  }
}

/// Bouton d'ouverture du selecteur de plage de dates (periode), avec une
/// croix pour effacer la plage active.
class BoutonPlageDates extends StatelessWidget {
  final String libelle;
  final bool actif;
  final VoidCallback onTap;
  final VoidCallback? onEffacer;

  const BoutonPlageDates({
    super.key,
    required this.libelle,
    required this.actif,
    required this.onTap,
    this.onEffacer,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: actif ? AppColors.primaire : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: actif ? AppColors.primaire : const Color(0xFFE1E6EE),
              width: 1.5),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.calendar_month_outlined,
              size: 14, color: actif ? Colors.white : AppColors.primaire),
          const SizedBox(width: 6),
          Text(libelle,
              style: GoogleFonts.ibmPlexSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: actif ? Colors.white : AppColors.primaire)),
          if (onEffacer != null) ...[
            const SizedBox(width: 6),
            GestureDetector(
              onTap: onEffacer,
              child: const Icon(Icons.close, size: 14, color: Colors.white),
            ),
          ],
        ]),
      ),
    );
  }
}

/// Barre de pagination de la maquette : visible uniquement quand la liste
/// depasse [parPage] elements (10 par defaut). Affiche « Page x sur y »,
/// les fleches precedent / suivant et le nombre total d'elements.
class PaginationSocadel extends StatelessWidget {
  final int total;
  final int page; // commence a 0
  final int parPage;
  final ValueChanged<int> onChange;

  const PaginationSocadel({
    super.key,
    required this.total,
    required this.page,
    required this.onChange,
    this.parPage = 10,
  });

  /// Nombre de pages necessaires pour [total] elements.
  static int pages(int total, {int parPage = 10}) =>
      total <= parPage ? 1 : (total / parPage).ceil();

  /// Tranche de la liste correspondant a la page demandee.
  static List<T> tranche<T>(List<T> liste, int page, {int parPage = 10}) {
    if (liste.length <= parPage) return liste;
    final debut = (page * parPage).clamp(0, liste.length);
    final fin = (debut + parPage).clamp(0, liste.length);
    return liste.sublist(debut, fin);
  }

  @override
  Widget build(BuildContext context) {
    // La pagination n'apparait que lorsque la liste depasse une page.
    if (total <= parPage) return const SizedBox.shrink();
    final nbPages = pages(total, parPage: parPage);
    final courante = page.clamp(0, nbPages - 1);

    Widget fleche(IconData icone, bool active, VoidCallback onTap) {
      return InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: active ? onTap : null,
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: active ? Colors.white : AppColors.grisFond,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.bordure),
          ),
          child: Icon(icone,
              size: 17,
              color: active ? AppColors.primaire : AppColors.inactifNav),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          fleche(Icons.chevron_left, courante > 0,
              () => onChange(courante - 1)),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 10),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.bordure),
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text('Page ${courante + 1} sur $nbPages',
                  style: GoogleFonts.ibmPlexSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.texte)),
              Text('$total éléments',
                  style: GoogleFonts.ibmPlexSans(
                      fontSize: 10, color: AppColors.texteLeger)),
            ]),
          ),
          fleche(Icons.chevron_right, courante < nbPages - 1,
              () => onChange(courante + 1)),
        ],
      ),
    );
  }
}

/// Encadre vide en pointilles (etats vides de la maquette).
class EncadreVide extends StatelessWidget {
  final String texte;
  const EncadreVide({super.key, required this.texte});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 26),
      decoration: BoxDecoration(
        color: AppColors.grisFond,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0xFFC2CAD6)),
      ),
      child: Text(texte,
          textAlign: TextAlign.center,
          style: GoogleFonts.ibmPlexSans(
              fontSize: 12.5, color: const Color(0xFF5A6577), height: 1.5)),
    );
  }
}

/// Affiche l'erreur reseau/API sous forme de SnackBar.
void afficherErreur(BuildContext context, Object erreur) {
  final message = erreur.toString().contains('SocketException') ||
          erreur.toString().contains('TimeoutException')
      ? "Connexion impossible à l'API Frontend. Vérifiez que les deux API sont démarrées."
      : erreur.toString();
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(message),
    backgroundColor: AppColors.rougeSombre,
    behavior: SnackBarBehavior.floating,
  ));
}

/// SnackBar de confirmation (equivalent du "toast" de la maquette).
void afficherToast(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Row(children: [
      const Icon(Icons.check, color: Color(0xFF3AD07A), size: 17),
      const SizedBox(width: 9),
      Expanded(child: Text(message)),
    ]),
    backgroundColor: AppColors.texte,
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
  ));
}
