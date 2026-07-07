import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/app_colors.dart';
import '../../core/session.dart';
import '../../models/rapport.dart';
import '../../services/rapport_service.dart';
import '../../widgets/soc_widgets.dart';
import '../../widgets/statut.dart';

/// Détail d'un rapport d'inspection (maquette "ADMIN REPORT DETAIL") :
/// état, technicien, zone, date/heure, position GPS, anomalies signalées,
/// observations, photo, puis avis de l'administrateur (Valider / Rejeter
/// + commentaire transmis au technicien).
/// Diagramme de séquence : "Consultation et validation d'un rapport".
class AdminReportDetailPage extends StatefulWidget {
  final Rapport rapport;
  const AdminReportDetailPage({super.key, required this.rapport});

  @override
  State<AdminReportDetailPage> createState() => _AdminReportDetailPageState();
}

class _AdminReportDetailPageState extends State<AdminReportDetailPage> {
  late Rapport _rapport = widget.rapport;
  late final _commentaire =
      TextEditingController(text: widget.rapport.commentaireAdmin);
  bool _traitement = false;
  bool _ouvertureFichier = false;
  late final Future<Uint8List?> _photoFuture = _chargerPhoto();

  /// Telecharge la photo d'inspection envoyee par le technicien.
  Future<Uint8List?> _chargerPhoto() async {
    if (!_rapport.photoDisponible) return null;
    try {
      return Uint8List.fromList(await RapportService.instance.photo(_rapport.id));
    } catch (_) {
      return null;
    }
  }

  /// Telecharge le fichier joint puis l'ouvre avec l'application associee
  /// (PDF -> lecteur PDF, DOCX -> Word...).
  Future<void> _ouvrirFichier() async {
    setState(() => _ouvertureFichier = true);
    try {
      final octets = await RapportService.instance.fichier(_rapport.id);
      final dossier = await getTemporaryDirectory();
      final nom = _rapport.fichier ?? 'piece_jointe_r${_rapport.id}';
      final fichier = File('${dossier.path}${Platform.pathSeparator}$nom');
      await fichier.writeAsBytes(octets, flush: true);
      final resultat = await OpenFilex.open(fichier.path);
      if (resultat.type != ResultType.done && mounted) {
        afficherErreur(context,
            "Aucune application ne peut ouvrir « $nom » sur ce téléphone.");
      }
    } catch (e) {
      if (mounted) afficherErreur(context, e);
    } finally {
      if (mounted) setState(() => _ouvertureFichier = false);
    }
  }

