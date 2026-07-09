import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/app_colors.dart';
import '../../models/compteur.dart';
import '../../models/utilisateur.dart';
import '../../services/compteur_service.dart';
import '../../services/stats_service.dart';
import '../../services/technicien_service.dart';
import '../../widgets/soc_widgets.dart';

/// Fiche compteur - ajout / modification (maquette "ADMIN METER FORM") :
/// référence, marque, modèle, type, index initial, zone, quartier,
/// latitude / longitude et technicien attribué (attribution intégrée).
/// Diagrammes de séquence : "Attribution d'un compteur à un technicien" + CRUD.
class AdminMeterFormPage extends StatefulWidget {
  final Compteur? compteur; // null = creation
  const AdminMeterFormPage({super.key, this.compteur});

  @override
  State<AdminMeterFormPage> createState() => _AdminMeterFormPageState();
}

class _AdminMeterFormPageState extends State<AdminMeterFormPage> {
  late final _reference = TextEditingController(text: widget.compteur?.reference);
  late final _modele = TextEditingController(text: widget.compteur?.modele);
  late final _index = TextEditingController(text: widget.compteur?.indexInitial);
  late final _quartier = TextEditingController(text: widget.compteur?.quartier);
  late final _latitude =
      TextEditingController(text: widget.compteur?.latitude.toString());
  late final _longitude =
      TextEditingController(text: widget.compteur?.longitude.toString());

  String? _marque;
  String? _type;
  String? _zone;
  String? _technicienMatricule;

  List<String> _zones = const [];
  List<Utilisateur> _techniciens = const [];
  bool _enregistrement = false;

  /// Marques de compteurs electriques utilisees par SOCADEL / ENEO.
  static const _marques = [
    'HEXING', 'INHEMETER', 'DONSUN', 'GENTAI', 'HOLLEY', 'WASION',
    'LANDIS+GYR', 'ITRON', 'EDMI', 'CLOU', 'SHENZHEN STAR', 'ELSTER',
  ];
  static const _types = [
    'Prépayé STS1', 'Prépayé STS2', 'Postpayé', 'Monophasé', 'Triphasé'
  ];

  @override
  void initState() {
    super.initState();
    _marque = widget.compteur?.marque;
    _type = widget.compteur?.type ?? 'Prépayé STS1';
    _zone = widget.compteur?.zone;
    _technicienMatricule = widget.compteur?.technicienMatricule;
    _chargerListes();
  }

