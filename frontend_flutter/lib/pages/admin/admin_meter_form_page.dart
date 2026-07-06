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
  late final _marque = TextEditingController(text: widget.compteur?.marque);
  late final _index = TextEditingController(text: widget.compteur?.indexInitial);
  late final _quartier = TextEditingController(text: widget.compteur?.quartier);
  late final _latitude =
      TextEditingController(text: widget.compteur?.latitude.toString());
  late final _longitude =
      TextEditingController(text: widget.compteur?.longitude.toString());

  String? _modele;
  String? _type;
  String? _zone;
  String? _technicienMatricule;

  List<String> _zones = const [];
  List<Utilisateur> _techniciens = const [];
  bool _enregistrement = false;

  static const _modeles = ['0142', '0143', '0144', '3723', '3724', '017900', '026'];
  static const _types = [
    'Prépayé STS1', 'Prépayé STS2', 'Postpayé', 'Monophasé', 'Triphasé'
  ];

  @override
  void initState() {
    super.initState();
    _modele = widget.compteur?.modele;
    _type = widget.compteur?.type ?? 'Prépayé STS1';
    _zone = widget.compteur?.zone;
    _technicienMatricule = widget.compteur?.technicienMatricule;
    _chargerListes();
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
        'marque': _marque.text.trim(),
        'modele': _modele,
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
            Expanded(
                child: ChampSocadel(
                    label: 'Marque (optionnel)',
                    placeholder: 'Ex : HEXING',
                    controleur: _marque)),
            const SizedBox(width: 12),
            Expanded(
                child: _Liste(
                    label: 'Modèle',
                    valeur: _modele,
                    options: _modeles,
                    placeholder: 'Choisir un modèle',
                    onChange: (v) => setState(() => _modele = v))),
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
