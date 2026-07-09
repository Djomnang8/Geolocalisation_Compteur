import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../core/app_colors.dart';
import '../../models/rapport.dart';
import '../../services/rapport_service.dart';
import '../../widgets/soc_widgets.dart';
import '../../widgets/statut.dart';
import 'admin_report_detail_page.dart';

/// Réception des rapports d'inspection (maquette "ADMIN REPORTS") :
/// recherche (technicien, zone), filtres Tous / En attente / Validés /
/// Rejetés, filtre par statut du compteur, sélecteur de plage de dates,
/// puis liste des rapports (référence, statut, technicien, zone, état, date).
/// Diagramme de séquence : "Consultation et validation d'un rapport".
class AdminReportsPage extends StatefulWidget {
  const AdminReportsPage({super.key});

  @override
  State<AdminReportsPage> createState() => _AdminReportsPageState();
}

class _AdminReportsPageState extends State<AdminReportsPage> {
  static final _formatDate = DateFormat('dd/MM/yyyy HH:mm');
  static final _formatJour = DateFormat('dd/MM/yyyy');

  final _recherche = TextEditingController();
  List<Rapport> _tous = const [];
  String _filtre = 'TOUS'; // statut du rapport
  String _filtreEtat = 'TOUS'; // statut du compteur constate
  DateTimeRange? _plage; // plage de dates d'intervention
  int _page = 0; // pagination (10 rapports par page)
  bool _chargement = true;
  String? _erreur;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    try {
      final rapports = await RapportService.instance.lister();
      if (mounted) {
        setState(() { _tous = rapports; _erreur = null; _chargement = false; });
      }
    } catch (e) {
      if (mounted) setState(() { _erreur = e.toString(); _chargement = false; });
    }
  }

  /// Selecteur de plage de dates (calendrier en francais).
  Future<void> _choisirPlage() async {
    final maintenant = DateTime.now();
    final plage = await showDateRangePicker(
      context: context,
      firstDate: DateTime(maintenant.year - 2),
      lastDate: DateTime(maintenant.year + 1),
      initialDateRange: _plage,
      helpText: 'Période des rapports',
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

  /// Filtres combines : statut du rapport, statut du compteur, plage de
  /// dates et recherche par nom de technicien / zone / reference.
  List<Rapport> get _filtres {
    final q = _recherche.text.trim().toLowerCase();
    return _tous.where((r) {
      final okStatut = _filtre == 'TOUS' || r.statut == _filtre;
      final okEtat = _filtreEtat == 'TOUS' || r.etat == _filtreEtat;
      final okRecherche = q.isEmpty ||
          r.technicienNom.toLowerCase().contains(q) ||
          (r.zone ?? '').toLowerCase().contains(q) ||
          r.reference.toLowerCase().contains(q);
      bool okDate = true;
      if (_plage != null) {
        try {
          final date = _formatDate.parse(r.date);
          final debut =
              DateTime(_plage!.start.year, _plage!.start.month, _plage!.start.day);
          final fin = DateTime(
              _plage!.end.year, _plage!.end.month, _plage!.end.day, 23, 59, 59);
          okDate = !date.isBefore(debut) && !date.isAfter(fin);
        } catch (_) {
          okDate = true;
        }
      }
      return okStatut && okEtat && okRecherche && okDate;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final affiches = _filtres;
    return Column(
      children: [
        // Recherche + filtres (technicien, zone, statut, periode)
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
          child: Column(children: [
            TextField(
              controller: _recherche,
              onChanged: (_) => setState(() => _page = 0),
              style: GoogleFonts.ibmPlexSans(fontSize: 13.5, color: AppColors.texte),
              decoration: decorationSocadel(
                      'Rechercher un technicien, une zone…')
                  .copyWith(
                prefixIcon: const Icon(Icons.search,
                    size: 18, color: AppColors.texteLeger),
                fillColor: AppColors.fond,
                suffixIcon: _recherche.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close,
                            size: 16, color: AppColors.texteLeger),
                        onPressed: () {
                          _recherche.clear();
                          setState(() => _page = 0);
                        },
                      ),
              ),
            ),
            const SizedBox(height: 10),
            // Statut du rapport + selecteur de periode
            SizedBox(
              height: 34,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  BoutonPlageDates(
                    libelle: _plage == null
                        ? 'Période'
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
                  const SizedBox(width: 7),
                  for (final (code, libelle) in [
                    ('TOUS', 'Tous'),
                    ('EN_ATTENTE', 'En attente'),
                    ('VALIDE', 'Validés'),
                    ('REJETE', 'Rejetés'),
                  ]) ...[
                    PuceFiltre(
                        label: libelle,
                        active: _filtre == code,
                        couleur: _filtre == code
                            ? AppColors.primaire
                            : const Color(0xFF5A6577),
                        onTap: () => setState(() {
                              _filtre = code;
                              _page = 0;
                            })),
                    const SizedBox(width: 7),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Statut du compteur constate lors de l'inspection
            SizedBox(
              height: 34,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  PuceFiltre(
                      label: 'Tous états',
                      active: _filtreEtat == 'TOUS',
                      couleur: AppColors.primaire,
                      onTap: () => setState(() {
                            _filtreEtat = 'TOUS';
                            _page = 0;
                          })),
                  for (final meta in [
                    StatutMeta.de('ACTIF'),
                    StatutMeta.de('MAINTENANCE'),
                    StatutMeta.de('PANNE'),
                    StatutMeta.de('AUTRE'),
                  ]) ...[
                    const SizedBox(width: 7),
                    PuceFiltre(
                        label: meta.libelle,
                        nombre: _tous.where((r) => r.etat == meta.code).length,
                        active: _filtreEtat == meta.code,
                        couleur: meta.couleur,
                        onTap: () => setState(() {
                              _filtreEtat = meta.code;
                              _page = 0;
                            })),
                  ],
                ],
              ),
            ),
          ]),
        ),
        Expanded(
          child: _chargement
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _charger,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 26),
                    children: [
                      Text('${affiches.length} rapport(s) affiché(s)',
                          style: GoogleFonts.ibmPlexSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.texteLeger)),
                      const SizedBox(height: 10),
                      if (_erreur != null) ...[
                        EncadreVide(texte: _erreur!),
                        const SizedBox(height: 10),
                      ],
                      if (affiches.isEmpty && _erreur == null)
                        const EncadreVide(
                            texte: 'Aucun rapport pour ces filtres.'),
                      ...PaginationSocadel.tranche(affiches, _page)
                          .map((r) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _CarteRapport(
                                  rapport: r,
                                  onTap: () => Navigator.of(context)
                                      .push(MaterialPageRoute(
                                          builder: (_) =>
                                              AdminReportDetailPage(rapport: r)))
                                      .then((_) => _charger()),
                                ),
                              )),
                      PaginationSocadel(
                          total: affiches.length,
                          page: _page,
                          onChange: (p) => setState(() => _page = p)),
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}


class _CarteRapport extends StatelessWidget {
  final Rapport rapport;
  final VoidCallback onTap;
  const _CarteRapport({required this.rapport, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final metaEtat = StatutMeta.de(rapport.etat);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        borderRadius: BorderRadius.circular(13),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.bordure),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(rapport.reference,
                      style: GoogleFonts.ibmPlexMono(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.texte)),
                  BadgeStatut(
                      texte: StatutRapport.libelle(rapport.statut),
                      couleur: StatutRapport.couleur(rapport.statut),
                      fond: StatutRapport.fond(rapport.statut)),
                ],
              ),
              const SizedBox(height: 7),
              Text('${rapport.technicienNom} · ${rapport.zone ?? '—'}',
                  style: GoogleFonts.ibmPlexSans(
                      fontSize: 11.5, color: AppColors.texteLeger)),
              const SizedBox(height: 9),
              Row(children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: metaEtat.fond,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                      StatutMeta.libelleComplet(rapport.etat, rapport.etatAutre),
                      style: GoogleFonts.ibmPlexSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: metaEtat.couleur)),
                ),
                const SizedBox(width: 8),
                Text(rapport.date,
                    style: GoogleFonts.ibmPlexMono(
                        fontSize: 11, color: AppColors.texteLeger)),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}
