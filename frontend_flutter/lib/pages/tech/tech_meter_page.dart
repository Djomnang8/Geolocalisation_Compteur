import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/app_colors.dart';
import '../../models/compteur.dart';
import '../../services/compteur_service.dart';
import '../../widgets/soc_widgets.dart';
import '../../widgets/statut.dart';
import 'tech_inspection_page.dart';

/// Détail d'un compteur attribué (maquette "TECH METER DETAIL") :
/// fiche complète (marque, modèle, type, index initial, zone, adresse),
/// bouton "Démarrer l'inspection" et historique des interventions.
class TechMeterPage extends StatefulWidget {
  final Compteur compteur;
  const TechMeterPage({super.key, required this.compteur});

  @override
  State<TechMeterPage> createState() => _TechMeterPageState();
}

class _TechMeterPageState extends State<TechMeterPage> {
  late final Compteur _compteur = widget.compteur;

  Future<void> _voirHistorique() async {
    try {
      final historique = await CompteurService.instance.historique(_compteur.id);
      if (!mounted) return;
      showModalBottomSheet(
        context: context,
        backgroundColor: AppColors.fond,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
        isScrollControlled: true,
        builder: (_) => _FeuilleHistorique(
            reference: _compteur.reference, historique: historique),
      );
    } catch (e) {
      if (mounted) afficherErreur(context, e);
    }
  }

  Future<void> _demarrerInspection() async {
    final envoye = await Navigator.of(context).push<bool>(MaterialPageRoute(
        builder: (_) => TechInspectionPage(compteur: _compteur)));
    if (envoye == true && mounted) {
      Navigator.of(context).pop(); // retour a la carte, statut mis a jour
    }
  }

  @override
  Widget build(BuildContext context) {
    final meta = StatutMeta.de(_compteur.statut);
    return Scaffold(
      appBar: _barreDetail(context, 'Détail compteur'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 26),
        children: [
          Row(children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.fondBleuClair,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.speed, size: 26, color: AppColors.primaire),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_compteur.reference,
                      style: GoogleFonts.ibmPlexMono(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.texte)),
                  const SizedBox(height: 5),
                  BadgeStatut(
                      texte: StatutMeta.libelleComplet(
                          _compteur.statut, _compteur.statutAutre),
                      couleur: meta.couleur,
                      fond: meta.fond),
                ],
              ),
            ),
          ]),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.bordure),
            ),
            child: Column(children: [
              _ligne('Marque', _compteur.marque ?? '—'),
              _ligne('Modèle', _compteur.modele ?? '—'),
              _ligne('Type', _compteur.type),
              _ligne('Index initial', '${_compteur.indexInitial} kWh', mono: true),
              _ligne('Zone', _compteur.zone ?? '—'),
              _ligne('Adresse', _compteur.quartier ?? '—', derniere: true),
            ]),
          ),
          const SizedBox(height: 16),
          BoutonPrincipal(
              texte: "Démarrer l'inspection",
              icone: Icons.edit_outlined,
              onPressed: _demarrerInspection),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _voirHistorique,
              icon: const Icon(Icons.history, size: 18, color: AppColors.primaire),
              label: Text("Voir l'historique",
                  style: GoogleFonts.ibmPlexSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaire)),
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white,
                side: const BorderSide(color: AppColors.bordureInput, width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _ligne(String label, String valeur, {bool mono = false, bool derniere = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 11),
      decoration: BoxDecoration(
        border: derniere
            ? null
            : const Border(bottom: BorderSide(color: AppColors.separateur)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: GoogleFonts.ibmPlexSans(
                  fontSize: 12.5, color: AppColors.texteLeger)),
          const SizedBox(width: 14),
          Expanded(
            child: Text(valeur,
                textAlign: TextAlign.right,
                style: mono
                    ? GoogleFonts.ibmPlexMono(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.texte)
                    : GoogleFonts.ibmPlexSans(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.texte)),
          ),
        ],
      ),
    );
  }
}

/// Barre d'application des pages de detail (fleche retour + titre).
PreferredSizeWidget _barreDetail(BuildContext context, String titre) {
  return AppBar(
    backgroundColor: AppColors.primaire,
    elevation: 2,
    leading: IconButton(
      onPressed: () => Navigator.of(context).pop(),
      icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: Colors.white),
    ),
    title: Text(titre,
        style: GoogleFonts.ibmPlexSans(
            fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
  );
}

/// Historique des interventions du compteur (frise verticale de la maquette).
class _FeuilleHistorique extends StatelessWidget {
  final String reference;
  final List<Map<String, dynamic>> historique;
  const _FeuilleHistorique({required this.reference, required this.historique});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.62,
      builder: (context, controleur) => ListView(
        controller: controleur,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 26),
        children: [
          Center(
            child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: const Color(0xFFCCD4E0),
                    borderRadius: BorderRadius.circular(3))),
          ),
          const SizedBox(height: 14),
          Text(reference,
              style:
                  GoogleFonts.ibmPlexMono(fontSize: 12.5, color: AppColors.texteLeger)),
          const SizedBox(height: 2),
          Text('Historique des interventions',
              style: GoogleFonts.ibmPlexSans(
                  fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.texte)),
          const SizedBox(height: 18),
          if (historique.isEmpty)
            const EncadreVide(
                texte: 'Aucune intervention enregistrée pour ce compteur.\n'
                    "L'historique se construira après votre première inspection.")
          else
            ...historique.map((h) => _EntreeHistorique(entree: h)),
        ],
      ),
    );
  }
}

class _EntreeHistorique extends StatelessWidget {
  final Map<String, dynamic> entree;
  const _EntreeHistorique({required this.entree});

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Frise verticale : point bleu + trait
          Column(children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: AppColors.primaire,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: const [
                  BoxShadow(color: Color(0xFFE1E6EE), spreadRadius: 2),
                ],
              ),
            ),
            Expanded(
                child: Container(width: 2, color: const Color(0xFFE1E6EE))),
          ]),
          const SizedBox(width: 14),
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.bordure),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text('${entree['etat'] ?? '—'}',
                            style: GoogleFonts.ibmPlexSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.texte)),
                      ),
                      Text('${entree['date'] ?? ''}',
                          style: GoogleFonts.ibmPlexMono(
                              fontSize: 10.5, color: AppColors.texteLeger)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text('${entree['note'] ?? '—'}',
                      style: GoogleFonts.ibmPlexSans(
                          fontSize: 12,
                          height: 1.5,
                          color: const Color(0xFF5A6577))),
                  const SizedBox(height: 8),
                  Row(children: [
                    const Icon(Icons.person_outline,
                        size: 13, color: AppColors.texteLeger),
                    const SizedBox(width: 6),
                    Text('${entree['technicien'] ?? '—'}',
                        style: GoogleFonts.ibmPlexSans(
                            fontSize: 11, color: AppColors.texteLeger)),
                  ]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
