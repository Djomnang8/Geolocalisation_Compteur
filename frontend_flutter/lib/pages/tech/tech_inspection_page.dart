import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../core/app_colors.dart';
import '../../core/session.dart';
import '../../models/compteur.dart';
import '../../services/rapport_service.dart';
import '../../widgets/soc_widgets.dart';
import '../../widgets/statut.dart';

/// Formulaire d'inspection (maquette "TECH INSPECTION FORM") :
/// etat du compteur (grille 2x2), anomalies, observations, pieces jointes,
/// capture automatique de la position GPS et envoi du rapport.
/// Diagrammes de sequence : "Remplir et envoyer un rapport d'inspection",
/// "Enregistrement de la position GPS de visite".
class TechInspectionPage extends StatefulWidget {
  final Compteur compteur;
  const TechInspectionPage({super.key, required this.compteur});

  @override
  State<TechInspectionPage> createState() => _TechInspectionPageState();
}

class _TechInspectionPageState extends State<TechInspectionPage> {
  String? _etat;
  final _etatAutre = TextEditingController();
  final _anomalies = TextEditingController();
  final _observations = TextEditingController();
  XFile? _photo; // photo prise ou choisie (preuve de visite)
  String? _fichierNom; // nom du fichier joint (PDF, DOCX, TXT...)
  Uint8List? _fichierOctets; // octets du fichier, envoyes a l'administrateur
  bool _envoiEnCours = false;

