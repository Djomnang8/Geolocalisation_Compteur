import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/app_colors.dart';
import '../../models/compteur.dart';
import '../../models/utilisateur.dart';
import '../../services/compteur_service.dart';
import '../../services/technicien_service.dart';
import '../../widgets/soc_widgets.dart';
import '../../widgets/statut.dart';

/// Attribution des compteurs (maquette "ADMIN ATTRIBUTION") : l'administrateur
/// recherche et sélectionne un technicien, puis lui attribue ou lui retire
/// des compteurs. Diagramme de séquence : "Attribution d'un compteur".
class AdminAttributionPage extends StatefulWidget {
  const AdminAttributionPage({super.key});

  @override
  State<AdminAttributionPage> createState() => _AdminAttributionPageState();
}

class _AdminAttributionPageState extends State<AdminAttributionPage> {
  List<Utilisateur> _techniciens = const [];
  List<Compteur> _compteurs = const [];
  Utilisateur? _selection;
  int _page = 0; // pagination (10 compteurs par page)
  bool _chargement = true;
  String? _erreur;
  int? _enCours; // id du compteur en cours d'attribution

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    try {
      final resultats = await Future.wait([
        TechnicienService.instance.lister(),
        CompteurService.instance.lister(),
      ]);
      final techniciens = (resultats[0] as List<Utilisateur>)
          .where((u) => !u.estAdmin)
          .toList();
      if (mounted) {
        setState(() {
          _techniciens = techniciens;
          _compteurs = resultats[1] as List<Compteur>;
          _selection ??= techniciens.isEmpty ? null : techniciens.first;
          _erreur = null;
          _chargement = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _erreur = e.toString(); _chargement = false; });
    }
  }

