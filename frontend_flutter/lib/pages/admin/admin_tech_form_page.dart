import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/app_colors.dart';
import '../../models/utilisateur.dart';
import '../../services/stats_service.dart';
import '../../services/technicien_service.dart';
import '../../widgets/soc_widgets.dart';

/// Fiche technicien - ajout / modification (maquette "ADMIN TECH FORM") :
/// nom, matricule, mot de passe, zone, téléphone et interrupteur
/// « Rôle administrateur » (donner ou retirer les droits d'administration).
/// Diagramme de séquence : "Gestion des techniciens (CRUD)".
class AdminTechFormPage extends StatefulWidget {
  final Utilisateur? utilisateur; // null = creation
  const AdminTechFormPage({super.key, this.utilisateur});

  @override
  State<AdminTechFormPage> createState() => _AdminTechFormPageState();
}

class _AdminTechFormPageState extends State<AdminTechFormPage> {
  late final _nom = TextEditingController(text: widget.utilisateur?.nom);
  late final _matricule = TextEditingController(text: widget.utilisateur?.matricule);
  final _motDePasse = TextEditingController();
  late final _telephone = TextEditingController(text: widget.utilisateur?.telephone);

  String? _zone;
  late bool _estAdmin = widget.utilisateur?.estAdmin ?? false;
  List<String> _zones = const [];
  bool _enregistrement = false;

  @override
  void initState() {
    super.initState();
    _zone = widget.utilisateur?.zone;
    _chargerZones();
  }

  Future<void> _chargerZones() async {
    try {
      final zones = await StatsService.instance.zones();
      if (mounted) {
        setState(() => _zones = zones.map((z) => z['nom'].toString()).toList());
      }
    } catch (_) {
      // Les zones ne sont pas indispensables pour enregistrer la fiche.
    }
  }

  Future<void> _enregistrer() async {
    if (_nom.text.trim().isEmpty || _matricule.text.trim().isEmpty) {
      afficherToast(context, 'Nom et matricule requis');
      return;
    }
    setState(() => _enregistrement = true);
    try {
      final compte = {
        'nom': _nom.text.trim(),
        'matricule': _matricule.text.trim(),
        'motDePasse':
            _motDePasse.text.trim().isEmpty ? null : _motDePasse.text.trim(),
        'role': _estAdmin ? 'ADMIN' : 'TECHNICIEN',
        'zone': _zone,
        'telephone': _telephone.text.trim(),
      };
      if (widget.utilisateur == null) {
        await TechnicienService.instance.creer(compte);
      } else {
        await TechnicienService.instance.modifier(widget.utilisateur!.id, compte);
      }
      if (!mounted) return;
      afficherToast(context, 'Technicien enregistré');
      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) afficherErreur(context, e);
    } finally {
      if (mounted) setState(() => _enregistrement = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primaire,
        elevation: 2,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: Colors.white),
        ),
        title: Text('Fiche technicien',
            style: GoogleFonts.ibmPlexSans(
                fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 30),
        children: [
          ChampSocadel(
              label: 'Nom complet', placeholder: 'Prénom NOM', controleur: _nom),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(
                child: ChampSocadel(
                    label: 'Matricule',
                    placeholder: 'TECH-XXXX',
                    controleur: _matricule,
                    mono: true)),
            const SizedBox(width: 12),
            Expanded(
                child: ChampSocadel(
                    label: 'Mot de passe',
                    placeholder: widget.utilisateur == null
                        ? '••••'
                        : 'Laisser vide pour ne pas changer',
                    controleur: _motDePasse,
                    motDePasse: true)),
          ]),
          const SizedBox(height: 14),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Zone',
                      style: GoogleFonts.ibmPlexSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.texteLabel)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: _zones.contains(_zone) ? _zone : null,
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down,
                        size: 18, color: AppColors.texteLeger),
                    style: GoogleFonts.ibmPlexSans(
                        fontSize: 13.5, color: AppColors.texte),
                    decoration: decorationSocadel('Choisir une zone'),
                    items: _zones
                        .map((z) => DropdownMenuItem(value: z, child: Text(z)))
                        .toList(),
                    onChanged: (v) => setState(() => _zone = v),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
                child: ChampSocadel(
                    label: 'Téléphone',
                    placeholder: '+237 …',
                    controleur: _telephone,
                    clavier: TextInputType.phone)),
          ]),
          const SizedBox(height: 16),
          // Interrupteur "Role administrateur" (identique a la maquette)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.bordure),
            ),
            child: Row(children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Rôle administrateur',
                        style: GoogleFonts.ibmPlexSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.texte)),
                    const SizedBox(height: 2),
                    Text("Donner les droits d'administration",
                        style: GoogleFonts.ibmPlexSans(
                            fontSize: 11, color: AppColors.texteLeger)),
                  ],
                ),
              ),
              Switch(
                value: _estAdmin,
                activeThumbColor: Colors.white,
                activeTrackColor: AppColors.vert,
                inactiveTrackColor: const Color(0xFFCDD4DE),
                onChanged: (v) => setState(() => _estAdmin = v),
              ),
            ]),
          ),
          const SizedBox(height: 18),
          BoutonPrincipal(
              texte: 'Enregistrer le technicien',
              enCours: _enregistrement,
              onPressed: _enregistrer),
        ],
      ),
    );
  }
}