  Future<void> _donnerAvis(String statut) async {
    setState(() => _traitement = true);
    try {
      final rapport = await RapportService.instance.donnerAvis(
        _rapport.id,
        statut: statut,
        commentaire: _commentaire.text.trim(),
        matriculeAdmin: Session.instance.utilisateur?.matricule,
      );
      if (!mounted) return;
      setState(() => _rapport = rapport);
      afficherToast(context, 'Avis enregistré');
    } catch (e) {
      if (mounted) afficherErreur(context, e);
    } finally {
      if (mounted) setState(() => _traitement = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final metaEtat = StatutMeta.de(_rapport.etat);
    final enAttente = _rapport.statut == 'EN_ATTENTE';
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primaire,
        elevation: 2,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: Colors.white),
        ),
        title: Text('Détail du rapport',
            style: GoogleFonts.ibmPlexSans(
                fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 30),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('R${_rapport.id.toString().padLeft(2, '0')}',
                        style: GoogleFonts.ibmPlexMono(
                            fontSize: 11, color: AppColors.texteLeger)),
                    const SizedBox(height: 2),
                    Text(_rapport.reference,
                        style: GoogleFonts.ibmPlexMono(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.texte)),
                  ],
                ),
              ),
              BadgeStatut(
                  texte: StatutRapport.libelle(_rapport.statut),
                  couleur: StatutRapport.couleur(_rapport.statut),
                  fond: StatutRapport.fond(_rapport.statut)),
            ],
          ),
          const SizedBox(height: 14),
          // Etat du compteur constate (fond plein colore, comme la maquette)
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: metaEtat.couleur,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                  'État : ${StatutMeta.libelleComplet(_rapport.etat, _rapport.etatAutre)}',
                  style: GoogleFonts.ibmPlexSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white)),
            ),
          ]),
          const SizedBox(height: 16),
          // Informations
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.bordure),
            ),
            child: Column(children: [
              _ligne('Technicien', _rapport.technicienNom),
              _ligne('Zone', _rapport.zone ?? '—'),
              _ligne('Date / heure', _rapport.date, mono: true),
              _ligne('Position GPS', _rapport.gps, mono: true, derniere: true),
            ]),
          ),
          // Anomalies signalees
          if (_rapport.anomalies.isNotEmpty) ...[
            const SizedBox(height: 18),
            _titre('Anomalies signalées'),
            const SizedBox(height: 9),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              decoration: BoxDecoration(
                color: AppColors.rougeFond,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFF3C2C2)),
              ),
              child: Text(_rapport.anomalies.join(' · '),
                  style: GoogleFonts.ibmPlexSans(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      height: 1.6,
                      color: AppColors.rougeSombre)),
            ),
          ],
          // Observations
          const SizedBox(height: 18),
          _titre('Observations'),
          const SizedBox(height: 9),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.bordure),
            ),
            child: Text(_rapport.observations ?? '—',
                style: GoogleFonts.ibmPlexSans(
                    fontSize: 12.5, height: 1.6, color: AppColors.texteLabel)),
          ),
          // Fichier joint : l'administrateur peut l'ouvrir et le consulter
          if (_rapport.fichier != null && _rapport.fichier!.isNotEmpty) ...[
            const SizedBox(height: 18),
            _titre('Fichier joint'),
            const SizedBox(height: 9),
            Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: _rapport.fichierDisponible && !_ouvertureFichier
                    ? _ouvrirFichier
                    : null,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.bordure),
                  ),
                  child: Row(children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.fondBleuClair,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: const Icon(Icons.description_outlined,
                          size: 18, color: AppColors.primaire),
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_rapport.fichier!,
                              style: GoogleFonts.ibmPlexSans(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.texte)),
                          const SizedBox(height: 2),
                          Text(
                              _rapport.fichierDisponible
                                  ? 'Toucher pour ouvrir'
                                  : 'Contenu non disponible (rapport de démonstration)',
                              style: GoogleFonts.ibmPlexSans(
                                  fontSize: 10.5, color: AppColors.texteLeger)),
                        ],
                      ),
                    ),
                    if (_ouvertureFichier)
                      const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2.2))
                    else if (_rapport.fichierDisponible)
                      const Icon(Icons.open_in_new,
                          size: 18, color: AppColors.primaire),
                  ]),
                ),
              ),
            ),
          ],
          // Photo de l'inspection : chargee depuis le serveur et affichee
          const SizedBox(height: 18),
          _titre("Photo de l'inspection"),
          const SizedBox(height: 9),
          if (_rapport.photo)
            FutureBuilder<Uint8List?>(
              future: _photoFuture,
              builder: (context, instantane) {
                if (instantane.connectionState != ConnectionState.done) {
                  return Container(
                    height: 150,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE9EDF2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.bordure),
                    ),
                    child: const Center(
                        child: SizedBox(
                            width: 22,
                            height: 22,
                            child:
                                CircularProgressIndicator(strokeWidth: 2.4))),
                  );
                }
                final octets = instantane.data;
                if (octets == null) {
                  return Container(
                    height: 150,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE9EDF2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.bordure),
                    ),
                    child: Center(
                      child: Text(
                          '[ photo terrain non disponible ]',
                          style: GoogleFonts.ibmPlexMono(
                              fontSize: 11.5, color: const Color(0xFF9AA3B2))),
                    ),
                  );
                }
                // Photo reelle : toucher pour l'agrandir en plein ecran
                return GestureDetector(
                  onTap: () => showDialog(
                    context: context,
                    builder: (_) => Dialog(
                      backgroundColor: Colors.black,
                      insetPadding: const EdgeInsets.all(10),
                      child: InteractiveViewer(
                          child: Image.memory(octets, fit: BoxFit.contain)),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(octets,
                        height: 210, width: double.infinity, fit: BoxFit.cover),
                  ),
                );
              },
            )
          else
            const EncadreVide(texte: 'Aucune photo jointe à ce rapport.'),
          // Avis de l'administrateur
          if (enAttente) ...[
            const SizedBox(height: 20),
            _titre("Avis de l'administrateur"),
            const SizedBox(height: 9),
            TextField(
              controller: _commentaire,
              maxLines: 3,
              style: GoogleFonts.ibmPlexSans(
                  fontSize: 13, color: AppColors.texte, height: 1.5),
              decoration:
                  decorationSocadel('Commentaire à transmettre au technicien…'),
            ),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: BoutonPrincipal(
                  texte: 'Valider',
                  icone: Icons.check,
                  couleur: AppColors.vert,
                  enCours: _traitement,
                  onPressed: () => _donnerAvis('VALIDE'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: _traitement ? null : () => _donnerAvis('REJETE'),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: Color(0xFFF3C2C2), width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('Rejeter',
                      style: GoogleFonts.ibmPlexSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.rougeSombre)),
                ),
              ),
            ]),
          ],
          // Avis deja donne
          if (!enAttente &&
              (_rapport.commentaireAdmin ?? '').isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              decoration: BoxDecoration(
                color: AppColors.fondBleuClair,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Avis administrateur',
                      style: GoogleFonts.ibmPlexSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaire)),
                  const SizedBox(height: 5),
                  Text(_rapport.commentaireAdmin!,
                      style: GoogleFonts.ibmPlexSans(
                          fontSize: 12.5,
                          height: 1.5,
                          color: AppColors.texteLabel)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _titre(String texte) => Text(texte,
      style: GoogleFonts.ibmPlexSans(
          fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.texte));

  Widget _ligne(String label, String valeur,
      {bool mono = false, bool derniere = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 11),
      decoration: BoxDecoration(
        border: derniere
            ? null
            : const Border(bottom: BorderSide(color: AppColors.separateur)),
      ),
      child: Row(children: [
        Text(label,
            style:
                GoogleFonts.ibmPlexSans(fontSize: 12.5, color: AppColors.texteLeger)),
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
      ]),
    );
  }
}
