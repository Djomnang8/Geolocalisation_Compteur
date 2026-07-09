import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../core/app_colors.dart';
import '../../services/stats_service.dart';
import '../../widgets/soc_widgets.dart';

/// Journal d'audit (maquette "ADMIN AUDIT") : traçabilité des actions
/// sensibles avec filtres par utilisateur, par plage de dates et par type
/// d'action, affichée en frise chronologique (norme ISO 27001).
class AdminAuditPage extends StatefulWidget {
  const AdminAuditPage({super.key});

  @override
  State<AdminAuditPage> createState() => _AdminAuditPageState();
}

class _AdminAuditPageState extends State<AdminAuditPage> {
  static final _formatDate = DateFormat('dd/MM/yyyy HH:mm');
  static final _formatJour = DateFormat('dd/MM/yyyy');

  List<Map<String, dynamic>> _journal = const [];
  bool _chargement = true;
  String? _erreur;

  String _filtreUtilisateur = 'Tous';
  DateTimeRange? _plage; // plage de dates des actions
  String _filtreType = 'TOUS';
  int _page = 0; // pagination (10 actions par page)

  static const _types = [
    ('TOUS', 'Toutes les actions'),
    ('RAPPORT', 'Rapports'),
    ('GPS', 'Captures GPS'),
    ('ATTRIBUTION', 'Attributions'),
    ('COMPTE', 'Comptes'),
    ('CONNEXION', 'Connexions'),
  ];

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    try {
      final journal = await StatsService.instance.journalAudit();
      if (mounted) {
        setState(() { _journal = journal; _erreur = null; _chargement = false; });
      }
    } catch (e) {
      if (mounted) setState(() { _erreur = e.toString(); _chargement = false; });
    }
  }

  List<String> get _utilisateurs => [
        'Tous',
        ..._journal.map((a) => '${a['utilisateur']}').toSet().toList()..sort(),
      ];

  /// Selecteur de plage de dates (calendrier en francais).
  Future<void> _choisirPlage() async {
    final maintenant = DateTime.now();
    final plage = await showDateRangePicker(
      context: context,
      firstDate: DateTime(maintenant.year - 2),
      lastDate: DateTime(maintenant.year + 1),
      initialDateRange: _plage,
      helpText: 'Période des actions',
      saveText: 'Appliquer',
      builder: (context, enfant) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context)
              .colorScheme
              .copyWith(primary: AppColors.primaire),
        ),
        child: enfant!,
      ),
    );
    if (plage != null) {
      setState(() {
        _plage = plage;
        _page = 0;
      });
    }
  }

  bool _dansLaPlage(String date) {
    if (_plage == null) return true;
    try {
      final d = _formatDate.parse(date);
      final debut =
          DateTime(_plage!.start.year, _plage!.start.month, _plage!.start.day);
      final fin = DateTime(
          _plage!.end.year, _plage!.end.month, _plage!.end.day, 23, 59, 59);
      return !d.isBefore(debut) && !d.isAfter(fin);
    } catch (_) {
      return true;
    }
  }

  bool _correspondType(String action) {
    final a = action.toLowerCase();
    return switch (_filtreType) {
      'RAPPORT' => a.contains('rapport') || a.contains('avis'),
      'GPS' => a.contains('gps') || a.contains('capture'),
      'ATTRIBUTION' => a.contains('attribution'),
      'COMPTE' =>
        a.contains('technicien') || a.contains('rôle') || a.contains('compte'),
      'CONNEXION' => a.contains('connexion'),
      _ => true,
    };
  }

  List<Map<String, dynamic>> get _filtres => _journal.where((a) {
        final okUtilisateur = _filtreUtilisateur == 'Tous' ||
            '${a['utilisateur']}' == _filtreUtilisateur;
        return okUtilisateur &&
            _dansLaPlage('${a['date']}') &&
            _correspondType('${a['action']}');
      }).toList();

  @override
  Widget build(BuildContext context) {
    if (_chargement) {
      return const Center(child: CircularProgressIndicator());
    }
    final affiches = _filtres;
    return RefreshIndicator(
      onRefresh: _charger,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 26),
        children: [
          Text("Traçabilité des actions sensibles (journal d'audit).",
              style: GoogleFonts.ibmPlexSans(
                  fontSize: 12.5, color: AppColors.texteSecondaire)),
          const SizedBox(height: 14),
          // Filtres utilisateur / plage de dates
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Expanded(
                child: _liste('Utilisateur', _filtreUtilisateur, _utilisateurs,
                    (v) => setState(() {
                          _filtreUtilisateur = v;
                          _page = 0;
                        }))),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Période',
                      style: GoogleFonts.ibmPlexSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.texteLeger)),
                  const SizedBox(height: 5),
                  BoutonPlageDates(
                    libelle: _plage == null
                        ? 'Toutes les dates'
                        : '${_formatJour.format(_plage!.start)} – ${_formatJour.format(_plage!.end)}',
                    actif: _plage != null,
                    onTap: _choisirPlage,
                    onEffacer: _plage == null
                        ? null
                        : () => setState(() {
                              _plage = null;
                              _page = 0;
                            }),
                  ),
                ],
              ),
            ),
          ]),
          const SizedBox(height: 12),
          Text("Type d'action",
              style: GoogleFonts.ibmPlexSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.texteLeger)),
          const SizedBox(height: 7),
          SizedBox(
            height: 34,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final (code, libelle) in _types) ...[
                  PuceFiltre(
                      label: libelle,
                      active: _filtreType == code,
                      couleur: AppColors.primaire,
                      onTap: () => setState(() {
                            _filtreType = code;
                            _page = 0;
                          })),
                  const SizedBox(width: 7),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (_erreur != null) ...[
            EncadreVide(texte: _erreur!),
            const SizedBox(height: 10),
          ],
          if (affiches.isEmpty && _erreur == null)
            const EncadreVide(texte: 'Aucune action pour ces filtres.'),
          // Frise chronologique (identique a la maquette)
          ...PaginationSocadel.tranche(affiches, _page)
              .map((a) => IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Column(children: [
                      Container(
                        width: 10,
                        height: 10,
                        margin: const EdgeInsets.only(top: 3),
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
                          child:
                              Container(width: 2, color: const Color(0xFFE1E6EE))),
                    ]),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${a['action']}',
                                style: GoogleFonts.ibmPlexSans(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    height: 1.4,
                                    color: AppColors.texte)),
                            const SizedBox(height: 4),
                            Text('${a['date']} · ${a['utilisateur']}',
                                style: GoogleFonts.ibmPlexMono(
                                    fontSize: 11, color: AppColors.texteLeger)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              )),
          PaginationSocadel(
              total: affiches.length,
              page: _page,
              onChange: (p) => setState(() => _page = p)),
        ],
      ),
    );
  }

  Widget _liste(String label, String valeur, List<String> options,
      ValueChanged<String> onChange) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.ibmPlexSans(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.texteLeger)),
        const SizedBox(height: 5),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AppColors.bordureInput, width: 1.5),
            borderRadius: BorderRadius.circular(10),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: options.contains(valeur) ? valeur : options.first,
              isExpanded: true,
              isDense: true,
              padding: const EdgeInsets.symmetric(vertical: 10),
              style: GoogleFonts.ibmPlexSans(
                  fontSize: 12.5, color: AppColors.texte),
              items: [
                for (final option in options)
                  DropdownMenuItem(
                      value: option,
                      child: Text(option,
                          maxLines: 1, overflow: TextOverflow.ellipsis)),
              ],
              onChanged: (v) => v == null ? null : onChange(v),
            ),
          ),
        ),
      ],
    );
  }
}