  /// Selecteur de technicien avec recherche (nom ou matricule).
  void _choisirTechnicien() {
    final recherche = TextEditingController();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.fond,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      isScrollControlled: true,
      constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7),
      builder: (contexteFeuille) => StatefulBuilder(
        builder: (context, setStateFeuille) {
          final q = recherche.text.trim().toLowerCase();
          final filtres = _techniciens
              .where((t) =>
                  q.isEmpty ||
                  t.nom.toLowerCase().contains(q) ||
                  t.matricule.toLowerCase().contains(q))
              .toList();
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                          color: const Color(0xFFCCD4E0),
                          borderRadius: BorderRadius.circular(3))),
                  TextField(
                    controller: recherche,
                    autofocus: true,
                    onChanged: (_) => setStateFeuille(() {}),
                    style: GoogleFonts.ibmPlexSans(
                        fontSize: 13.5, color: AppColors.texte),
                    decoration: decorationSocadel(
                        'Rechercher (nom ou matricule)…'),
                  ),
                  const SizedBox(height: 10),
                  Flexible(
                    child: ListView(
                      shrinkWrap: true,
                      children: [
                        if (filtres.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(14),
                            child: EncadreVide(
                                texte: 'Aucun technicien ne correspond.'),
                          ),
                        for (final t in filtres)
                          ListTile(
                            leading: CircleAvatar(
                              radius: 17,
                              backgroundColor: AppColors.fondBleuClair,
                              child: Text(t.initiales,
                                  style: GoogleFonts.ibmPlexSans(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primaire)),
                            ),
                            title: Text(t.nom,
                                style: GoogleFonts.ibmPlexSans(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.texte)),
                            subtitle: Text('${t.matricule} · ${t.compteurs} compteur(s)',
                                style: GoogleFonts.ibmPlexMono(
                                    fontSize: 11, color: AppColors.texteLeger)),
                            onTap: () {
                              Navigator.of(contexteFeuille).pop();
                              setState(() => _selection = t);
                            },
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Attribue le compteur au technicien selectionne, ou le lui retire.
  Future<void> _basculer(Compteur compteur) async {
    final selection = _selection;
    if (selection == null) return;
    final attribueAuSelectionne =
        compteur.technicienMatricule == selection.matricule;
    setState(() => _enCours = compteur.id);
    try {
      await CompteurService.instance.attribuer(
          compteur.id, attribueAuSelectionne ? '' : selection.matricule);
      await _charger();
      if (mounted) {
        afficherToast(
            context,
            attribueAuSelectionne
                ? '${compteur.reference} retiré à ${selection.nom}'
                : '${compteur.reference} attribué à ${selection.nom}');
      }
    } catch (e) {
      if (mounted) afficherErreur(context, e);
    } finally {
      if (mounted) setState(() => _enCours = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_chargement) {
      return const Center(child: CircularProgressIndicator());
    }
    final selection = _selection;
    return RefreshIndicator(
      onRefresh: _charger,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 26),
        children: [
          Text(
              'Recherchez et sélectionnez un technicien, puis attribuez-lui des compteurs.',
              style: GoogleFonts.ibmPlexSans(
                  fontSize: 12.5,
                  color: AppColors.texteSecondaire,
                  height: 1.5)),
          const SizedBox(height: 11),
          // Selecteur de technicien (combo de la maquette)
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(11),
            child: InkWell(
              borderRadius: BorderRadius.circular(11),
              onTap: _choisirTechnicien,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                decoration: BoxDecoration(
                  border:
                      Border.all(color: AppColors.bordureInput, width: 1.5),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Row(children: [
                  Expanded(
                    child: Text(
                        selection == null
                            ? 'Sélectionner un technicien…'
                            : '${selection.nom} (${selection.matricule})',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.ibmPlexSans(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.texte)),
                  ),
                  const Icon(Icons.expand_more,
                      size: 20, color: AppColors.texteLeger),
                ]),
              ),
            ),
          ),
          const SizedBox(height: 14),
          // Encart "Attribution active"
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: AppColors.fondBleuClair,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Text(
                'Attribution active : ${selection?.nom ?? 'aucun technicien'}',
                style: GoogleFonts.ibmPlexSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaire)),
          ),
          const SizedBox(height: 14),
          if (_erreur != null) ...[
            EncadreVide(texte: _erreur!),
            const SizedBox(height: 10),
          ],
          if (_compteurs.isEmpty && _erreur == null)
            const EncadreVide(texte: 'Aucun compteur enregistré.'),
          ...PaginationSocadel.tranche(_compteurs, _page).map((c) {
            final meta = StatutMeta.de(c.statut);
            final attribueAuSelectionne = selection != null &&
                c.technicienMatricule == selection.matricule;
            return Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: AppColors.bordure),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Row(children: [
                  Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                          color: meta.couleur, shape: BoxShape.circle)),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(c.reference,
                            style: GoogleFonts.ibmPlexMono(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.texte)),
                        const SizedBox(height: 2),
                        Text(
                            '${c.zone ?? '—'} · ${c.technicienNom ?? 'Non attribué'}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.ibmPlexSans(
                                fontSize: 11, color: AppColors.texteLeger)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 34,
                    child: TextButton(
                      onPressed: _enCours != null || selection == null
                          ? null
                          : () => _basculer(c),
                      style: TextButton.styleFrom(
                        backgroundColor: attribueAuSelectionne
                            ? AppColors.rougeFond
                            : AppColors.fondBleuClair,
                        padding:
                            const EdgeInsets.symmetric(horizontal: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(9)),
                      ),
                      child: _enCours == c.id
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2))
                          : Text(
                              attribueAuSelectionne ? 'Retirer' : 'Attribuer',
                              style: GoogleFonts.ibmPlexSans(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: attribueAuSelectionne
                                      ? AppColors.rougeSombre
                                      : AppColors.primaire)),
                    ),
                  ),
                ]),
              ),
            );
          }),
          PaginationSocadel(
              total: _compteurs.length,
              page: _page,
              onChange: (p) => setState(() => _page = p)),
        ],
      ),
    );
  }
}
