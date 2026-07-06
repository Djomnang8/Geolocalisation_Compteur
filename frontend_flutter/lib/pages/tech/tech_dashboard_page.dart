import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/app_colors.dart';
import '../../core/session.dart';
import '../../models/compteur.dart';
import '../../services/compteur_service.dart';
import '../../widgets/soc_widgets.dart';
import 'tech_meter_page.dart';

/// Tableau de bord personnel du technicien (maquette "TECH DASHBOARD") :
/// salutation, indicateurs (attribués / réalisés / à inspecter), bouton
/// "Itinéraire du jour" et liste "Mes compteurs".
class TechDashboardPage extends StatefulWidget {
  final VoidCallback? ouvrirCarte;
  const TechDashboardPage({super.key, this.ouvrirCarte});

  @override
  State<TechDashboardPage> createState() => _TechDashboardPageState();
}

class _TechDashboardPageState extends State<TechDashboardPage> {
  List<Compteur>? _compteurs;
  String? _erreur;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    try {
      final compteurs = await CompteurService.instance
          .lister(technicien: Session.instance.utilisateur!.matricule);
      if (mounted) setState(() { _compteurs = compteurs; _erreur = null; });
    } catch (e) {
      if (mounted) setState(() => _erreur = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final utilisateur = Session.instance.utilisateur!;
    final compteurs = _compteurs ?? const <Compteur>[];
    final realises = compteurs.where((c) => c.statut != 'NON_INSPECTE').length;
    final aInspecter = compteurs.where((c) => c.statut == 'NON_INSPECTE').length;

    return RefreshIndicator(
      onRefresh: _charger,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 26),
        children: [
          Text('Bonjour,',
              style: GoogleFonts.ibmPlexSans(
                  fontSize: 13, color: AppColors.texteSecondaire)),
          const SizedBox(height: 2),
          Text(utilisateur.nom,
              style: GoogleFonts.ibmPlexSans(
                  fontSize: 21, fontWeight: FontWeight.w700, color: AppColors.texte)),
          const SizedBox(height: 3),
          Text('${utilisateur.matricule} · Technicien',
              style: GoogleFonts.ibmPlexMono(fontSize: 12, color: AppColors.texteLeger)),
          const SizedBox(height: 18),

          if (_erreur != null) ...[
            EncadreVide(texte: 'Impossible de charger les données.\n$_erreur'),
            const SizedBox(height: 14),
          ],

          // Indicateurs
          Row(children: [
            Expanded(
                child: _CarteKpi(
                    valeur: '${compteurs.length}',
                    label: 'Compteurs attribués',
                    fond: AppColors.primaire,
                    texteBlanc: true)),
            const SizedBox(width: 10),
            Expanded(
                child: _CarteKpi(
                    valeur: '$realises',
                    label: 'Inspections réalisées',
                    couleurValeur: AppColors.vert)),
            const SizedBox(width: 10),
            Expanded(
                child: _CarteKpi(
                    valeur: '$aInspecter',
                    label: 'À inspecter',
                    couleurValeur: AppColors.jaune)),
          ]),
          const SizedBox(height: 14),

          // Bouton itineraire du jour (degrade bleu, comme la maquette)
          Material(
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: widget.ouvrirCarte,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [AppColors.primaire, Color(0xFF1D4AA6)]),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                        color: AppColors.primaire.withValues(alpha: 0.22),
                        blurRadius: 18,
                        offset: const Offset(0, 8)),
                  ],
                ),
                child: Row(children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: const Icon(Icons.route, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Itinéraire du jour',
                            style: GoogleFonts.ibmPlexSans(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w600,
                                color: Colors.white)),
                        const SizedBox(height: 2),
                        Text('Trajet optimisé · $aInspecter arrêts',
                            style: GoogleFonts.ibmPlexSans(
                                fontSize: 11.5,
                                color: Colors.white.withValues(alpha: 0.82))),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.white),
                ]),
              ),
            ),
          ),
          const SizedBox(height: 22),

          // Mes compteurs
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Mes compteurs',
                  style: GoogleFonts.ibmPlexSans(
                      fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.texte)),
              TextButton(
                onPressed: widget.ouvrirCarte,
                child: Text('Voir la carte',
                    style: GoogleFonts.ibmPlexSans(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaire)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          if (_compteurs == null && _erreur == null)
            const Padding(
              padding: EdgeInsets.all(30),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (compteurs.isEmpty)
            const EncadreVide(
                texte: 'Aucun compteur ne vous est attribué pour le moment.')
          else
            ...compteurs.map((c) => Padding(
                  padding: const EdgeInsets.only(bottom: 9),
                  child: CarteCompteur(
                    compteur: c,
                    onTap: () => Navigator.of(context)
                        .push(MaterialPageRoute(
                            builder: (_) => TechMeterPage(compteur: c)))
                        .then((_) => _charger()),
                  ),
                )),
        ],
      ),
    );
  }
}

class _CarteKpi extends StatelessWidget {
  final String valeur;
  final String label;
  final Color? fond;
  final Color? couleurValeur;
  final bool texteBlanc;

  const _CarteKpi({
    required this.valeur,
    required this.label,
    this.fond,
    this.couleurValeur,
    this.texteBlanc = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: fond ?? Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: fond == null ? Border.all(color: AppColors.bordure) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(valeur,
              style: GoogleFonts.ibmPlexSans(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  height: 1,
                  color: texteBlanc ? Colors.white : (couleurValeur ?? AppColors.texte))),
          const SizedBox(height: 5),
          Text(label,
              style: GoogleFonts.ibmPlexSans(
                  fontSize: 11,
                  height: 1.25,
                  color: texteBlanc
                      ? Colors.white.withValues(alpha: 0.82)
                      : AppColors.texteSecondaire)),
        ],
      ),
    );
  }
}
