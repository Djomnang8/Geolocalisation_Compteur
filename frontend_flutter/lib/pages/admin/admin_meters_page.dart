import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/app_colors.dart';
import '../../models/compteur.dart';
import '../../services/compteur_service.dart';
import '../../widgets/soc_widgets.dart';
import '../../widgets/statut.dart';
import 'admin_meter_form_page.dart';

/// Gestion des compteurs - CRUD administrateur (maquette "ADMIN METERS CRUD") :
/// recherche (n°, zone, technicien attribué), filtres par statut, cartes avec
/// boutons Modifier / Supprimer et bouton "Ajouter un compteur".
/// Diagramme de séquence : "Recherche d'un compteur par numéro" + CRUD.
class AdminMetersPage extends StatefulWidget {
  const AdminMetersPage({super.key});

  @override
  State<AdminMetersPage> createState() => _AdminMetersPageState();
}

class _AdminMetersPageState extends State<AdminMetersPage> {
  final _recherche = TextEditingController();
  List<Compteur> _tous = const [];
  String _filtre = 'TOUS';
  bool _chargement = true;
  String? _erreur;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    try {
      final compteurs = await CompteurService.instance.lister();
      if (mounted) {
        setState(() { _tous = compteurs; _erreur = null; _chargement = false; });
      }
    } catch (e) {
      if (mounted) setState(() { _erreur = e.toString(); _chargement = false; });
    }
  }

  List<Compteur> get _filtres {
    final q = _recherche.text.trim().toLowerCase();
    return _tous.where((c) {
      final okStatut = _filtre == 'TOUS' || c.statut == _filtre;
      final okRecherche = q.isEmpty ||
          c.reference.toLowerCase().contains(q) ||
          (c.quartier ?? '').toLowerCase().contains(q) ||
          (c.zone ?? '').toLowerCase().contains(q) ||
          (c.technicienNom ?? '').toLowerCase().contains(q);
      return okStatut && okRecherche;
    }).toList();
  }

  Future<void> _supprimer(Compteur c) async {
    final confirme = await showDialog<bool>(
      context: context,
      builder: (contexteDialogue) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Supprimer le compteur ?',
            style: GoogleFonts.ibmPlexSans(
                fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.texte)),
        content: Text(
            'La fiche ${c.reference} et son historique seront définitivement supprimés.',
            style: GoogleFonts.ibmPlexSans(
                fontSize: 13, color: AppColors.texteSecondaire, height: 1.5)),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(contexteDialogue).pop(false),
              child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.of(contexteDialogue).pop(true),
            child: Text('Supprimer',
                style: GoogleFonts.ibmPlexSans(
                    fontWeight: FontWeight.w600, color: AppColors.rougeSombre)),
          ),
        ],
      ),
    );
    if (confirme != true) return;
    try {
      await CompteurService.instance.supprimer(c.id);
      if (!mounted) return;
      afficherToast(context, 'Compteur supprimé');
      _charger();
    } catch (e) {
      if (mounted) afficherErreur(context, e);
    }
  }

  void _ouvrirFormulaire([Compteur? compteur]) {
    Navigator.of(context)
        .push(MaterialPageRoute(
            builder: (_) => AdminMeterFormPage(compteur: compteur)))
        .then((_) => _charger());
  }

  @override
  Widget build(BuildContext context) {
    final affiches = _filtres;
    return _chargement
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _charger,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 26),
              children: [
                TextField(
                  controller: _recherche,
                  onChanged: (_) => setState(() {}),
                  style:
                      GoogleFonts.ibmPlexSans(fontSize: 13.5, color: AppColors.texte),
                  decoration: decorationSocadel(
                          'Rechercher (n°, zone, technicien attribué…)')
                      .copyWith(
                    prefixIcon: const Icon(Icons.search,
                        size: 18, color: AppColors.texteLeger),
                  ),
                ),
                const SizedBox(height: 11),
                SizedBox(
                  height: 34,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      PuceFiltre(
                          label: 'Tous',
                          nombre: _tous.length,
                          active: _filtre == 'TOUS',
                          couleur: AppColors.primaire,
                          onTap: () => setState(() => _filtre = 'TOUS')),
                      for (final meta in StatutMeta.liste) ...[
                        const SizedBox(width: 7),
                        PuceFiltre(
                            label: meta.libelle,
                            nombre:
                                _tous.where((c) => c.statut == meta.code).length,
                            active: _filtre == meta.code,
                            couleur: meta.couleur,
                            onTap: () => setState(() => _filtre = meta.code)),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                if (_erreur != null) ...[
                  EncadreVide(texte: _erreur!),
                  const SizedBox(height: 10),
                ],
                ...affiches.map((c) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _CarteCompteurCrud(
                        compteur: c,
                        onModifier: () => _ouvrirFormulaire(c),
                        onSupprimer: () => _supprimer(c),
                      ),
                    )),
                const SizedBox(height: 6),
                // Ajouter un compteur (bordure pointillee de la maquette)
                InkWell(
                  borderRadius: BorderRadius.circular(13),
                  onTap: () => _ouvrirFormulaire(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(color: const Color(0xFFB9C3D2), width: 1.5),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.add, size: 18, color: AppColors.primaire),
                        const SizedBox(width: 8),
                        Text('Ajouter un compteur',
                            style: GoogleFonts.ibmPlexSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaire)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
  }
}

/// Carte compteur du CRUD : infos + attribué + actions Modifier / Supprimer.
class _CarteCompteurCrud extends StatelessWidget {
  final Compteur compteur;
  final VoidCallback onModifier;
  final VoidCallback onSupprimer;

  const _CarteCompteurCrud({
    required this.compteur,
    required this.onModifier,
    required this.onSupprimer,
  });

  @override
  Widget build(BuildContext context) {
    final meta = StatutMeta.de(compteur.statut);
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: AppColors.bordure),
      ),
      child: Column(children: [
        Row(children: [
          Container(
              width: 11,
              height: 11,
              decoration:
                  BoxDecoration(color: meta.couleur, shape: BoxShape.circle)),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(compteur.reference,
                    style: GoogleFonts.ibmPlexMono(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.texte)),
                const SizedBox(height: 2),
                Text(
                    '${compteur.marque ?? ''} ${compteur.modele ?? ''} · ${compteur.zone ?? '—'}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.ibmPlexSans(
                        fontSize: 11, color: AppColors.texteLeger)),
              ],
            ),
          ),
          BadgeStatut(
              texte: StatutMeta.libelleComplet(compteur.statut, compteur.statutAutre),
              couleur: meta.couleur,
              fond: meta.fond),
        ]),
        const SizedBox(height: 11),
        Container(
          padding: const EdgeInsets.only(top: 11),
          decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.separateur))),
          child: Row(children: [
            Expanded(
              child: Text.rich(
                TextSpan(
                  text: 'Attribué : ',
                  style: GoogleFonts.ibmPlexSans(
                      fontSize: 11, color: AppColors.texteLeger),
                  children: [
                    TextSpan(
                        text: compteur.technicienNom ?? 'Non attribué',
                        style: GoogleFonts.ibmPlexSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.texteLabel)),
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            OutlinedButton.icon(
              onPressed: onModifier,
              icon: const Icon(Icons.edit_outlined, size: 13, color: AppColors.primaire),
              label: Text('Modifier',
                  style: GoogleFonts.ibmPlexSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaire)),
              style: OutlinedButton.styleFrom(
                minimumSize: Size.zero,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                side: const BorderSide(color: AppColors.bordureInput),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: onSupprimer,
              style: OutlinedButton.styleFrom(
                minimumSize: Size.zero,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                side: const BorderSide(color: Color(0xFFF3C2C2)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Icon(Icons.delete_outline,
                  size: 14, color: AppColors.rougeSombre),
            ),
          ]),
        ),
      ]),
    );
  }
}