  /// Prise de photo : l'utilisateur choisit Caméra ou Galerie.
  Future<void> _joindrePhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.fond,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (contexteFeuille) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined,
                  color: AppColors.primaire),
              title: Text('Prendre une photo',
                  style: GoogleFonts.ibmPlexSans(
                      fontSize: 14, fontWeight: FontWeight.w600)),
              onTap: () =>
                  Navigator.of(contexteFeuille).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined,
                  color: AppColors.primaire),
              title: Text('Choisir dans la galerie',
                  style: GoogleFonts.ibmPlexSans(
                      fontSize: 14, fontWeight: FontWeight.w600)),
              onTap: () =>
                  Navigator.of(contexteFeuille).pop(ImageSource.gallery),
            ),
            if (_photo != null)
              ListTile(
                leading: const Icon(Icons.delete_outline,
                    color: AppColors.rougeSombre),
                title: Text('Retirer la photo',
                    style: GoogleFonts.ibmPlexSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.rougeSombre)),
                onTap: () {
                  Navigator.of(contexteFeuille).pop();
                  setState(() => _photo = null);
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (source == null) return;
    try {
      final image = await ImagePicker()
          .pickImage(source: source, maxWidth: 1600, imageQuality: 82);
      if (image != null && mounted) {
        setState(() => _photo = image);
        afficherToast(context, 'Photo jointe au rapport');
      }
    } catch (e) {
      if (mounted) {
        afficherErreur(context,
            "Impossible d'accéder à l'appareil photo / la galerie.");
      }
    }
  }

  /// Choix d'un fichier a joindre (PDF, DOCX, TXT, image...). Les octets
  /// sont conserves pour etre envoyes a l'administrateur avec le rapport.
  Future<void> _joindreFichier() async {
    try {
      final resultat = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'jpg', 'jpeg', 'png'],
        withData: true,
      );
      if (resultat != null && resultat.files.isNotEmpty && mounted) {
        final fichier = resultat.files.single;
        if (fichier.bytes == null) {
          afficherErreur(context, 'Impossible de lire le fichier sélectionné.');
          return;
        }
        if (fichier.bytes!.length > 10 * 1024 * 1024) {
          afficherErreur(context, 'Fichier trop volumineux (10 Mo maximum).');
          return;
        }
        setState(() {
          _fichierNom = fichier.name;
          _fichierOctets = fichier.bytes;
        });
        afficherToast(context, 'Fichier joint : $_fichierNom');
      }
    } catch (e) {
      if (mounted) {
        afficherErreur(context, 'Impossible de sélectionner le fichier.');
      }
    }
  }

  late final String _date =
      DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());

  /// Capture de la position GPS precise lors de la visite du compteur.
  /// En cas d'indisponibilite (permission refusee, GPS coupe), la position
  /// du point de livraison du compteur est utilisee.
  Future<(double, double)> _capturerGps() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return (widget.compteur.latitude, widget.compteur.longitude);
      }
      final position = await Geolocator.getCurrentPosition(
          locationSettings:
              const LocationSettings(accuracy: LocationAccuracy.high))
          .timeout(const Duration(seconds: 8));
      return (position.latitude, position.longitude);
    } catch (_) {
      return (widget.compteur.latitude, widget.compteur.longitude);
    }
  }

  Future<void> _envoyer() async {
    // Regles de validation identiques a la maquette
    if (_etat == null) {
      afficherToast(context, "Sélectionnez l'état du compteur");
      return;
    }
    if (_etat == 'AUTRE' && _etatAutre.text.trim().isEmpty) {
      afficherToast(context, "Précisez l'état (champ Autre)");
      return;
    }
    if (_anomalies.text.trim().isEmpty) {
      afficherToast(context, 'Renseignez les anomalies constatées');
      return;
    }
    if (_observations.text.trim().isEmpty) {
      afficherToast(context, 'Renseignez les observations');
      return;
    }
    setState(() => _envoiEnCours = true);
    try {
      final (latitude, longitude) = await _capturerGps();
      final anomalies = _anomalies.text
          .split(RegExp(r'[\n,]'))
          .map((a) => a.trim())
          .where((a) => a.isNotEmpty)
          .join(';');
      // Pieces jointes : octets encodes en Base64, consultables ensuite
      // par l'administrateur depuis la page "Detail du rapport".
      final photoOctets = _photo == null ? null : await _photo!.readAsBytes();
      await RapportService.instance.envoyer({
        'compteurId': widget.compteur.id,
        'matricule': Session.instance.utilisateur!.matricule,
        'etat': _etat,
        'etatAutre': _etat == 'AUTRE' ? _etatAutre.text.trim() : null,
        'anomalies': anomalies,
        'observations': _observations.text.trim(),
        'photo': _photo != null,
        'fichier': _fichierNom,
        'photoBase64': photoOctets == null ? null : base64Encode(photoOctets),
        'fichierBase64':
            _fichierOctets == null ? null : base64Encode(_fichierOctets!),
        'latitude': latitude,
        'longitude': longitude,
      });
      if (!mounted) return;
      afficherToast(context, 'Rapport envoyé · état mis à jour sur la carte');
      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) afficherErreur(context, e);
    } finally {
      if (mounted) setState(() => _envoiEnCours = false);
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
        title: Text("Rapport d'inspection",
            style: GoogleFonts.ibmPlexSans(
                fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
        children: [
          // Rappel du compteur inspecte
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: AppColors.bordure),
            ),
            child: Row(children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.fondBleuClair,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.speed, size: 19, color: AppColors.primaire),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.compteur.reference,
                        style: GoogleFonts.ibmPlexMono(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.texte)),
                    Text('${widget.compteur.zone ?? '—'} · $_date',
                        style: GoogleFonts.ibmPlexSans(
                            fontSize: 11.5, color: AppColors.texteLeger)),
                  ],
                ),
              ),
            ]),
          ),

          // Etat du compteur
          const SizedBox(height: 20),
          _titreSection("État du compteur", obligatoire: true),
          const SizedBox(height: 4),
          Text(
            "C'est ici que l'état du compteur est défini. Il deviendra visible sur la carte après envoi.",
            style: GoogleFonts.ibmPlexSans(
                fontSize: 11.5, color: AppColors.texteLeger, height: 1.5),
          ),
          const SizedBox(height: 11),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 3.4,
            children: [
              for (final code in ['ACTIF', 'MAINTENANCE', 'PANNE', 'AUTRE'])
                _OptionEtat(
                  meta: StatutMeta.de(code),
                  active: _etat == code,
                  onTap: () => setState(() => _etat = code),
                ),
            ],
          ),
          if (_etat == 'AUTRE') ...[
            const SizedBox(height: 11),
            TextField(
              controller: _etatAutre,
              style: GoogleFonts.ibmPlexSans(fontSize: 13.5, color: AppColors.texte),
              decoration: decorationSocadel("Précisez l'état du compteur…"),
            ),
          ],

          // Anomalies
          const SizedBox(height: 22),
          _titreSection('Anomalies constatées', obligatoire: true),
          const SizedBox(height: 11),
          TextField(
            controller: _anomalies,
            maxLines: 3,
            style: GoogleFonts.ibmPlexSans(
                fontSize: 13.5, color: AppColors.texte, height: 1.5),
            decoration: decorationSocadel(
                'Décrivez les anomalies constatées (séparez-les par une virgule ou un retour à la ligne)…'),
          ),

          // Observations
          const SizedBox(height: 22),
          _titreSection('Observations', obligatoire: true),
          const SizedBox(height: 9),
          TextField(
            controller: _observations,
            maxLines: 4,
            style: GoogleFonts.ibmPlexSans(
                fontSize: 13.5, color: AppColors.texte, height: 1.5),
            decoration: decorationSocadel(
                "Décrivez l'intervention, le contexte, les actions menées…"),
          ),

          // Pieces jointes
          const SizedBox(height: 22),
          Row(children: [
            _titreSection('Pièces jointes'),
            const SizedBox(width: 6),
            Text('(optionnel)',
                style: GoogleFonts.ibmPlexSans(
                    fontSize: 12, color: AppColors.texteLeger)),
          ]),
          const SizedBox(height: 11),
          Row(children: [
            Expanded(
              child: _BoutonPieceJointe(
                icone: Icons.attach_file,
                label: _fichierNom == null ? 'Joindre un fichier' : 'Fichier joint',
                detail: _fichierNom,
                actif: _fichierNom != null,
                onTap: _joindreFichier,
                onSupprimer: _fichierNom == null
                    ? null
                    : () => setState(() {
                          _fichierNom = null;
                          _fichierOctets = null;
                        }),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _BoutonPieceJointe(
                icone: Icons.photo_camera_outlined,
                label: _photo == null ? 'Joindre une photo' : 'Photo jointe',
                detail: _photo?.name,
                actif: _photo != null,
                onTap: _joindrePhoto,
                onSupprimer:
                    _photo == null ? null : () => setState(() => _photo = null),
              ),
            ),
          ]),
          const SizedBox(height: 9),
          Row(children: [
            const Icon(Icons.location_on_outlined,
                size: 13, color: AppColors.texteLeger),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                "Position GPS enregistrée automatiquement à l'envoi du rapport.",
                style: GoogleFonts.ibmPlexSans(
                    fontSize: 11, color: AppColors.texteLeger),
              ),
            ),
          ]),

          // Envoi
          const SizedBox(height: 22),
          BoutonPrincipal(
            texte: 'Envoyer le rapport',
            icone: Icons.send,
            couleur: AppColors.vert,
            enCours: _envoiEnCours,
            onPressed: _envoyer,
          ),
        ],
      ),
    );
  }

  Widget _titreSection(String texte, {bool obligatoire = false}) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Text(texte,
          style: GoogleFonts.ibmPlexSans(
              fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.texte)),
      if (obligatoire)
        Text(' *',
            style: GoogleFonts.ibmPlexSans(
                fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.rouge)),
    ]);
  }
}