  /// Choix de la marque : liste deroulante avec barre de recherche
  /// (feuille de selection filtrable).
  void _choisirMarque() {
    final recherche = TextEditingController();
    // La marque deja enregistree reste proposee meme si elle n'est pas
    // dans la liste standard.
    final toutes = {
      ..._marques,
      if (_marque != null && _marque!.isNotEmpty) _marque!,
    }.toList()
      ..sort();
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
          final filtrees =
              toutes.where((m) => q.isEmpty || m.toLowerCase().contains(q)).toList();
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                            color: const Color(0xFFCCD4E0),
                            borderRadius: BorderRadius.circular(3))),
                  ),
                  Text('Choisir la marque du compteur',
                      style: GoogleFonts.ibmPlexSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.texte)),
                  const SizedBox(height: 10),
                  TextField(
                    controller: recherche,
                    autofocus: true,
                    onChanged: (_) => setStateFeuille(() {}),
                    style: GoogleFonts.ibmPlexSans(
                        fontSize: 13.5, color: AppColors.texte),
                    decoration: decorationSocadel('Rechercher une marque…')
                        .copyWith(
                      prefixIcon: const Icon(Icons.search,
                          size: 18, color: AppColors.texteLeger),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Flexible(
                    child: ListView(
                      shrinkWrap: true,
                      children: [
                        if (_marque != null)
                          ListTile(
                            leading: const Icon(Icons.clear,
                                size: 19, color: AppColors.rougeSombre),
                            title: Text('Effacer la marque',
                                style: GoogleFonts.ibmPlexSans(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.rougeSombre)),
                            onTap: () {
                              Navigator.of(contexteFeuille).pop();
                              setState(() => _marque = null);
                            },
                          ),
                        if (filtrees.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(14),
                            child: EncadreVide(
                                texte: 'Aucune marque ne correspond.'),
                          ),
                        for (final marque in filtrees)
                          ListTile(
                            leading: Icon(
                                marque == _marque
                                    ? Icons.radio_button_checked
                                    : Icons.radio_button_off,
                                size: 19,
                                color: marque == _marque
                                    ? AppColors.primaire
                                    : AppColors.texteLeger),
                            title: Text(marque,
                                style: GoogleFonts.ibmPlexSans(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.texte)),
                            onTap: () {
                              Navigator.of(contexteFeuille).pop();
                              setState(() => _marque = marque);
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

  Future<void> _chargerListes() async {
    try {
      final zones = await StatsService.instance.zones();
      final utilisateurs = await TechnicienService.instance.lister();
      if (mounted) {
        setState(() {
          _zones = zones.map((z) => z['nom'].toString()).toList();
          _techniciens =
              utilisateurs.where((u) => u.role == 'TECHNICIEN').toList();
        });
      }
    } catch (e) {
      if (mounted) afficherErreur(context, e);
    }
  }

  Future<void> _enregistrer() async {
    if (_reference.text.trim().isEmpty) {
      afficherToast(context, 'Référence requise');
      return;
    }
    setState(() => _enregistrement = true);
    try {
      final fiche = {
        'reference': _reference.text.trim(),
        'marque': _marque,
        'modele': _modele.text.trim(),
        'type': _type,
        'indexInitial': _index.text.trim(),
        'quartier': _quartier.text.trim(),
        'latitude': double.tryParse(_latitude.text.replaceAll(',', '.')),
        'longitude': double.tryParse(_longitude.text.replaceAll(',', '.')),
        'zone': _zone,
        'technicienMatricule': _technicienMatricule ?? '',
      };
      if (widget.compteur == null) {
        await CompteurService.instance.creer(fiche);
      } else {
        await CompteurService.instance.modifier(widget.compteur!.id, fiche);
      }
      if (!mounted) return;
      afficherToast(context, 'Compteur enregistré');
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
        title: Text('Fiche compteur',
            style: GoogleFonts.ibmPlexSans(
                fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 30),
        children: [
          ChampSocadel(
              label: 'Référence',
              placeholder: 'CPT-XXXXXX',
              controleur: _reference,
              mono: true),
          const SizedBox(height: 14),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Marque : liste deroulante avec barre de recherche
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Marque (optionnel)',
                      style: GoogleFonts.ibmPlexSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.texteLabel)),
                  const SizedBox(height: 6),
                  Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(11),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(11),
                      onTap: _choisirMarque,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 13),
                        decoration: BoxDecoration(
                          border: Border.all(
                              color: AppColors.bordureInput, width: 1.5),
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: Row(children: [
                          Expanded(
                            child: Text(_marque ?? 'Choisir une marque',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.ibmPlexSans(
                                    fontSize: 13.5,
                                    color: _marque == null
                                        ? AppColors.texteLeger
                                        : AppColors.texte)),
                          ),
                          const Icon(Icons.keyboard_arrow_down,
                              size: 18, color: AppColors.texteLeger),
                        ]),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Modele : champ de saisie libre
            Expanded(
                child: ChampSocadel(
                    label: 'Modèle',
                    placeholder: 'Ex : 0142',
                    controleur: _modele,
                    mono: true)),
          ]),
          const SizedBox(height: 14),
          _Liste(
              label: 'Type',
              valeur: _type,
              options: _types,
              placeholder: 'Choisir un type',
              onChange: (v) => setState(() => _type = v)),
          const SizedBox(height: 14),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
                child: ChampSocadel(
                    label: 'Index initial',
                    controleur: _index,
                    mono: true,
                    clavier: TextInputType.number)),
            const SizedBox(width: 12),
            Expanded(
                child: _Liste(
                    label: 'Zone',
                    valeur: _zone,
                    options: _zones,
                    placeholder: 'Choisir une zone',
                    onChange: (v) => setState(() => _zone = v))),
          ]),
          const SizedBox(height: 14),
          ChampSocadel(
              label: 'Quartier',
              placeholder: 'Ex : Koumassi, Rue 2.045',
              controleur: _quartier),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(
                child: ChampSocadel(
                    label: 'Latitude',
                    placeholder: 'Ex : 4.0512',
                    controleur: _latitude,
                    mono: true,
                    clavier: const TextInputType.numberWithOptions(decimal: true))),
            const SizedBox(width: 12),
            Expanded(
                child: ChampSocadel(
                    label: 'Longitude',
                    placeholder: 'Ex : 9.7689',
                    controleur: _longitude,
                    mono: true,
                    clavier: const TextInputType.numberWithOptions(decimal: true))),
          ]),
          const SizedBox(height: 14),
          _Liste(
            label: 'Technicien attribué',
            valeur: _technicienMatricule,
            options: [
              '',
              ..._techniciens.map((t) => t.matricule),
            ],
            libelles: {
              '': 'Non attribué',
              for (final t in _techniciens)
                t.matricule: '${t.nom} (${t.matricule})',
            },
            placeholder: 'Non attribué',
            onChange: (v) =>
                setState(() => _technicienMatricule = (v ?? '').isEmpty ? null : v),
          ),
          const SizedBox(height: 20),
          BoutonPrincipal(
              texte: 'Enregistrer le compteur',
              enCours: _enregistrement,
              onPressed: _enregistrer),
        ],
      ),
    );
  }
}

/// Liste deroulante au style des champs de la maquette.
class _Liste extends StatelessWidget {
  final String label;
  final String? valeur;
  final List<String> options;
  final Map<String, String>? libelles;
  final String placeholder;
  final ValueChanged<String?> onChange;

  const _Liste({
    required this.label,
    required this.valeur,
    required this.options,
    this.libelles,
    required this.placeholder,
    required this.onChange,
  });

  @override
  Widget build(BuildContext context) {
    final valeurValide =
        valeur != null && options.contains(valeur) ? valeur : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.ibmPlexSans(
                fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.texteLabel)),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          initialValue: valeurValide,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down,
              size: 18, color: AppColors.texteLeger),
          style: GoogleFonts.ibmPlexSans(fontSize: 13.5, color: AppColors.texte),
          decoration: decorationSocadel(placeholder),
          hint: Text(placeholder,
              style: GoogleFonts.ibmPlexSans(
                  fontSize: 13.5, color: AppColors.texteLeger)),
          items: options
              .map((o) => DropdownMenuItem(
                    value: o,
                    child: Text(libelles?[o] ?? o,
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  ))
              .toList(),
          onChanged: onChange,
        ),
      ],
    );
  }
}
