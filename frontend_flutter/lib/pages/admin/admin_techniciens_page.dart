import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/app_colors.dart';
import '../../models/utilisateur.dart';
import '../../services/technicien_service.dart';
import '../../widgets/soc_widgets.dart';
import 'admin_tech_form_page.dart';

/// Gestion des techniciens - CRUD administrateur (maquette "ADMIN TECHNICIENS") :
/// recherche (nom, matricule), cartes avec avatar/initiales, rôle, nombre de
/// compteurs, actions Promouvoir/Retirer admin, Modifier, Supprimer, Ajouter.
/// Diagramme de séquence : "Gestion des techniciens (CRUD)".
class AdminTechniciensPage extends StatefulWidget {
  const AdminTechniciensPage({super.key});

  @override
  State<AdminTechniciensPage> createState() => _AdminTechniciensPageState();
}

class _AdminTechniciensPageState extends State<AdminTechniciensPage> {
  final _recherche = TextEditingController();
  List<Utilisateur> _tous = const [];
  int _page = 0; // pagination (10 techniciens par page)
  bool _chargement = true;
  String? _erreur;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    try {
      final utilisateurs = await TechnicienService.instance.lister();
      if (mounted) {
        setState(() { _tous = utilisateurs; _erreur = null; _chargement = false; });
      }
    } catch (e) {
      if (mounted) setState(() { _erreur = e.toString(); _chargement = false; });
    }
  }

  List<Utilisateur> get _filtres {
    final q = _recherche.text.trim().toLowerCase();
    return _tous
        .where((u) =>
            q.isEmpty ||
            u.nom.toLowerCase().contains(q) ||
            u.matricule.toLowerCase().contains(q))
        .toList();
  }

  Future<void> _basculerRole(Utilisateur u) async {
    try {
      await TechnicienService.instance.basculerRole(u.id);
      if (!mounted) return;
      afficherToast(context, 'Rôle modifié');
      _charger();
    } catch (e) {
      if (mounted) afficherErreur(context, e);
    }
  }

  Future<void> _supprimer(Utilisateur u) async {
    final confirme = await showDialog<bool>(
      context: context,
      builder: (contexteDialogue) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Supprimer le compte ?',
            style: GoogleFonts.ibmPlexSans(
                fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.texte)),
        content: Text(
            '${u.nom} (${u.matricule}) sera supprimé. Ses compteurs repasseront en « non attribué ».',
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
      await TechnicienService.instance.supprimer(u.id);
      if (!mounted) return;
      afficherToast(context, 'Technicien supprimé');
      _charger();
    } catch (e) {
      if (mounted) afficherErreur(context, e);
    }
  }

  void _ouvrirFormulaire([Utilisateur? utilisateur]) {
    Navigator.of(context)
        .push(MaterialPageRoute(
            builder: (_) => AdminTechFormPage(utilisateur: utilisateur)))
        .then((_) => _charger());
  }

  @override
  Widget build(BuildContext context) {
    final affiches = _filtres;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primaire,
        elevation: 2,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: Colors.white),
        ),
        title: Text('Techniciens',
            style: GoogleFonts.ibmPlexSans(
                fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
      ),
      body: _chargement
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _charger,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 26),
                children: [
                  TextField(
                    controller: _recherche,
                    onChanged: (_) => setState(() => _page = 0),
                    style: GoogleFonts.ibmPlexSans(
                        fontSize: 13.5, color: AppColors.texte),
                    decoration:
                        decorationSocadel('Rechercher (nom, matricule)').copyWith(
                      prefixIcon: const Icon(Icons.search,
                          size: 18, color: AppColors.texteLeger),
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (_erreur != null) ...[
                    EncadreVide(texte: _erreur!),
                    const SizedBox(height: 10),
                  ],
                  ...PaginationSocadel.tranche(affiches, _page)
                      .map((u) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _CarteTechnicien(
                              utilisateur: u,
                              onBasculerRole: () => _basculerRole(u),
                              onModifier: () => _ouvrirFormulaire(u),
                              onSupprimer: () => _supprimer(u),
                            ),
                          )),
                  PaginationSocadel(
                      total: affiches.length,
                      page: _page,
                      onChange: (p) => setState(() => _page = p)),
                  const SizedBox(height: 6),
                  InkWell(
                    borderRadius: BorderRadius.circular(13),
                    onTap: () => _ouvrirFormulaire(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(13),
                        border:
                            Border.all(color: const Color(0xFFB9C3D2), width: 1.5),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.add, size: 18, color: AppColors.primaire),
                          const SizedBox(width: 8),
                          Text('Ajouter un technicien',
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
            ),
    );
  }
}

class _CarteTechnicien extends StatelessWidget {
  final Utilisateur utilisateur;
  final VoidCallback onBasculerRole;
  final VoidCallback onModifier;
  final VoidCallback onSupprimer;

  const _CarteTechnicien({
    required this.utilisateur,
    required this.onBasculerRole,
    required this.onModifier,
    required this.onSupprimer,
  });

  @override
  Widget build(BuildContext context) {
    final estAdmin = utilisateur.estAdmin;
    final couleurRole = estAdmin ? const Color(0xFF7A4FB5) : AppColors.primaire;
    final fondRole = estAdmin ? const Color(0xFFF1EBF9) : AppColors.fondBleuClair;
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: AppColors.bordure),
      ),
      child: Column(children: [
        Row(children: [
          CircleAvatar(
            radius: 21,
            backgroundColor: fondRole,
            child: Text(utilisateur.initiales,
                style: GoogleFonts.ibmPlexSans(
                    fontSize: 14, fontWeight: FontWeight.w700, color: couleurRole)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(utilisateur.nom,
                    style: GoogleFonts.ibmPlexSans(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.texte)),
                const SizedBox(height: 2),
                Text(utilisateur.matricule,
                    style: GoogleFonts.ibmPlexMono(
                        fontSize: 11, color: AppColors.texteLeger)),
              ],
            ),
          ),
          BadgeStatut(
              texte: utilisateur.roleLibelle,
              couleur: couleurRole,
              fond: fondRole),
        ]),
        const SizedBox(height: 11),
        Container(
          padding: const EdgeInsets.only(top: 11),
          decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.separateur))),
          child: Row(children: [
            Expanded(
              child: Text(
                  '${utilisateur.compteurs} compteur(s) · ${utilisateur.zone ?? '—'}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.ibmPlexSans(
                      fontSize: 11, color: AppColors.texteLeger)),
            ),
            OutlinedButton(
              onPressed: onBasculerRole,
              style: OutlinedButton.styleFrom(
                minimumSize: Size.zero,
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                side: const BorderSide(color: AppColors.bordureInput),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(estAdmin ? 'Retirer admin' : 'Promouvoir admin',
                  style: GoogleFonts.ibmPlexSans(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF7A4FB5))),
            ),
            const SizedBox(width: 7),
            OutlinedButton(
              onPressed: onModifier,
              style: OutlinedButton.styleFrom(
                minimumSize: Size.zero,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                side: const BorderSide(color: AppColors.bordureInput),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Icon(Icons.edit_outlined,
                  size: 14, color: AppColors.primaire),
            ),
            const SizedBox(width: 7),
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