/// Option d'etat de la grille (bordure coloree + point de couleur).
class _OptionEtat extends StatelessWidget {
  final StatutMeta meta;
  final bool active;
  final VoidCallback onTap;
  const _OptionEtat({required this.meta, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13),
        decoration: BoxDecoration(
          color: active ? meta.fond : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: active ? meta.couleur : const Color(0xFFE1E6EE), width: 2),
        ),
        child: Row(children: [
          Container(
              width: 13,
              height: 13,
              decoration:
                  BoxDecoration(color: meta.couleur, shape: BoxShape.circle)),
          const SizedBox(width: 9),
          Expanded(
            child: Text(meta.libelle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.ibmPlexSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.texte)),
          ),
        ]),
      ),
    );
  }
}

/// Bouton de piece jointe : ouvre le selecteur au tap ; quand une piece est
/// jointe, affiche son nom et un appui long permet de la retirer.
class _BoutonPieceJointe extends StatelessWidget {
  final IconData icone;
  final String label;
  final String? detail;
  final bool actif;
  final VoidCallback onTap;
  final VoidCallback? onSupprimer;

  const _BoutonPieceJointe({
    required this.icone,
    required this.label,
    this.detail,
    required this.actif,
    required this.onTap,
    this.onSupprimer,
  });

  @override
  Widget build(BuildContext context) {
    final couleur = actif ? AppColors.vert : AppColors.primaire;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      onLongPress: onSupprimer,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
        decoration: BoxDecoration(
          color: actif ? AppColors.vertFond : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: actif ? AppColors.vert : AppColors.bordureInput, width: 1.5),
        ),
        child: Column(children: [
          Icon(actif ? Icons.check_circle_outline : icone,
              size: 22, color: couleur),
          const SizedBox(height: 7),
          Text(label,
              textAlign: TextAlign.center,
              style: GoogleFonts.ibmPlexSans(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.texte)),
          if (detail != null) ...[
            const SizedBox(height: 3),
            Text(detail!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: GoogleFonts.ibmPlexMono(
                    fontSize: 9.5, color: AppColors.texteLeger)),
            Text('Appui long pour retirer',
                style: GoogleFonts.ibmPlexSans(
                    fontSize: 9, color: AppColors.texteLeger)),
          ],
        ]),
      ),
    );
  }
}
